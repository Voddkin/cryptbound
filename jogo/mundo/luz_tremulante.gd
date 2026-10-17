class_name LuzTremulante
extends PointLight2D
## Luz de vela: energia e tamanho oscilam com ruído suave (cada luz com sua semente).

const TEXTURA := preload("res://arte/luzes/luz_suave.png")

var energia_base := 1.0
var escala_base := 1.0
var intensidade_tremor := 0.12
var _ruido := FastNoiseLite.new()
var _t := 0.0


func _init(cor: Color = Color(1.0, 0.72, 0.42), energia: float = 1.0, escala: float = 1.4, semente: int = 0) -> void:
	texture = TEXTURA
	color = cor
	energia_base = energia
	escala_base = escala
	energy = energia
	texture_scale = escala
	shadow_enabled = false
	_ruido.seed = semente
	_ruido.frequency = 2.2
	_t = float(semente % 97)


func _process(delta: float) -> void:
	_t += delta
	var n := _ruido.get_noise_1d(_t * 4.0)
	energy = energia_base * (1.0 + n * intensidade_tremor)
	texture_scale = escala_base * (1.0 + n * intensidade_tremor * 0.35)
