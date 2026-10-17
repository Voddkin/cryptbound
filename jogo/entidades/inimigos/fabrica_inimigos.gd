class_name FabricaInimigos
extends RefCounted
## Cria inimigos a partir do identificador usado nas salas.

const CONHECIDOS: Array[StringName] = [&"ressequido", &"lamuriante"]


static func criar(tipo: StringName) -> Inimigo:
	match tipo:
		&"ressequido":
			return Ressequido.new()
		&"lamuriante":
			return Lamuriante.new()
	push_error("Inimigo desconhecido: %s" % tipo)
	return null
