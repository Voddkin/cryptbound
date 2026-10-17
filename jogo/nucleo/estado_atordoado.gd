class_name EstadoAtordoado
extends Estado
## Atordoado: o alvo não age (não anda, não ataca) até o efeito passar.


func _init(p_duracao: float = 0.8, p_origem: Node2D = null) -> void:
	id = &"atordoado"
	duracao = p_duracao
	origem = p_origem


func reaplicar(novo: Estado) -> void:
	restante = maxf(restante, novo.duracao)


func impede_acao() -> bool:
	return true


func cor_realce() -> Color:
	return Color(0.95, 0.85, 0.45, 0.25)
