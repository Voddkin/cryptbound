extends CasoTeste
## Simulação: a sala tranca, ergue as ondas, libera ao fim; a morte encerra a descida.

const SALA_COMBATE := "nome: Teste
tipo: combate
entrada: v
saida: ^
---
#########^^#########
#########^^#########
#########^^#########
#..................#
#....r......r......#
#..................#
#.........R........#
#..................#
#..................#
#########vv#########
"

var m: MundoTeste


func depois_de_cada() -> void:
	if m:
		m.queue_free()


func teste_sala_tranca_ergue_ondas_e_libera() -> void:
	m = MundoTeste.criar(self, SALA_COMBATE)
	var limpa := [false]
	m.sala.limpa.connect(func() -> void: limpa[0] = true)
	m.sala.iniciar(m.jogador)
	await quadros(2)
	afirmar_igual(m.sala.estado, Sala.Situacao.AGUARDANDO_ENTRADA, "espera a Coveira entrar")
	afirmar(not m.sala.portas["v"].trancada, "a passagem de entrada ainda está aberta")
	m.entrada.mover = Vector2.UP
	for i in 60:
		await quadros(1)
		if m.sala.estado == Sala.Situacao.COMBATE:
			break
	m.entrada.mover = Vector2.ZERO
	afirmar_igual(m.sala.estado, Sala.Situacao.COMBATE, "combate começou ao entrar")
	afirmar(m.sala.portas["v"].trancada and m.sala.portas["^"].trancada, "as passagens foram trancadas pelas raízes")
	afirmar_igual(m.sala.onda_atual, 1, "primeira onda")
	await quadros(50)  # deixa os inimigos surgirem
	var mortos := 0
	for onda in 2:
		for inimigo in m.sala.vivos.duplicate():
			inimigo.pular_surgimento()
			inimigo.receber_dano(_letal())
			mortos += 1
		await quadros(80)
	afirmar(mortos >= 3, "derrubou as duas ondas (%d inimigos)" % mortos)
	afirmar(limpa[0], "sala purificada")
	afirmar(not m.sala.portas["^"].trancada, "a saída abriu")
	afirmar_igual(Jogo.salas_limpas, 1, "estatística de salas")


func teste_ninguem_sai_do_mapa_pela_passagem_de_entrada() -> void:
	m = MundoTeste.criar(self, SALA_COMBATE)
	m.sala.iniciar(m.jogador)
	await quadros(2)
	var fundo := m.sala.altura_px()
	# Anda para trás pela passagem de entrada e ainda esquiva na mesma direção.
	m.entrada.mover = Vector2.DOWN
	await quadros(30)
	m.entrada.esquivar = true
	await quadros(2)
	m.entrada.esquivar = false
	await quadros(40)
	afirmar(m.jogador.global_position.y < fundo, "a Coveira continua dentro do mapa (y = %.1f, borda em %.1f)" % [m.jogador.global_position.y, fundo])
	afirmar_igual(m.sala.estado, Sala.Situacao.AGUARDANDO_ENTRADA, "o combate não começa com a Coveira na passagem")
	# Voltando para dentro, a sala tranca normalmente com ela do lado certo.
	m.entrada.mover = Vector2.UP
	for i in 90:
		await quadros(1)
		if m.sala.estado == Sala.Situacao.COMBATE:
			break
	m.entrada.mover = Vector2.ZERO
	afirmar_igual(m.sala.estado, Sala.Situacao.COMBATE, "o combate começa quando ela entra")
	afirmar(m.sala.andavel(m.sala.celula_de(m.jogador.global_position)), "e ela está numa célula andável da sala")


func teste_relicario_sem_reliquias_novas_oferece_oferendas() -> void:
	var texto := FileAccess.get_file_as_string("res://dados/salas/catacumbas/relicario.txt")
	m = MundoTeste.criar(self, texto)
	var mensagens: Array[String] = []
	var ouvir := func(t: String, _d: float = 0.0) -> void: mensagens.append(t)
	Eventos.mensagem.connect(ouvir)
	m.sala.iniciar(m.jogador)
	Eventos.mensagem.disconnect(ouvir)
	await quadros(2)
	afirmar(m.sala.altares.size() >= 2, "o relicário tem altares (%d)" % m.sala.altares.size())
	var ossos := 0
	var velas := 0
	for c in get_tree().get_nodes_in_group(&"coletaveis"):
		if c.tipo == Coletavel.Tipo.OSSO:
			ossos += 1
		else:
			velas += 1
	afirmar_igual(ossos, 3 * m.sala.altares.size(), "três ossos de oferenda por altar vazio")
	afirmar_igual(velas, 1, "e um toco de vela")
	afirmar(mensagens.has(Textos.t("hud.altares_vazios")), "o jogador sabe por que os altares estão vazios")


