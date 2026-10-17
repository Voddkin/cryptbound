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
	afirmar(is_equal_approx(Engine.time_scale, 1.0), "a câmera lenta terminou")


func _letal() -> DanoInfo:
	var d := DanoInfo.new()
	d.valor = 999.0
	d.interrupcao = DanoInfo.Interrupcao.FORTE
	d.direcao = Vector2.UP
	return d
