class_name FabricaEstados
extends RefCounted
## Cria estados a partir do identificador usado nos arquivos de dados.

const CONHECIDOS: Array[StringName] = [&"sangria", &"atordoado"]


static func criar(id: StringName, potencia: float, duracao: float, origem: Node2D = null) -> Estado:
	match id:
		&"sangria":
			return EstadoSangria.new(potencia, duracao, origem)
		&"atordoado":
			return EstadoAtordoado.new(duracao, origem)
	push_error("Estado desconhecido: %s" % id)
	return null