func teste_relicario_com_reliquias_avisa_que_so_uma_pode_ser_levada() -> void:
	var texto := FileAccess.get_file_as_string("res://dados/salas/catacumbas/relicario.txt")
	var def := DefinicaoSala.de_texto(texto)
	var itens: Array[ItemDados] = []
	for id in ["presa_cao_de_cova", "sino_rachado", "vela_perene"]:
		itens.append(load("res://dados/itens/%s.tres" % id) as ItemDados)
	Jogo.nova_descida(9)
	var sala := ConstrutorSala.construir(def, 9, itens)
	add_child(sala)
	var mensagens: Array[String] = []
	var ouvir := func(t: String, _d: float = 0.0) -> void: mensagens.append(t)
	Eventos.mensagem.connect(ouvir)
	sala.iniciar(Node2D.new())
	Eventos.mensagem.disconnect(ouvir)
	await quadros(2)
	afirmar(mensagens.has(Textos.t("hud.escolha_reliquia")), "aviso de que só uma relíquia pode ser levada")
	afirmar_igual(get_tree().get_nodes_in_group(&"coletaveis").size(), 0, "sem oferendas quando há relíquias")
	sala.queue_free()


func teste_saida_aberta_leva_adiante() -> void:
	m = MundoTeste.criar(self, SALA_COMBATE)
	var atravessou := [false]
	m.sala.saida_atravessada.connect(func() -> void: atravessou[0] = true)
	m.sala.iniciar(m.jogador)
	m.sala._marcar_limpa(false)
	await quadros(2)
	m.jogador.global_position = m.sala.centro_celula(Vector2i(9, 3))
	m.jogador.reset_physics_interpolation()
	m.entrada.mover = Vector2.UP
	for i in 90:
		await quadros(1)
		if atravessou[0]:
			break
	afirmar(atravessou[0], "andar pela passagem de saída aberta leva à próxima sala")


func teste_morte_mostra_causa_e_registra() -> void:
	m = MundoTeste.criar(self)
	var mortes_antes := int(Salvamento.dados.get("mortes", 0))
	var recebido: Array[DanoInfo] = []
	var conexao := func(info: DanoInfo) -> void: recebido.append(info)
	Eventos.jogador_morreu.connect(conexao)
	Jogo.perder_velas(Jogo.velas - 1)
	await quadros(2)
	var golpe := DanoInfo.new()
	golpe.valor = 1.0
	golpe.velas = 1
	golpe.fonte_nome = "Ressequido"
	golpe.ataque_nome = "Investida"
	golpe.dica = "Esquive para o lado."
	golpe.direcao = Vector2.RIGHT
	afirmar(m.jogador.receber_dano(golpe), "golpe final acertou")
	afirmar_igual(m.jogador.estado, Jogador.Situacao.MORTO, "a Coveira tombou")
	afirmar(not Jogo.em_descida, "a descida terminou")
	for i in 200:
		await quadros(1)
		if not recebido.is_empty():
			break
	Eventos.jogador_morreu.disconnect(conexao)
	afirmar_igual(recebido.size(), 1, "evento de morte emitido depois da câmera lenta")
	if not recebido.is_empty():
		afirmar_igual(recebido[0].fonte_nome, "Ressequido", "a causa da morte é conhecida")
	afirmar_igual(int(Salvamento.dados.get("mortes", 0)), mortes_antes + 1, "morte registrada no progresso")
	# A escala volta no quadro seguinte (Efeitos só grava a escala no próprio _process).
	await get_tree().process_frame
	await get_tree().process_frame
	afirmar(is_equal_approx(Engine.time_scale, 1.0), "a câmera lenta terminou")


func _letal() -> DanoInfo:
	var d := DanoInfo.new()
	d.valor = 999.0
	d.interrupcao = DanoInfo.Interrupcao.FORTE
	d.direcao = Vector2.UP
	return d
