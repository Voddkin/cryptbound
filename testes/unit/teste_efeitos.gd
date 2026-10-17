extends CasoTeste
## Hitstop e tremor pedidos durante a física sobrevivem ao quadro do impacto. O motor lê
## Engine.time_scale no início de cada iteração; medir o tempo com a escala nova cancelava
## o hitstop e o tremor no mesmo quadro em que nasciam.


func antes_de_cada() -> void:
	Efeitos.limpar_registro()
	await get_tree().process_frame


func depois_de_cada() -> void:
	Efeitos.limpar_registro()


## Conta, a partir de agora, quantos quadros rodam em câmera lenta (escala < limite).
func _quadros_lentos(limite: float, maximo: int = 30) -> int:
	var lentos := 0
	for i in maximo:
		await get_tree().process_frame
		if Engine.time_scale < limite:
			lentos += 1
	return lentos


func teste_hitstop_pedido_na_fisica_dura_o_tempo_pedido() -> void:
	await get_tree().physics_frame
	Efeitos.hitstop(0.045)
	afirmar(Efeitos.em_hitstop(), "o pedido já conta como hitstop")
	var lentos := await _quadros_lentos(0.5)
	# 0,045 s a 60 quadros por segundo ≈ 3 quadros congelados.
	afirmar(lentos >= 2 and lentos <= 4, "hitstop de 0,045 s deveria congelar 2–4 quadros, congelou %d" % lentos)
	afirmar(not Efeitos.em_hitstop(), "o hitstop termina")
	afirmar_proximo(Engine.time_scale, 1.0, 0.001, "a escala volta ao normal")


func teste_tremor_nao_some_no_quadro_do_impacto() -> void:
	await get_tree().physics_frame
	Efeitos.hitstop(0.09)
	Efeitos.tremer(0.3, Vector2.RIGHT)
	var trauma_inicial := Efeitos.trauma
	var chute_inicial := Efeitos.chute.length()
	afirmar(trauma_inicial > 0.0 and chute_inicial > 0.0, "tremor e recuo registrados")
	await get_tree().process_frame
	await get_tree().process_frame
	# Um quadro de decaimento real (1/60 s) tira ~0,037 do trauma; nunca tudo de uma vez.
	afirmar(Efeitos.trauma > trauma_inicial - 0.08, "trauma decai aos poucos (%.3f → %.3f)" % [trauma_inicial, Efeitos.trauma])
	afirmar(Efeitos.chute.length() > chute_inicial * 0.3, "o recuo da câmera ainda aparece")


func teste_hitstop_durante_camera_lenta_volta_para_a_camera_lenta() -> void:
	Efeitos.definir_escala_base(0.35)
	await get_tree().process_frame
	await get_tree().process_frame
	afirmar_proximo(Engine.time_scale, 0.35, 0.001, "câmera lenta aplicada")
	await get_tree().physics_frame
	Efeitos.hitstop(0.05)
	var lentos := await _quadros_lentos(0.1)
	afirmar(lentos >= 2 and lentos <= 4, "hitstop congelou %d quadros dentro da câmera lenta" % lentos)
	afirmar_proximo(Engine.time_scale, 0.35, 0.001, "depois do hitstop volta para 0,35, não para 1")
