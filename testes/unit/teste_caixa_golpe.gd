extends CasoTeste
## Detecção área-área: golpe acerta uma vez por ativação e sobrevive a desativar+ativar no mesmo quadro.


func _montar() -> Array:
	var mundo := Node2D.new()
	add_child(mundo)
	var alvo := AlvoFalso.new()
	mundo.add_child(alvo)
	var caixa_dano := CaixaDano.new()
	caixa_dano.dono = alvo
	caixa_dano.collision_layer = 1 << 2
	caixa_dano.collision_mask = 0
	var forma_d := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 6.0
	forma_d.shape = circ
	caixa_dano.add_child(forma_d)
	alvo.add_child(caixa_dano)
	var golpe := CaixaGolpe.new()
	golpe.collision_layer = 0
	golpe.collision_mask = 1 << 2
	var forma_g := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(20, 20)
	forma_g.shape = ret
	golpe.add_child(forma_g)
	golpe.fabricar_dano = func(_alvo: Node2D) -> DanoInfo:
		var d := DanoInfo.new()
		d.valor = 7.0
		return d
	mundo.add_child(golpe)
	return [mundo, alvo, golpe]


func teste_acerta_uma_vez_por_ativacao() -> void:
	var partes := _montar()
	var alvo: AlvoFalso = partes[1]
	var golpe: CaixaGolpe = partes[2]
	await quadros(2)
	golpe.ativar()
	await quadros(6)
	afirmar_igual(alvo.danos.size(), 1, "um acerto na ativação")
	afirmar_proximo(alvo.dano_total(), 7.0, 0.01, "dano aplicado")
	golpe.desativar()
	await quadros(3)
	golpe.ativar()
	await quadros(6)
	afirmar_igual(alvo.danos.size(), 2, "nova ativação acerta de novo")
	partes[0].queue_free()


func teste_desativar_e_ativar_no_mesmo_quadro() -> void:
	var partes := _montar()
	var alvo: AlvoFalso = partes[1]
	var golpe: CaixaGolpe = partes[2]
	await quadros(2)
	golpe.ativar()
	await quadros(4)
	golpe.desativar()
	golpe.ativar()
	await quadros(6)
	afirmar(golpe.monitoring, "monitoramento termina ligado")
	afirmar_igual(alvo.danos.size(), 2, "golpe encadeado no mesmo quadro ainda acerta")
	partes[0].queue_free()


func teste_alvo_fora_do_alcance_nao_e_atingido() -> void:
	var partes := _montar()
	var alvo: AlvoFalso = partes[1]
	var golpe: CaixaGolpe = partes[2]
	alvo.position = Vector2(100, 0)
	await quadros(2)
	golpe.ativar()
	await quadros(6)
	afirmar_igual(alvo.danos.size(), 0, "sem sobreposição, sem dano")
	partes[0].queue_free()
