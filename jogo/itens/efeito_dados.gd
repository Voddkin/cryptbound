@tool
class_name EfeitoDados
extends Resource
## Efeito de item: quando o `gatilho` acontece e as condições batem, `executar` roda.
## Subclasses implementam o comportamento; os parâmetros vêm do arquivo .tres.

## Gatilhos conhecidos: ao_adquirir, ao_acertar, ao_esquivar, ao_sofrer_dano,
## ao_eliminar, ao_limpar_sala.
@export var gatilho: StringName = &"ao_acertar"
## Para gatilhos com golpe: o golpe precisa ter todas estas etiquetas.
@export var requer_tags: Array[StringName] = []
## Para gatilhos com golpe: o golpe não pode ter nenhuma destas etiquetas.
@export var proibe_tags: Array[StringName] = []
@export_range(0.0, 1.0) var chance: float = 1.0
## Recarga interna em segundos (0 = sem recarga).
@export var recarga: float = 0.0


func condicoes_atendidas(ctx: ContextoEfeito) -> bool:
	if ctx.info != null:
		for tag in requer_tags:
			if not ctx.info.tem_tag(tag):
				return false
		for tag in proibe_tags:
			if ctx.info.tem_tag(tag):
				return false
	if chance < 1.0 and ctx.rng.randf() > chance:
		return false
	return true


func executar(_ctx: ContextoEfeito) -> void:
	pass
