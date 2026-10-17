class_name RastroGolpe
extends Node2D
## Rastro do golpe: um crescente que acompanha a varredura da arma e se desfaz rápido.
## Desenhado em baixa resolução, já sai "pixelado" e casa com a arte.

const DESVANECER := 0.12

var _ativo := false
var _t := 0.0
var _duracao := 0.08
var _centro := 0.0
var _arco := 0.0
var _sentido := 1.0
var _raio := 26.0
var _fade := 0.0
var _cor := Color("f2e8d0")


func iniciar(direcao: Vector2, golpe: GolpeDados, pesado: bool) -> void:
	_ativo = true
	_t = 0.0
	_duracao = maxf(golpe.ativo, 0.03)
	_centro = direcao.angle()
	_arco = deg_to_rad(golpe.arco_graus)
	_sentido = float(golpe.sentido_giro)
	_raio = golpe.alcance
	_fade = 1.0
	_cor = Color("f7bb47") if pesado or golpe.interrupcao == DanoInfo.Interrupcao.FORTE else Color("f2e8d0")
	queue_redraw()


func _process(delta: float) -> void:
	if not _ativo and _fade <= 0.0:
		return
	_t += delta
	if _ativo and _t >= _duracao:
		_ativo = false
	if not _ativo:
		_fade = maxf(_fade - delta / DESVANECER, 0.0)
	queue_redraw()


func _draw() -> void:
	if _fade <= 0.0:
		return
	var k := clampf(_t / _duracao, 0.0, 1.0)
	var origem := Vector2(0, -9)
	if _sentido == 0.0:
		# Estocada: um rastro reto na direção do golpe.
		var dir := Vector2.from_angle(_centro)
		var lateral := dir.orthogonal()
		var alcance := _raio * ease(k, 0.3)
		if alcance < 8.0:
			return
		var pontos := PackedVector2Array([origem + lateral * 3.0 + dir * 6.0, origem + dir * alcance, origem - lateral * 3.0 + dir * 6.0])
		draw_colored_polygon(pontos, Color(_cor, 0.75 * _fade))
		return
	var inicio := _centro - _arco * 0.5 * _sentido
	var atual := inicio + _arco * _sentido * ease(k, 0.35)
	var cauda := inicio + (atual - inicio) * 0.15
	if absf(atual - cauda) < 0.08:
		return  # arco ainda curto demais para formar um polígono válido
	var segmentos := 10
	var externo := PackedVector2Array()
	var interno := PackedVector2Array()
	for i in segmentos + 1:
		var f := float(i) / segmentos
		var a := lerpf(cauda, atual, f)
		# O crescente engrossa em direção à ponta (onde está a arma agora).
		var espessura := lerpf(1.0, 7.0, f)
		externo.append(origem + Vector2.from_angle(a) * _raio)
		interno.append(origem + Vector2.from_angle(a) * (_raio - espessura))
	interno.reverse()
	var poligono := externo + interno
	draw_colored_polygon(poligono, Color(_cor, 0.55 * _fade))
	draw_polyline(externo, Color(1, 1, 1, 0.9 * _fade), 1.0)
