class_name ProjetilLamuria
extends Area2D
## Onda de lamento da Lamuriante: lenta, some ao bater em parede ou objeto, e pode ser
## dissipada por um golpe da Coveira.

const VELOCIDADE := 82.0
const DURACAO := 4.5

var direcao := Vector2.RIGHT
var dados_origem: InimigoDados
var atirador: Node2D
var _vida := DURACAO
var _sprite: AnimatedSprite2D
var _desfeito := false


func _ready() -> void:
	collision_layer = 0
	# Detecta a CaixaDano da Coveira (camada 2) e paredes/objetos (camada 1).
	collision_mask = 1 | (1 << 1)
	monitorable = false
	var forma := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 5.0
	forma.shape = circ
	add_child(forma)
	_sprite = BibliotecaSprites.criar_animado("res://arte/efeitos/lamuria.json", &"voar")
	_sprite.rotation = direcao.angle()
	add_child(_sprite)
	var luz := PointLight2D.new()
	luz.texture = preload("res://arte/luzes/luz_pequena.png")
	luz.color = Color("9a5cd0")
	luz.energy = 0.9
	luz.texture_scale = 0.8
	add_child(luz)
	# Uma CaixaDano própria permite que o golpe da Coveira dissipe a onda.
	var caixa := CaixaDano.new()
	caixa.dono = self
	caixa.collision_layer = 1 << 2
	var forma_c := CollisionShape2D.new()
	var circ_c := CircleShape2D.new()
	circ_c.radius = 6.0
	forma_c.shape = circ_c
	caixa.add_child(forma_c)
	add_child(caixa)
	area_entered.connect(_ao_tocar_area)
	body_entered.connect(_ao_tocar_corpo)
	Eventos.sala_limpa.connect(_ao_purificar_sala)


## Sala purificada: nenhum lamento sobrevive a ela.
func _ao_purificar_sala(_sala: Node) -> void:
	_desfazer.call_deferred()


func _physics_process(delta: float) -> void:
	position += direcao * VELOCIDADE * delta
	_vida -= delta
	if _vida <= 0.0:
		_desfazer()


func _ao_tocar_area(area: Area2D) -> void:
	if _desfeito or not area is CaixaDano:
		return
	var alvo := (area as CaixaDano).dono
	if alvo == null or not alvo.is_in_group(&"jogador"):
		return
	_atingir.call_deferred(area)


func _atingir(area: CaixaDano) -> void:
	if _desfeito or not is_instance_valid(area):
		return
	var info := DanoInfo.new()
	info.valor = 1.0
	info.velas = dados_origem.velas_de_dano if dados_origem else 1
	info.atacante = atirador if is_instance_valid(atirador) else null
	info.fonte_nome = dados_origem.nome if dados_origem else ""
	info.ataque_nome = dados_origem.ataque if dados_origem else ""
	info.dica = dados_origem.dica if dados_origem else ""
	info.direcao = direcao
	info.empurrao = 120.0
	info.hitstop = 0.06
	info.tremor = 0.35
	if area.receber(info):
		_desfazer()


func _ao_tocar_corpo(corpo: Node2D) -> void:
	if corpo is TileMapLayer or corpo is StaticBody2D:
		_desfazer.call_deferred()


## Atingida por um golpe da Coveira: a onda se dissipa.
func receber_dano(_info: DanoInfo) -> bool:
	if _desfeito:
		return false
	Audio.tocar(&"lamuria_disparo", global_position, 0.2, -8.0)
	_desfazer.call_deferred()
	return true


func esta_vivo() -> bool:
	return not _desfeito


func _desfazer() -> void:
	if _desfeito:
		return
	_desfeito = true
	Efeitos.cinzas_cera(global_position, 5)
	queue_free()
