class_name EstadoSangria
extends Estado
## Sangria: o alvo sangra conforme se move. A cada PASSO pixels percorridos sofre
## `dano_por_passo × acúmulos`. Empurrar um alvo sangrando o faz sangrar mais.

const PASSO := 20.0

var dano_por_passo := 3.0
var _distancia_acumulada := 0.0


func _init(p_dano_por_passo: float = 3.0, p_duracao: float = 4.0, p_origem: Node2D = null) -> void:
	id = &"sangria"
	dano_por_passo = p_dano_por_passo
	duracao = p_duracao
	max_acumulos = 3
	origem = p_origem


func ao_mover(distancia: float) -> void:
	_distancia_acumulada += distancia
	while _distancia_acumulada >= PASSO:
		_distancia_acumulada -= PASSO
		_sangrar()
		if hospedeiro == null or not is_instance_valid(hospedeiro):
			return


func _sangrar() -> void:
	if not hospedeiro.has_method(&"receber_dano"):
		return
	var info := DanoInfo.new()
	info.valor = dano_por_passo * acumulos
	info.atacante = origem if is_instance_valid(origem) else null
	info.tags = [&"estado", &"sangria"]
	info.interrupcao = DanoInfo.Interrupcao.NENHUMA
	info.profundidade = DanoInfo.MAX_PROFUNDIDADE
	hospedeiro.receber_dano(info)
	Efeitos.sangue(hospedeiro.global_position + Vector2(0, -6), Vector2.DOWN, 3)


func cor_realce() -> Color:
	return Color(0.75, 0.1, 0.12, 0.35 + 0.1 * acumulos)
