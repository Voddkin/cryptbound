class_name AnelOnda
extends Node2D
## Anel que se expande e some (badalo do Sino Rachado, impacto do golpe pesado...).

var raio_final := 48.0
var estilo: StringName = &"badalo"
var duracao := 0.28
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= duracao:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / duracao
	var raio := raio_final * (1.0 - pow(1.0 - k, 3.0))
	var cor := Color("f6c35a") if estilo == &"badalo" else Color("e8dcc0")
	cor.a = 1.0 - k
	var espessura := 3.0 if k < 0.3 else (2.0 if k < 0.65 else 1.0)
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 40, cor, espessura, false)
	if estilo == &"badalo" and k < 0.5:
		draw_arc(Vector2.ZERO, raio * 0.6, 0.0, TAU, 28, Color(1, 0.95, 0.75, (0.5 - k)), 1.0, false)
