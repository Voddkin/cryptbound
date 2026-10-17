class_name Coletavel
extends Node2D
## Ossos (moeda) e tocos de vela (cura). Saltam ao surgir, quicam e, depois de um instante,
## são atraídos pela Coveira. A coleta é por distância (sem física).

enum Tipo { OSSO, VELA }

const RAIO_ATRACAO := 44.0
const RAIO_COLETA := 7.0
const GRAVIDADE := 360.0

var tipo: Tipo = Tipo.OSSO
var valor := 1
var _vel := Vector2.ZERO
var _z := 0.0
var _vz := 0.0
var _espera := 0.35
var _sprite: Sprite2D
var _sombra: Polygon2D
var _avisou := false


static func criar(p_tipo: Tipo, p_valor: int, posicao: Vector2, impulso: Vector2) -> Coletavel:
	var c := Coletavel.new()
	c.tipo = p_tipo
	c.valor = p_valor
	c.position = posicao
	c._vel = impulso
	c._z = 4.0
	c._vz = randf_range(70.0, 110.0)
	return c


func _ready() -> void:
	add_to_group(&"coletaveis")
	_sombra = Polygon2D.new()
	_sombra.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(0, -1), Vector2(3, 0), Vector2(0, 1)])
	_sombra.color = Color(0, 0, 0, 0.35)
	add_child(_sombra)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://arte/itens/osso.png" if tipo == Tipo.OSSO else "res://arte/itens/toco_vela.png") as Texture2D
	_sprite.centered = true
	add_child(_sprite)
	if tipo == Tipo.VELA:
		var luz := LuzTremulante.new(Color(1.0, 0.75, 0.45), 0.6, 0.5, int(position.x * 7.0))
		luz.position = Vector2(0, -6)
		add_child(luz)


func _physics_process(delta: float) -> void:
	_espera -= delta
	# Salto inicial
	if _z > 0.0 or _vz > 0.0:
		_vz -= GRAVIDADE * delta
		_z = maxf(_z + _vz * delta, 0.0)
		if _z == 0.0 and absf(_vz) > 40.0:
			_vz = -_vz * 0.35
		elif _z == 0.0:
			_vz = 0.0
	position += _vel * delta
	_vel = _vel.move_toward(Vector2.ZERO, 260.0 * delta)
	var jogador := get_tree().get_first_node_in_group(&"jogador") as Node2D
	if jogador and _espera <= 0.0 and _pode_coletar():
		var alvo := jogador.global_position + Vector2(0, -4)
		var dist := global_position.distance_to(alvo)
		if dist < RAIO_COLETA:
			_coletar()
			return
		if dist < RAIO_ATRACAO:
			var forca := lerpf(260.0, 90.0, dist / RAIO_ATRACAO)
			_vel = (alvo - global_position).normalized() * forca
	elif jogador and tipo == Tipo.VELA and not _avisou and global_position.distance_to(jogador.global_position) < 14.0:
		_avisou = true
		Eventos.mensagem.emit(Textos.t("hud.vida_cheia"), 1.6)
	_sprite.position = Vector2(0, -3 - roundf(_z) + (roundf(sin(Time.get_ticks_msec() / 260.0)) if _z == 0.0 and tipo == Tipo.VELA else 0.0))


func _pode_coletar() -> bool:
	return tipo == Tipo.OSSO or Jogo.velas < Jogo.velas_max


func _coletar() -> void:
	match tipo:
		Tipo.OSSO:
			Jogo.adicionar_ossos(valor)
			Audio.tocar(&"coletar_osso", global_position, 0.06)
		Tipo.VELA:
			Jogo.curar(valor)
			Audio.tocar(&"vela_acender", global_position)
			Eventos.mensagem.emit(Textos.t("hud.vela_acesa"), 1.4)
	queue_free()
