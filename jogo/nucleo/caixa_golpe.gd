class_name CaixaGolpe
extends Area2D
## Área ofensiva. Enquanto ativa, acerta cada CaixaDano no máximo uma vez por ativação.
##
## Ligar/desligar o monitoramento é sempre adiado (ordem FIFO garante que desativar+ativar
## no mesmo quadro termine ativo). O dano é aplicado fora de `area_entered` (que roda durante
## o flush de consultas da física), para o alvo poder mudar a própria física ao morrer.

signal acertou(alvo: Node2D, info: DanoInfo)

## Função que fabrica o DanoInfo para um alvo específico (permite direção por alvo).
var fabricar_dano: Callable
var _atingidos: Array[Node] = []
var ativa := false


func _init() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_ao_entrar_area)


func ativar() -> void:
	_atingidos.clear()
	ativa = true
	set_deferred(&"monitoring", true)
	_verificar_sobrepostas.call_deferred()


func desativar() -> void:
	ativa = false
	set_deferred(&"monitoring", false)


## Áreas que já estavam sobrepostas ao ligar podem não gerar area_entered; confere no
## próximo quadro de física.
func _verificar_sobrepostas() -> void:
	if not ativa or not is_inside_tree():
		return
	await get_tree().physics_frame
	if not ativa or not monitoring:
		return
	for area in get_overlapping_areas():
		_ao_entrar_area(area)


func _ao_entrar_area(area: Area2D) -> void:
	if not ativa or not area is CaixaDano:
		return
	var caixa := area as CaixaDano
	var alvo := caixa.dono
	if alvo == null or _atingidos.has(alvo):
		return
	_atingidos.append(alvo)
	_aplicar.call_deferred(caixa, alvo)


func _aplicar(caixa: CaixaDano, alvo: Node2D) -> void:
	if not is_instance_valid(caixa) or not is_instance_valid(alvo) or not fabricar_dano.is_valid():
		return
	var info: DanoInfo = fabricar_dano.call(alvo)
	if info == null:
		return
	if caixa.receber(info):
		acertou.emit(alvo, info)
