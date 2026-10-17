class_name AlvoFalso
extends Node2D
## Alvo mínimo para testes: registra o dano recebido e tem um contêiner de Estados.

var danos: Array[DanoInfo] = []
var aceitar := true
var estados: Estados


func _init() -> void:
	estados = Estados.new()
	estados.name = "Estados"
	add_child(estados)
	add_to_group(&"inimigos")


func receber_dano(info: DanoInfo) -> bool:
	if not aceitar:
		return false
	danos.append(info)
	return true


func dano_total() -> float:
	var total := 0.0
	for d in danos:
		total += d.valor
	return total
