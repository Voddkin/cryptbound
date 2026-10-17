@tool
class_name EfeitoAplicarEstado
extends EfeitoDados
## Aplica um estado alterado ao alvo do golpe.

@export var estado: StringName = &"sangria"
@export var potencia: float = 3.0
@export var duracao: float = 4.0
@export var acumulos: int = 1


func executar(ctx: ContextoEfeito) -> void:
	if ctx.alvo == null or not is_instance_valid(ctx.alvo):
		return
	var estados: Estados = ctx.alvo.get_node_or_null(^"Estados")
	if estados == null:
		return
	var novo := FabricaEstados.criar(estado, potencia, duracao, ctx.jogador)
	if novo == null:
		return
	novo.acumulos = acumulos
	estados.aplicar(novo)
