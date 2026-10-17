class_name Interagivel
extends Area2D
## Algo com que a Coveira interage (altar, escada...). Detecta a entrada do corpo da
## Coveira e se registra nela; a Coveira escolhe o mais próximo e mostra a dica.

const CAMADA_INTERAGIVEIS := 1 << 6
const CAMADA_JOGADOR := 1 << 1


func _init() -> void:
	collision_layer = CAMADA_INTERAGIVEIS
	collision_mask = CAMADA_JOGADOR
	monitoring = true
	monitorable = false
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func definir_area(tamanho: Vector2, centro: Vector2 = Vector2.ZERO) -> void:
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = tamanho
	forma.shape = ret
	forma.position = centro
	add_child(forma)


## Texto da ação ("Pegar Sino Rachado"). Vazio = sem interação no momento.
func texto_acao() -> String:
	return ""


func item_associado() -> ItemDados:
	return null


func interagir(_jogador: Node2D) -> void:
	pass


func _ao_entrar(corpo: Node2D) -> void:
	if corpo.has_method(&"registrar_interagivel"):
		corpo.registrar_interagivel(self)


func _ao_sair(corpo: Node2D) -> void:
	if corpo.has_method(&"remover_interagivel"):
		corpo.remover_interagivel(self)
