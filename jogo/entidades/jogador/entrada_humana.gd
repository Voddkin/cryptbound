class_name EntradaHumana
extends FonteEntrada
## Lê teclado, mouse e controle pelo mapa de ações registrado em `Controles`.


func atualizar(jogador: Node2D, _delta: float) -> void:
	mover = Input.get_vector(&"mover_esquerda", &"mover_direita", &"mover_cima", &"mover_baixo")
	atacar = Input.is_action_just_pressed(&"atacar")
	esquivar = Input.is_action_just_pressed(&"esquivar")
	interagir = Input.is_action_just_pressed(&"interagir")
	pesado = Input.is_action_pressed(&"pesado")
	mirar = Vector2.ZERO
	if Controles.usando_controle:
		mirar = Controles.mira_analogica().normalized()
	elif Controles.mouse_ativo() and jogador.is_inside_tree():
		var alvo := jogador.get_global_mouse_position()
		var origem := jogador.global_position + Vector2(0, -9)
		if alvo.distance_to(origem) > 2.0:
			mirar = (alvo - origem).normalized()
