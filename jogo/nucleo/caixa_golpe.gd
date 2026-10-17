class_name CaixaGolpe
extends Area2D
## Área ofensiva. Enquanto ativa, acerta cada CaixaDano no máximo uma vez por ativação.

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
	monitoring = true
	# Áreas que já estavam sobrepostas não disparam area_entered; verificamos no próximo quadro físico.
	_verificar_sobrepostas.call_deferred()


func desativar() -> void:
	ativa = false
	set_deferred(&"monitoring", false)


func _verificar_sobrepostas() -> void:
	if not ativa:
		return
	await get_tree().physics_frame
	if not ativa:
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
	if not fabricar_dano.is_valid():
		return
	var info: DanoInfo = fabricar_dano.call(alvo)
	if info == null:
		return
	if caixa.receber(info):
		acertou.emit(alvo, info)
