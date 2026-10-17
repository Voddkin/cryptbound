class_name SistemaParticulas
extends Node2D
## Partículas de pixel com altura simulada (z): estilhaços sobem, caem, quicam e,
## se marcados, deixam mancha no chão. Desenhadas como retângulos de 1–2 px.

enum Tipo { FAISCA, ESTILHACO, POEIRA, FUMACA }

const GRAVIDADE := 340.0
const MAXIMO := 900


class Particula:
	var tipo: int
	var pos: Vector2
	var vel: Vector2
	var z: float
	var vz: float
	var vida: float
	var vida_total: float
	var cor: Color
	var tamanho: int
	var mancha: bool
	var quiques: int


var _lista: Array[Particula] = []
var manchas: ManchasChao


func _process(delta: float) -> void:
	if _lista.is_empty():
		return
	var i := 0
	while i < _lista.size():
		var p := _lista[i]
		p.vida -= delta
		if p.vida <= 0.0:
			_lista.remove_at(i)
			continue
		match p.tipo:
			Tipo.FAISCA:
				p.pos += p.vel * delta
				p.vel *= 1.0 - minf(1.0, 9.0 * delta)
			Tipo.ESTILHACO:
				p.pos += p.vel * delta
				p.vz -= GRAVIDADE * delta
				p.z += p.vz * delta
				if p.z <= 0.0:
					p.z = 0.0
					if p.mancha and manchas:
						manchas.manchar(p.pos, p.cor.darkened(0.15), 0)
						_lista.remove_at(i)
						continue
					if p.quiques > 0 and absf(p.vz) > 25.0:
						p.vz = -p.vz * 0.35
						p.vel *= 0.5
						p.quiques -= 1
					else:
						p.vz = 0.0
						p.vel *= 1.0 - minf(1.0, 12.0 * delta)
			Tipo.POEIRA, Tipo.FUMACA:
				p.pos += p.vel * delta
				p.vel *= 1.0 - minf(1.0, 3.0 * delta)
				p.z += (6.0 if p.tipo == Tipo.POEIRA else 14.0) * delta
		i += 1
	queue_redraw()


func _draw() -> void:
	for p in _lista:
		var cor := p.cor
		var t := p.vida / p.vida_total
		if p.tipo in [Tipo.POEIRA, Tipo.FUMACA]:
			cor.a *= t
		elif p.tipo == Tipo.FAISCA:
			cor = cor.lerp(Color("f6c35a"), 1.0 - t)
		var x := roundf(p.pos.x)
		var y := roundf(p.pos.y - p.z)
		draw_rect(Rect2(x, y, p.tamanho, p.tamanho), cor)
		if p.tipo == Tipo.FAISCA and t > 0.4:
			var rastro := -p.vel.normalized() * 2.0
			draw_rect(Rect2(x + roundf(rastro.x), y + roundf(rastro.y), 1, 1), cor.darkened(0.3))


func _adicionar(p: Particula) -> void:
	if _lista.size() >= MAXIMO:
		_lista.remove_at(0)
	_lista.append(p)
	queue_redraw()


func faiscas(posicao: Vector2, direcao: Vector2, quantidade: int) -> void:
	var base := direcao.angle() if direcao != Vector2.ZERO else randf() * TAU
	for i in quantidade:
		var p := Particula.new()
		p.tipo = Tipo.FAISCA
		p.pos = posicao
		var ang := base + randf_range(-0.9, 0.9)
		p.vel = Vector2.from_angle(ang) * randf_range(90.0, 190.0)
		p.vida = randf_range(0.08, 0.18)
		p.vida_total = p.vida
		p.cor = Color("fff1b8")
		p.tamanho = 1
		_adicionar(p)


func estilhacos(posicao: Vector2, direcao: Vector2, quantidade: int, cores: Array, deixa_mancha: bool) -> void:
	var base := direcao.angle() if direcao != Vector2.ZERO else randf() * TAU
	for i in quantidade:
		var p := Particula.new()
		p.tipo = Tipo.ESTILHACO
		p.pos = posicao + Vector2(randf_range(-2, 2), 6.0)
		var ang := base + randf_range(-0.8, 0.8)
		p.vel = Vector2.from_angle(ang) * randf_range(25.0, 85.0)
		p.z = randf_range(5.0, 10.0)
		p.vz = randf_range(30.0, 85.0)
		p.vida = randf_range(0.6, 1.4) if not deixa_mancha else 3.0
		p.vida_total = p.vida
		p.cor = cores[randi() % cores.size()]
		p.tamanho = 1 if randf() < 0.7 else 2
		p.mancha = deixa_mancha
		p.quiques = 1
		_adicionar(p)


func poeira(posicao: Vector2, quantidade: int, direcao: Vector2 = Vector2.ZERO) -> void:
	for i in quantidade:
		var p := Particula.new()
		p.tipo = Tipo.POEIRA
		p.pos = posicao + Vector2(randf_range(-3, 3), randf_range(-1, 1))
		p.vel = direcao * randf_range(10.0, 30.0) + Vector2(randf_range(-8, 8), randf_range(-3, 3))
		p.vida = randf_range(0.3, 0.55)
		p.vida_total = p.vida
		p.cor = Color(0.72, 0.68, 0.62, 0.55)
		p.tamanho = 2 if randf() < 0.5 else 1
		_adicionar(p)


func fumaca(posicao: Vector2, quantidade: int) -> void:
	for i in quantidade:
		var p := Particula.new()
		p.tipo = Tipo.FUMACA
		p.pos = posicao + Vector2(randf_range(-2, 2), 0)
		p.vel = Vector2(randf_range(-6, 6), randf_range(-4, 0))
		p.vida = randf_range(0.6, 1.1)
		p.vida_total = p.vida
		p.cor = Color(0.35, 0.32, 0.38, 0.6)
		p.tamanho = 2
		_adicionar(p)


func quantidade() -> int:
	return _lista.size()
