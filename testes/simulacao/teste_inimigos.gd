extends CasoTeste
## Simulação: comportamento dos inimigos e interrupção por postura.

var m: MundoTeste


func antes_de_cada() -> void:
	m = MundoTeste.criar(self)


func depois_de_cada() -> void:
	m.queue_free()


func teste_ressequido_prepara_investe_e_acerta_jogador_parado() -> void:
	await quadros(2)
	var r := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(36, 0)) as Ressequido
	var viu_preparo := false
	var viu_investida := false
	var velas := Jogo.velas
	for i in 240:
		await quadros(1)
		viu_preparo = viu_preparo or r.acao == Ressequido.Acao.PREPARAR
		viu_investida = viu_investida or r.acao == Ressequido.Acao.INVESTIR
		if Jogo.velas < velas:
			break
	afirmar(viu_preparo, "telegrafou a investida (preparo)")
	afirmar(viu_investida, "investiu")
	afirmar_igual(Jogo.velas, velas - 1, "a investida tirou uma vela da Coveira parada")


func teste_preparo_dura_o_suficiente_para_reagir() -> void:
	await quadros(2)
	var r := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(36, 0)) as Ressequido
	var quadros_preparo := 0
	for i in 200:
		await quadros(1)
		if r.acao == Ressequido.Acao.PREPARAR:
			quadros_preparo += 1
		elif quadros_preparo > 0:
			break
	afirmar(quadros_preparo >= 30, "preparo visível por pelo menos 0,5 s (%d quadros)" % quadros_preparo)


func teste_preparo_fortalecido_tambem_dura_o_suficiente() -> void:
	await quadros(2)
	var r := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(36, 0)) as Ressequido
	var quadros_preparo := 0
	for i in 200:
		r.fortalecer(1.0)
		await quadros(1)
		if r.acao == Ressequido.Acao.PREPARAR:
			quadros_preparo += 1
		elif quadros_preparo > 0:
			break
	afirmar(r.esta_fortalecido(), "Ressequido fortalecido durante o teste")
	afirmar(quadros_preparo >= 30, "fortalecido, o aviso continua com 0,5 s ou mais (%d quadros)" % quadros_preparo)


func teste_golpe_leve_nao_interrompe_preparo_mas_pancada_sim() -> void:
	await quadros(2)
	var r := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(36, 0)) as Ressequido
	for i in 200:
		await quadros(1)
		if r.acao == Ressequido.Acao.PREPARAR:
			break
	afirmar_igual(r.acao, Ressequido.Acao.PREPARAR, "entrou em preparo")
	var leve := DanoInfo.new()
	leve.valor = 1.0
	leve.interrupcao = DanoInfo.Interrupcao.LEVE
	leve.direcao = Vector2.RIGHT
	r.receber_dano(leve)
	afirmar_igual(r.acao, Ressequido.Acao.PREPARAR, "golpe leve não quebra a postura")
	var forte := DanoInfo.new()
	forte.valor = 1.0
	forte.interrupcao = DanoInfo.Interrupcao.FORTE
	forte.direcao = Vector2.RIGHT
	r.receber_dano(forte)
	afirmar_igual(r.acao, Ressequido.Acao.PERSEGUIR, "golpe forte interrompe o preparo")
	afirmar_igual(r.fase, Inimigo.Fase.ATINGIDO, "e o deixa atordoado por um instante")


func teste_lamuriante_fortalece_ressequido_proximo() -> void:
	await quadros(2)
	var base := m.jogador.global_position + Vector2(-60, -10)
	var r := m.inimigo(&"ressequido", base) as Ressequido
	var l := m.inimigo(&"lamuriante", base + Vector2(-30, 0)) as Lamuriante
	await quadros(4)
	afirmar(r.esta_fortalecido(), "Ressequido ao alcance fica fortalecido")
	l.receber_dano(_dano_letal())
	await quadros(30)
	afirmar(not r.esta_fortalecido(), "sem a Lamuriante, o fortalecimento passa")


