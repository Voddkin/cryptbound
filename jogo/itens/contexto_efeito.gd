class_name ContextoEfeito
extends RefCounted
## Dados disponíveis para um efeito de item no momento em que ele dispara.

var jogador: Node2D
var alvo: Node2D
var info: DanoInfo
var posicao: Vector2
var rng: RandomNumberGenerator


func _init(p_jogador: Node2D = null, p_alvo: Node2D = null, p_info: DanoInfo = null, p_posicao: Vector2 = Vector2.ZERO) -> void:
	jogador = p_jogador
	alvo = p_alvo
	info = p_info
	posicao = p_posicao
	rng = Jogo.rng if Jogo else RandomNumberGenerator.new()
