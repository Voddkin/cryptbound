extends CasoTeste


func teste_sangria_causa_dano_por_distancia() -> void:
	var alvo := AlvoFalso.new()
	add_child(alvo)
	alvo.estados.aplicar(EstadoSangria.new(3.0, 10.0))
	await quadros(2)
	# Anda 100 px em 10 quadros: 5 passos de 20 px → 5 × 3 de dano.
	for i in 10:
		alvo.position.x += 10.0
		await quadros(1)
	afirmar_proximo(alvo.dano_total(), 15.0, 0.01, "dano total da sangria")
	alvo.queue_free()


func teste_sangria_parada_nao_causa_dano() -> void:
	var alvo := AlvoFalso.new()
	add_child(alvo)
	alvo.estados.aplicar(EstadoSangria.new(3.0, 10.0))
	await quadros(20)
	afirmar_igual(alvo.danos.size(), 0, "alvo parado não sangra")
	alvo.queue_free()


func teste_sangria_acumula_ate_tres() -> void:
	var alvo := AlvoFalso.new()
	add_child(alvo)
	for i in 5:
		alvo.estados.aplicar(EstadoSangria.new(3.0, 10.0))
	var s: Estado = alvo.estados.obter(&"sangria")
	afirmar_igual(s.acumulos, 3, "acúmulos limitados a 3")
	await quadros(2)
	alvo.position.x += 20.0
	await quadros(2)
	afirmar_proximo(alvo.dano_total(), 9.0, 0.01, "dano de um passo com 3 acúmulos")
	afirmar(alvo.danos[0].profundidade >= DanoInfo.MAX_PROFUNDIDADE, "dano de sangria não encadeia efeitos")
	alvo.queue_free()


func teste_estado_expira() -> void:
	var alvo := AlvoFalso.new()
	add_child(alvo)
	alvo.estados.aplicar(EstadoAtordoado.new(0.1))
	afirmar(alvo.estados.impede_acao(), "atordoado impede ação")
	await quadros(12)
	afirmar(not alvo.estados.tem(&"atordoado"), "atordoamento expirou")
	afirmar(not alvo.estados.impede_acao(), "sem estados, pode agir")
	alvo.queue_free()


func teste_fabrica_conhece_todos_os_estados() -> void:
	for id in FabricaEstados.CONHECIDOS:
		var e := FabricaEstados.criar(id, 1.0, 1.0)
		afirmar(e != null and e.id == id, "fábrica cria %s" % id)