func teste_lamuriante_lanca_lamuria() -> void:
	await quadros(2)
	m.inimigo(&"lamuriante", m.jogador.global_position + Vector2(-110, 0))
	var viu_projetil := false
	for i in 300:
		await quadros(1)
		if not get_tree().get_nodes_in_group(&"inimigos").filter(func(n: Node) -> bool: return n is ProjetilLamuria).is_empty():
			viu_projetil = true
		for filho in m.sala.mundo.get_children():
			if filho is ProjetilLamuria:
				viu_projetil = true
		if viu_projetil:
			break
	afirmar(viu_projetil, "a Lamuriante lançou uma Lamúria")


const SALA_BLOCO := "nome: Teste\ntipo: inicio\n---\n##############\n##############\n##############\n#............#\n#............#\n#...######...#\n#...######...#\n#...######...#\n#............#\n#.....@......#\n#............#\n##############\n"


func teste_lamuriante_sem_linha_de_tiro_procura_uma() -> void:
	# A Coveira parada atrás de um bloco de parede, a ~96 px: a Lamuriante não pode ficar
	# indecisa entre fugir e se aproximar; ela contorna o bloco até ter linha de tiro.
	m.queue_free()
	m = MundoTeste.criar(self, SALA_BLOCO)
	await quadros(2)
	var l := m.inimigo(&"lamuriante", m.sala.centro_celula(Vector2i(6, 3)) + Vector2(0, 4)) as Lamuriante
	afirmar(not m.sala.visao_livre(l.global_position + Vector2(0, -12), m.jogador.global_position + Vector2(0, -8)), "começa sem linha de tiro")
	var lancou := false
	for i in 480:
		await quadros(1)
		for filho in m.sala.mundo.get_children():
			if filho is ProjetilLamuria:
				lancou = true
		if lancou:
			break
	afirmar(lancou, "em até 8 s ela encontra uma linha de tiro e lança a Lamúria")


func teste_morte_solta_ossos_e_deixa_restos() -> void:
	await quadros(2)
	var r := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(50, 0))
	r.receber_dano(_dano_letal())
	afirmar(not r.esta_vivo(), "morreu")
	await quadros(60)
	var ossos := get_tree().get_nodes_in_group(&"coletaveis").size()
	afirmar(ossos >= r.dados.ossos_min, "soltou ossos (%d)" % ossos)
	afirmar(is_instance_valid(r) and r.fase == Inimigo.Fase.MORTO, "os restos ficam na sala")
	afirmar(r.z_index < 0, "restos desenhados abaixo dos vivos")


func teste_lamuria_se_desfaz_quando_a_sala_e_purificada() -> void:
	await quadros(2)
	var p := ProjetilLamuria.new()
	p.direcao = Vector2.LEFT
	p.position = m.jogador.global_position + Vector2(120, 0)
	m.sala.mundo.add_child(p)
	await quadros(2)
	afirmar(p.esta_vivo(), "a Lamúria voa")
	Eventos.sala_limpa.emit(m.sala)
	await quadros(2)
	afirmar(not is_instance_valid(p) or not p.esta_vivo(), "sala purificada desfaz a Lamúria")


func teste_restos_apagam_as_luzes_e_nao_atravessam_paredes() -> void:
	await quadros(2)
	var direita := m.sala.centro_celula(Vector2i(m.sala.definicao.largura - 2, 6))
	var r := m.inimigo(&"ressequido", direita + Vector2(-6, 0))
	var l := m.inimigo(&"lamuriante", m.jogador.global_position + Vector2(-60, 0))
	await quadros(2)
	var golpe := _dano_letal()
	golpe.direcao = Vector2.RIGHT
	golpe.empurrao = 300.0
	r.receber_dano(golpe)
	l.receber_dano(_dano_letal())
	await quadros(90)
	var limite := float((m.sala.definicao.largura - 1) * 16)
	afirmar(r.global_position.x < limite, "o cadáver para na parede (x = %.1f, parede em %.1f)" % [r.global_position.x, limite])
	for inimigo: Node in [r, l]:
		var acesas := 0
		for luz: PointLight2D in inimigo.find_children("*", "PointLight2D", true, false):
			if luz.visible and luz.energy > 0.01:
				acesas += 1
		afirmar_igual(acesas, 0, "%s: luzes apagadas nos restos" % inimigo.name)


func _dano_letal() -> DanoInfo:
	var d := DanoInfo.new()
	d.valor = 999.0
	d.interrupcao = DanoInfo.Interrupcao.FORTE
	d.direcao = Vector2.RIGHT
	return d
