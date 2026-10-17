class_name CaixaDano
extends Area2D
## Área vulnerável de uma entidade. Repassa o golpe ao dono, que decide se o aceita
## (invulnerabilidade, esquiva etc.).

var dono: Node2D


func _init() -> void:
	monitoring = false
	monitorable = true


func receber(info: DanoInfo) -> bool:
	if dono == null or not is_instance_valid(dono):
		return false
	if not dono.has_method(&"receber_dano"):
		return false
	return dono.receber_dano(info)
