extends CasoTeste
## Todas as salas são válidas, montam sem erro, têm colisão nas paredes e caminho da
## chegada até a saída (ou até a escada).

const PASTA := "res://dados/salas/catacumbas/"


func _salas() -> Array[String]:
	var lista: Array[String] = []
	for arquivo in DirAccess.get_files_at(PASTA):
		if arquivo.ends_with(".txt"):
			lista.append(arquivo)
	lista.sort()
	return lista


func teste_todas_as_definicoes_sao_validas() -> void:
	var arquivos := _salas()
	afirmar(arquivos.size() >= 8, "pelo menos oito salas")
	for arquivo in arquivos:
		var def := DefinicaoSala.de_arquivo(PASTA + arquivo)
		afirmar(def.valida(), "%s válida: %s" % [arquivo, "; ".join(def.erros)])


func teste_validador_rejeita_salas_quebradas() -> void:
	var aberta := DefinicaoSala.de_texto("tipo: inicio\n---\n#####\n#.@..\n#...#\n#####\n#####\n")
	afirmar(not aberta.valida(), "borda aberta é rejeitada")
	var torta := DefinicaoSala.de_texto("tipo: inicio\n---\n#####\n#.@.#\n#..#\n#####\n#####\n")
	afirmar(not torta.valida(), "linhas de larguras diferentes são rejeitadas")
	var presa := DefinicaoSala.de_texto("tipo: combate\nentrada: v\n---\n#######\n#..#r.#\n#..####\n#.....#\n#.....#\n###vv##\n")
	afirmar(not presa.valida(), "inimigo inalcançável é rejeitado")
	var sem_saida := DefinicaoSala.de_texto("tipo: combate\nentrada: v\nsaida: ^\n---\n#######\n#.....#\n#.....#\n###vv##\n")
	afirmar(not sem_saida.valida(), "saída declarada mas ausente é rejeitada")


func teste_montagem_de_cada_sala() -> void:
	for arquivo in _salas():
		var sala := ConstrutorSala.carregar(PASTA + arquivo, 99)
		afirmar(sala != null, "%s monta" % arquivo)
		if sala == null:
			continue
		add_child(sala)
		var def := sala.definicao
		# Toda célula de parede tem tile com colisão; todo chão tem tile de chão.
		var paredes_sem_colisao := 0
		var chao_faltando := 0
		for y in def.altura:
			for x in def.largura:
				var c := Vector2i(x, y)
				if def.eh_parede(c):
					var dados := sala.paredes.get_cell_tile_data(c)
					if dados == null or dados.get_collision_polygons_count(0) == 0:
						paredes_sem_colisao += 1
				elif sala.chao.get_cell_source_id(c) < 0:
					chao_faltando += 1
		afirmar_igual(paredes_sem_colisao, 0, "%s: paredes com colisão" % arquivo)
		afirmar_igual(chao_faltando, 0, "%s: chão completo" % arquivo)
		# Passagens declaradas viram portas
		for simbolo in [def.entrada, def.saida]:
			if simbolo != "":
				afirmar(sala.portas.has(simbolo), "%s: porta '%s' criada" % [arquivo, simbolo])
		# A chegada é andável e existe caminho até a saída / escada
		var chegada := sala.posicao_chegada()
		afirmar(sala.andavel(sala.celula_de(chegada)), "%s: chegada em chão andável" % arquivo)
		if def.saida != "":
			var destino := sala.centro_celula(def.celula_dentro_da_porta(def.saida))
			afirmar(sala.caminho(chegada, destino).size() > 1, "%s: caminho até a saída" % arquivo)
		if def.tipo == "descida":
			afirmar(sala.escada != null, "%s: escada criada" % arquivo)
		if def.tipo == "reliquia":
			afirmar(sala.altares.size() == def.celulas_com("A").size(), "%s: altares criados" % arquivo)
		sala.queue_free()
		await quadros(1)


func teste_faces_de_parede_em_vista_tres_quartos() -> void:
	var def := DefinicaoSala.de_texto("tipo: inicio\n---\n######\n######\n######\n#.@..#\n#.##.#\n#....#\n######\n")
	afirmar(def.valida(), "sala de teste válida: %s" % "; ".join(def.erros))
	afirmar_igual(ConstrutorSala.tipo_face(def, Vector2i(1, 2)), ConstrutorSala.FACE_BAIXO, "parede com chão abaixo e parede acima é face de baixo")
	afirmar_igual(ConstrutorSala.tipo_face(def, Vector2i(1, 1)), ConstrutorSala.FACE_CIMA, "acima da face de baixo vem a face de cima")
	afirmar_igual(ConstrutorSala.tipo_face(def, Vector2i(1, 0)), ConstrutorSala.SEM_FACE, "o resto é topo")
	afirmar_igual(ConstrutorSala.tipo_face(def, Vector2i(2, 4)), ConstrutorSala.FACE_UNICA, "parede de um tile com chão acima e abaixo é face única")
	afirmar_igual(ConstrutorSala.tipo_face(def, Vector2i(0, 6)), ConstrutorSala.SEM_FACE, "parede sul é topo")


func teste_quem_encosta_em_objeto_baixo_continua_visivel_e_alcancavel() -> void:
	# Caixão 't' em (6,5): a colisão física ocupa só parte da célula, então quem encosta
	# nele por cima fica com os pés numa célula sólida da grade.
	var def := DefinicaoSala.de_texto("tipo: inicio\n---\n############\n############\n############\n#..........#\n#..........#\n#.....t....#\n#.@........#\n#..........#\n############\n")
	afirmar(def.valida(), "sala de teste válida: %s" % "; ".join(def.erros))
	var sala := ConstrutorSala.construir(def, 3)
	add_child(sala)
	var no_caixao := sala.centro_celula(Vector2i(6, 5)) + Vector2(0, -5)
	afirmar(not sala.andavel(sala.celula_de(no_caixao)), "os pés estão numa célula sólida")
	var longe := sala.centro_celula(Vector2i(9, 7))
	afirmar(sala.visao_livre(longe, no_caixao), "quem encosta no caixão continua visível")
	afirmar(sala.visao_livre(no_caixao + Vector2(0, -3), longe + Vector2(0, -3)), "e enxerga a sala")
	afirmar(sala.caminho(longe, no_caixao).size() > 1, "existe caminho até quem encosta no caixão")
	afirmar(sala.caminho(no_caixao, longe).size() > 1, "e de quem encosta no caixão até o resto da sala")
	var atras := sala.centro_celula(Vector2i(6, 3))
	var frente := sala.centro_celula(Vector2i(6, 7))
	afirmar(not sala.visao_livre(atras, frente), "o caixão continua bloqueando a visão de quem passa por ele")
	sala.queue_free()
