extends CasoTeste
## Simulação: movimento, colisão, esquiva, combo e buffer de entrada da Coveira.

var m: MundoTeste


func antes_de_cada() -> void:
	m = MundoTeste.criar(self)


func depois_de_cada() -> void:
	m.queue_free()


func teste_move_em_oito_direcoes_sem_passar_da_velocidade() -> void:
	await quadros(2)
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0)
		m.jogador.global_position = m.centro()
		m.jogador.velocity = Vector2.ZERO
		await quadros(1)
		var inicio := m.jogador.global_position
		m.entrada.mover = dir
		await quadros(20)
		var desloc := m.jogador.global_position - inicio
		afirmar(desloc.normalized().dot(dir) > 0.98, "direção %d seguida (%s)" % [i, desloc])
		afirmar(m.jogador.velocity.length() <= Jogador.VELOCIDADE + 0.5, "velocidade %d limitada (%.1f)" % [i, m.jogador.velocity.length()])
		m.entrada.mover = Vector2.ZERO
		await quadros(12)
		afirmar(m.jogador.velocity.length() < 1.0, "para ao soltar (%d)" % i)


func teste_aceleracao_e_curta() -> void:
	await quadros(2)
	m.entrada.mover = Vector2.RIGHT
	await quadros(7)  # ~0,12 s
	afirmar(m.jogador.velocity.x >= Jogador.VELOCIDADE * 0.95, "atinge a velocidade máxima em ~0,1 s (%.1f)" % m.jogador.velocity.x)


func teste_colide_com_parede() -> void:
	await quadros(2)
	m.entrada.mover = Vector2.LEFT
	await quadros(150)
	# A parede oeste ocupa x < 16; o corpo (raio 4,5) não pode atravessá-la.
	afirmar(m.jogador.global_position.x >= 16.0 + 4.0, "parou na parede (x=%.1f)" % m.jogador.global_position.x)
	afirmar(m.jogador.global_position.x < 30.0, "chegou até a parede (x=%.1f)" % m.jogador.global_position.x)


func _golpe_inimigo() -> DanoInfo:
	var info := DanoInfo.new()
	info.valor = 1.0
	info.velas = 1
	info.fonte_nome = "Teste"
	info.direcao = Vector2.RIGHT
	return info


func teste_esquiva_concede_invulnerabilidade() -> void:
	await quadros(2)
	m.entrada.mover = Vector2.RIGHT
	m.entrada.esquivar = true
	await quadros(2)
	afirmar_igual(m.jogador.estado, Jogador.Situacao.ESQUIVANDO, "entrou na esquiva")
	var velas := Jogo.velas
	afirmar(not m.jogador.receber_dano(_golpe_inimigo()), "golpe durante a esquiva é ignorado")
	afirmar_igual(Jogo.velas, velas, "nenhuma vela perdida")
	m.entrada.mover = Vector2.ZERO
	await quadros(40)
	afirmar_igual(m.jogador.estado, Jogador.Situacao.LIVRE, "esquiva terminou")
	afirmar(m.jogador.receber_dano(_golpe_inimigo()), "depois da esquiva o golpe acerta")
	afirmar_igual(Jogo.velas, velas - 1, "perdeu uma vela")
	afirmar(not m.jogador.receber_dano(_golpe_inimigo()), "invulnerabilidade curta após o dano")


func teste_golpe_no_fim_da_esquiva_restaura_colisao_com_inimigos() -> void:
	await quadros(2)
	m.entrada.mover = Vector2.RIGHT
	m.entrada.esquivar = true
	await quadros(1)
	m.entrada.esquivar = false
	# Espera passar a invulnerabilidade (0,18 s) sem terminar a esquiva (0,24 s).
	while m.jogador.estado == Jogador.Situacao.ESQUIVANDO and m.jogador.invulneravel():
		await quadros(1)
	afirmar_igual(m.jogador.estado, Jogador.Situacao.ESQUIVANDO, "ainda na cauda da esquiva")
	afirmar(m.jogador.receber_dano(_golpe_inimigo()), "a cauda da esquiva é vulnerável")
	afirmar(m.jogador.collision_mask & Jogador.CAMADA_INIMIGOS != 0, "volta a colidir com inimigos")
	m.entrada.mover = Vector2.ZERO
	m.entrada.esquivar = true
	await quadros(14)
	afirmar(m.jogador.estado != Jogador.Situacao.ESQUIVANDO, "a recarga da esquiva também foi aplicada")


func teste_esquiva_percorre_distancia_util() -> void:
	await quadros(2)
	var inicio := m.jogador.global_position
	m.entrada.esquivar = true
	m.entrada.mover = Vector2.RIGHT
	await quadros(16)
	var dist := m.jogador.global_position.x - inicio.x
	afirmar(dist > 38.0 and dist < 80.0, "esquiva desloca ~40–70 px (%.1f)" % dist)


func teste_combo_completo_mata_ressequido() -> void:
	await quadros(2)
	var alvo := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(20, 0))
	alvo.set_physics_process(false)  # alvo parado para medir só o combo
	m.jogador.mira = Vector2.RIGHT
	m.entrada.mirar = Vector2.RIGHT
	var golpes_vistos := {}
	for i in 90:
		m.entrada.atacar = i % 6 == 0
		await quadros(1)
		if m.jogador.estado == Jogador.Situacao.ATACANDO:
			golpes_vistos[m.jogador._indice_atual] = true
	afirmar(golpes_vistos.has(0) and golpes_vistos.has(1) and golpes_vistos.has(2), "os três golpes do combo saíram (%s)" % [golpes_vistos.keys()])
	afirmar(not alvo.esta_vivo(), "Ressequido abatido pelo combo (vida %.1f)" % alvo.vida)


func teste_buffer_guarda_ataque_apertado_durante_esquiva() -> void:
	await quadros(2)
	m.entrada.esquivar = true
	await quadros(3)
	# Ataque apertado logo no começo da esquiva deve sair assim que ela termina.
	m.entrada.atacar = true
	var saiu_em := -1
	for i in 30:
		await quadros(1)
		if m.jogador.estado == Jogador.Situacao.ATACANDO:
			saiu_em = i
			break
	afirmar(saiu_em >= 0, "ataque pedido durante a esquiva saiu depois dela")
	afirmar(saiu_em <= 16, "e saiu logo após o fim da esquiva (quadro %d)" % saiu_em)
