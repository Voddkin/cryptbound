class_name BotaoMenu
extends Button
## Botão de menu: realça com a chama ao lado quando focado; som ao navegar e confirmar.
## O mouse por cima também dá foco, então teclado, controle e mouse se comportam igual.

const MARCADOR := preload("res://arte/interface/marcador.png")


func _init(texto: String = "") -> void:
	text = texto
	flat = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(0, 20)
	focus_entered.connect(func() -> void:
		Audio.tocar(&"ui_mover")
		queue_redraw())
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(grab_focus)
	pressed.connect(func() -> void: Audio.tocar(&"ui_confirmar"))


func _draw() -> void:
	if has_focus():
		var y := size.y * 0.5 - MARCADOR.get_height() * 0.5
		draw_texture(MARCADOR, Vector2(-MARCADOR.get_width() - 4, roundf(y)))
