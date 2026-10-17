class_name Escada
extends Node2D
## Escada que desce para a próxima profundidade (bloco 2×2 de células).

signal descer

var _interacao: InteracaoEscada


class InteracaoEscada:
	extends Interagivel
	var escada: Escada

	func texto_acao() -> String:
		return Textos.t("hud.descer")

	func interagir(_jogador: Node2D) -> void:
		escada.descer.emit()


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://arte/props/escada.png") as Texture2D
	sprite.centered = false
	sprite.position = Vector2(1, 5)
	add_child(sprite)
	var luz := LuzTremulante.new(Color(0.45, 0.8, 0.75), 0.35, 0.7, 77)
	luz.position = Vector2(16, 16)
	add_child(luz)
	_interacao = InteracaoEscada.new()
	_interacao.escada = self
	_interacao.definir_area(Vector2(30, 30), Vector2(16, 16))
	add_child(_interacao)
