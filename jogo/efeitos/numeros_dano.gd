class_name NumerosDano
extends Node2D
## Números de dano que sobem e somem. Desenhados com contorno de 1 px para leitura.

const DURACAO := 0.65
const SUBIDA := 14.0

var _fonte: Font
var _lista: Array[Dictionary] = []


func _ready() -> void:
	_fonte = Fontes.pequena()


func adicionar(posicao: Vector2, valor: float, cor: Color, critico: bool) -> void:
	# Golpes quase simultâneos no mesmo alvo somam no mesmo número.
	for n in _lista:
		if n.pos.distance_to(posicao) < 6.0 and n.vida > DURACAO - 0.12 and n.cor == cor:
			n.valor += valor
			queue_redraw()
			return
	_lista.append({"pos": posicao + Vector2(randf_range(-3, 3), -18), "valor": valor, "cor": cor, "vida": DURACAO, "critico": critico})
	queue_redraw()


func _process(delta: float) -> void:
	if _lista.is_empty():
		return
	for n in _lista:
		n.vida -= delta
	_lista = _lista.filter(func(n: Dictionary) -> bool: return n.vida > 0.0)
	queue_redraw()


func _draw() -> void:
	if _fonte == null:
		return
	var tamanho := Fontes.TAMANHO_PEQUENA
	for n in _lista:
		var t: float = 1.0 - n.vida / DURACAO
		var subida := SUBIDA * (1.0 - pow(1.0 - minf(t * 1.6, 1.0), 3.0))
		var texto := str(int(roundf(n.valor)))
		var largura := _fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
		var pos := Vector2(roundf(n.pos.x - largura * 0.5), roundf(n.pos.y - subida))
		var cor: Color = n.cor
		if t > 0.7:
			cor.a = 1.0 - (t - 0.7) / 0.3
		var contorno := Color(0.05, 0.04, 0.06, cor.a)
		for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_string(_fonte, pos + d, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, contorno)
		draw_string(_fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
