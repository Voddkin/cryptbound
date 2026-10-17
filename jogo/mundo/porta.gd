class_name Porta
extends Node2D
## Passagem entre salas. Quando o combate começa, raízes brotam e fecham a passagem;
## quando a sala é purificada, elas recuam. A passagem de saída, aberta, leva à próxima sala.

signal atravessada(porta: Porta)

const T := 16

var simbolo := "^"
var direcao := Vector2i(0, -1)
var celulas: Array[Vector2i] = []
var eh_saida := false
var trancada := false
var _bloqueio: StaticBody2D
var _forma_bloqueio: CollisionShape2D
var _raizes: AnimatedSprite2D
var _gatilho: Area2D
var _usada := false


## Retângulo (em pixels, coordenadas da sala) coberto pelas células da passagem.
func retangulo() -> Rect2:
	var minimo := Vector2i(1 << 20, 1 << 20)
	var maximo := Vector2i(-(1 << 20), -(1 << 20))
	for c in celulas:
		minimo = minimo.min(c)
		maximo = maximo.max(c)
	return Rect2(Vector2(minimo * T), Vector2((maximo - minimo + Vector2i.ONE) * T))


func horizontal() -> bool:
	return simbolo == "^" or simbolo == "v"


func _ready() -> void:
	var r := retangulo()
	# A posição do nó fica na base da passagem (para o y-sort do arco).
	position = Vector2(r.position.x, r.end.y)
	var local := Rect2(Vector2(0, -r.size.y), r.size)
	if simbolo == "^":
		_criar_arco(local)
	else:
		_criar_escuridao(local)
	# Bloqueio físico (ativo só com a passagem trancada)
	_bloqueio = StaticBody2D.new()
	_bloqueio.collision_layer = 1
	_bloqueio.collision_mask = 0
	_forma_bloqueio = CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = local.size
	_forma_bloqueio.shape = ret
	_forma_bloqueio.position = local.get_center()
	_forma_bloqueio.disabled = true
	_bloqueio.add_child(_forma_bloqueio)
	add_child(_bloqueio)
	# Raízes na borda interna da passagem
	_raizes = BibliotecaSprites.criar_animado("res://arte/props/porta_raizes.json" if horizontal() else "res://arte/props/porta_raizes_v.json", &"crescer")
	_raizes.stop()
	_raizes.visible = false
	var borda := _borda_interna(local)
	_raizes.position = borda
	add_child(_raizes)
	# Gatilho de saída: só a parte mais externa da passagem
	_gatilho = Area2D.new()
	_gatilho.collision_layer = 0
	_gatilho.collision_mask = 1 << 1
	_gatilho.monitorable = false
	var forma_g := CollisionShape2D.new()
	var ret_g := RectangleShape2D.new()
	var externa := _faixa_externa(local)
	ret_g.size = externa.size
	forma_g.shape = ret_g
	forma_g.position = externa.get_center()
	_gatilho.add_child(forma_g)
	_gatilho.body_entered.connect(_ao_tocar)
	add_child(_gatilho)


func _borda_interna(local: Rect2) -> Vector2:
	match simbolo:
		"^": return Vector2(local.get_center().x, local.end.y + 2)
		"v": return Vector2(local.get_center().x, local.position.y + 18)
		"<": return Vector2(local.end.x + 2, local.end.y)
		">": return Vector2(local.position.x + 8, local.end.y)
	return local.get_center()


func _faixa_externa(local: Rect2) -> Rect2:
	match simbolo:
		"^": return Rect2(local.position, Vector2(local.size.x, 12))
		"v": return Rect2(Vector2(local.position.x, local.end.y - 12), Vector2(local.size.x, 12))
		"<": return Rect2(local.position, Vector2(10, local.size.y))
		">": return Rect2(Vector2(local.end.x - 10, local.position.y), Vector2(10, local.size.y))
	return local


func _criar_arco(local: Rect2) -> void:
	# Fundo escuro em toda a passagem + moldura de cantaria em volta das faces.
	var fundo := Polygon2D.new()
	fundo.polygon = PackedVector2Array([local.position, Vector2(local.end.x, local.position.y), local.end, Vector2(local.position.x, local.end.y)])
	fundo.color = Color("0b0910")
	add_child(fundo)
	var arco := Sprite2D.new()
	arco.texture = load("res://arte/props/arco_norte.png") as Texture2D
	arco.centered = false
	arco.position = Vector2(local.position.x - 6, local.end.y - arco.texture.get_height())
	add_child(arco)


func _criar_escuridao(local: Rect2) -> void:
	# Gradiente do chão para o breu, sugerindo que o corredor continua.
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([local.position, Vector2(local.end.x, local.position.y), local.end, Vector2(local.position.x, local.end.y)])
	var escuro := Color(0.04, 0.035, 0.06, 1.0)
	var claro := Color(0.04, 0.035, 0.06, 0.0)
	match simbolo:
		"v": p.vertex_colors = PackedColorArray([claro, claro, escuro, escuro])
		"<": p.vertex_colors = PackedColorArray([escuro, claro, claro, escuro])
		">": p.vertex_colors = PackedColorArray([claro, escuro, escuro, claro])
	add_child(p)


func trancar() -> void:
	if trancada:
		return
	trancada = true
	_forma_bloqueio.set_deferred(&"disabled", false)
	_raizes.visible = true
	_raizes.play(&"crescer")
	Efeitos.poeira(global_position + _raizes.position, 5)


func destrancar() -> void:
	if not trancada:
		return
	trancada = false
	_forma_bloqueio.set_deferred(&"disabled", true)
	_raizes.play_backwards(&"crescer")
	_raizes.animation_finished.connect(func() -> void: _raizes.visible = trancada, CONNECT_ONE_SHOT)


func _ao_tocar(corpo: Node2D) -> void:
	if not eh_saida or trancada or _usada:
		return
	if corpo.is_in_group(&"jogador"):
		_usada = true
		atravessada.emit(self)
