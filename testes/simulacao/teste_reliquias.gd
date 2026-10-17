extends CasoTeste
## Simulação: relíquias mudam o comportamento e se combinam.

var m: MundoTeste


func antes_de_cada() -> void:
	m = MundoTeste.criar(self)


func depois_de_cada() -> void:
	m.queue_free()


func _item(id: String) -> ItemDados:
	return load("res://dados/itens/%s.tres" % id) as ItemDados


func teste_estado_aplicado_mostra_o_nome_sobre_o_alvo() -> void:
	await quadros(2)
	var alvo := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(40, 0))
	var sangria := EstadoSangria.new()
	alvo.estados.aplicar(sangria)
	var nomes: Array = m.numeros._lista.filter(func(n: Dictionary) -> bool: return n.get("texto", "") == Textos.t("estado.sangria"))
	afirmar_igual(nomes.size(), 1, "\"Sangria\" sobe sobre o alvo")
	alvo.estados.aplicar(EstadoSangria.new())
	nomes = m.numeros._lista.filter(func(n: Dictionary) -> bool: return n.has("texto"))
	afirmar_igual(nomes.size(), 1, "reaplicar (acumular) não repete o nome")


func teste_vela_perene_aumenta_e_acende() -> void:
	Jogo.perder_velas(2)
	var antes_max := Jogo.velas_max
	var antes := Jogo.velas
	Jogo.adicionar_item(_item("vela_perene"), m.jogador)
	afirmar_igual(Jogo.velas_max, antes_max + 1, "uma vela máxima a mais")
	afirmar_igual(Jogo.velas, antes + 1, "e uma vela acesa")
	afirmar(Jogo.tem_item(&"vela_perene"), "relíquia registrada")


func teste_presa_aplica_sangria_so_no_golpe_final() -> void:
	Jogo.adicionar_item(_item("presa_cao_de_cova"), m.jogador)
	await quadros(2)
	var alvo := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(20, 0))
	alvo.vida = 9999.0
	alvo.vida_max = 9999.0
	alvo.set_physics_process(false)
	m.entrada.mirar = Vector2.RIGHT
	var sangria_antes_do_final := false
	for i in 90:
		m.entrada.atacar = i % 6 == 0
		await quadros(1)
		if m.jogador._indice_atual < 2 and alvo.estados.tem(&"sangria"):
			sangria_antes_do_final = true
		if alvo.estados.tem(&"sangria"):
			break
	afirmar(alvo.estados.tem(&"sangria"), "golpe final aplicou Sangria")
	afirmar(not sangria_antes_do_final, "golpes leves não aplicam Sangria")


func teste_sino_rachado_empurra_e_atordoa_ao_esquivar() -> void:
	Jogo.adicionar_item(_item("sino_rachado"), m.jogador)
	await quadros(2)
	var r := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(24, 0))
	await quadros(1)
	var inicio := r.global_position
	m.entrada.esquivar = true
	m.entrada.mover = Vector2.LEFT
	await quadros(3)
	afirmar(r.estados.tem(&"atordoado"), "badalo atordoou o Ressequido")
	await quadros(12)
	afirmar(r.global_position.distance_to(inicio) > 12.0, "badalo empurrou o Ressequido (%.1f px)" % r.global_position.distance_to(inicio))


func teste_combinacao_sino_empurra_alvo_sangrando() -> void:
	# Sangria cobra por distância percorrida; o empurrão do Sino faz o alvo "andar" e sangrar.
	Jogo.adicionar_item(_item("sino_rachado"), m.jogador)
	await quadros(2)
	var r := m.inimigo(&"ressequido", m.jogador.global_position + Vector2(22, 0))
	r.vida = 500.0
	r.vida_max = 500.0
	r.estados.aplicar(EstadoSangria.new(3.0, 5.0, m.jogador))
	await quadros(2)
	var vida_antes := r.vida
	m.entrada.esquivar = true
	m.entrada.mover = Vector2.LEFT
	await quadros(30)
	afirmar(r.vida < vida_antes, "o empurrão fez o alvo sangrar (%.0f → %.0f)" % [vida_antes, r.vida])
