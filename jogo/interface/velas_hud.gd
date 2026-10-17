class_name VelasHud
extends Control
## As velas (vida) da Coveira: chamas tremulando; a que se apaga solta fumaça.

const ESPACO := 9
const JSON_VELA := "res://arte/interface/vela_hud.json"

var _quadros: SpriteFrames
var _atual := 0
var _maximo := 0
var _apagando: Dictionary[int, float] = {}
var _t := 0.0


func _ready() -> void:
	_quadros = BibliotecaSprites.carregar(JSON_VELA)["frames"]
	Eventos.velas_mudaram.connect(_ao_mudar)
	_ao_mudar(Jogo.velas, Jogo.velas_max)


func _ao_mudar(atual: int, maximo: int) -> void:
	for i in range(atual, mini(_atual, maximo)):
		_apagando[i] = 0.0
	_atual = atual
	_maximo = maximo
	custom_minimum_size = Vector2(maximo * ESPACO, 14)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	for i: int in _apagando.keys():
		_apagando[i] += delta
		if _apagando[i] > 0.6:
			_apagando.erase(i)
	queue_redraw()


func _draw() -> void:
	for i in _maximo:
		var tex: Texture2D
		if i < _atual:
			var f := int(_t * 6.0 + i * 1.7) % _quadros.get_frame_count(&"acesa")
			tex = _quadros.get_frame_texture(&"acesa", f)
		elif _apagando.has(i):
			var f := mini(int(_apagando[i] * 8.0), _quadros.get_frame_count(&"apagando") - 1)
			tex = _quadros.get_frame_texture(&"apagando", f)
		else:
			tex = _quadros.get_frame_texture(&"apagada", 0)
		draw_texture(tex, Vector2(i * ESPACO, 0))
