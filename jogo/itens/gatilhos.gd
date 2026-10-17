class_name Gatilhos
extends RefCounted
## Distribui eventos da Coveira para os efeitos das relíquias carregadas,
## respeitando condições, chance, recarga interna e o limite de encadeamento.

## Recarga por efeito: instância do recurso → momento em que pode disparar de novo.
var _prontos_em: Dictionary = {}
var _tempo := 0.0


func avancar(delta: float) -> void:
	_tempo += delta


func disparar(gatilho: StringName, ctx: ContextoEfeito, itens: Array[ItemDados]) -> int:
	if ctx.info != null and not ctx.info.pode_encadear():
		return 0
	var disparados := 0
	for item in itens:
		for efeito in item.efeitos:
			if efeito == null or efeito.gatilho != gatilho:
				continue
			if _tempo < float(_prontos_em.get(efeito, -1.0)):
				continue
			if not efeito.condicoes_atendidas(ctx):
				continue
			if efeito.recarga > 0.0:
				_prontos_em[efeito] = _tempo + efeito.recarga
			efeito.executar(ctx)
			disparados += 1
	return disparados
