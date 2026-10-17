class_name Altar
extends Node2D
## Altar de relíquia: mostra um item flutuando; a Coveira escolhe um dos altares da sala
## e os outros itens se desfazem em pó.

signal escolhido(altar: Altar)

var item: ItemDados
var _icone: Sprite2D
var _luz: LuzTremulante
var _interacao: InteracaoAltar
var _t := 0.0


class InteracaoAltar:
	extends Interagivel
	var altar: Altar

	func texto_acao() -> String:
		if altar.item == null:
			return ""
		return Textos.t("hud.pegar", {"nome": altar.item.nome})

	func item_associado() -> ItemDados:
		return altar.item

	func interagir(jogador: Node2D) -> void:
		altar.entregar(jogador)


func _ready() -> void:
	add_child(BibliotecaSprites.criar_estatico("res://arte/props/altar.png"))
	var corpo := StaticBody2D.new()
	corpo.collision_layer = 1
	corpo.collision_mask = 0
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(14, 8)
	forma.shape = ret
	forma.position = Vector2(0, -4)
	corpo.add_child(forma)
	add_child(corpo)
	_icone = Sprite2D.new()
	_icone.position = Vector2(0, -26)
	add_child(_icone)
	_luz = LuzTremulante.new(Color(1, 1, 1), 0.7, 0.55, int(position.x))
	_luz.position = Vector2(0, -24)
	add_child(_luz)
	_interacao = InteracaoAltar.new()
	_interacao.altar = self
	_interacao.definir_area(Vector2(26, 22), Vector2(0, 4))
	add_child(_interacao)
	_atualizar()


func definir_item(novo: ItemDados) -> void:
	item = novo
	if is_inside_tree():
		_atualizar()


func _atualizar() -> void:
	_icone.texture = item.icone if item else null
	_luz.visible = item != null
	if item:
		_luz.color = item.cor_raridade()


func _process(delta: float) -> void:
	if item == null:
		return
	_t += delta
	_icone.position.y = -26 + roundf(sin(_t * 2.4) * 2.0)


func entregar(jogador: Node2D) -> void:
	if item == null:
		return
	var pego := item
	definir_item(null)
	Jogo.adicionar_item(pego, jogador)
	Audio.tocar(&"coletar_item", global_position)
	Efeitos.cinzas_cera(global_position + Vector2(0, -26), 8)
	escolhido.emit(self)


## Desfaz o item sem entregar (quando outro altar foi escolhido).
func desfazer() -> void:
	if item == null:
		return
	definir_item(null)
	Efeitos.poeira(global_position + Vector2(0, -26), 6)
	Efeitos.fumaca(global_position + Vector2(0, -24), 4)
