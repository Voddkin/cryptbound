class_name Estados
extends Node
## Contêiner de estados alterados de uma entidade. Mede a distância percorrida pelo
## hospedeiro a cada quadro físico (base da Sangria).

signal estado_adicionado(estado: Estado)
signal estado_removido(estado: Estado)

var hospedeiro: Node2D
var _ativos: Dictionary[StringName, Estado] = {}
var _ultima_posicao := Vector2.INF


func _ready() -> void:
	if hospedeiro == null:
		hospedeiro = get_parent() as Node2D


func aplicar(estado: Estado) -> void:
	if hospedeiro == null or not is_instance_valid(hospedeiro):
		return
	if _ativos.has(estado.id):
		_ativos[estado.id].reaplicar(estado)
		return
	estado.hospedeiro = hospedeiro
	estado.restante = estado.duracao
	_ativos[estado.id] = estado
	estado.ao_aplicar()
	estado_adicionado.emit(estado)
	Eventos.estado_aplicado.emit(hospedeiro, estado.id)


func remover(id: StringName) -> void:
	if not _ativos.has(id):
		return
	var estado: Estado = _ativos[id]
	_ativos.erase(id)
	estado.ao_remover()
	estado_removido.emit(estado)


func limpar() -> void:
	for id: StringName in _ativos.keys():
		remover(id)


func tem(id: StringName) -> bool:
	return _ativos.has(id)


func obter(id: StringName) -> Estado:
	return _ativos.get(id)


func ativos() -> Array[Estado]:
	var lista: Array[Estado] = []
	lista.assign(_ativos.values())
	return lista


func impede_acao() -> bool:
	for estado: Estado in _ativos.values():
		if estado.impede_acao():
			return true
	return false


func cor_realce() -> Color:
	var cor := Color(0, 0, 0, 0)
	for estado: Estado in _ativos.values():
		var c := estado.cor_realce()
		if c.a > cor.a:
			cor = c
	return cor


func _physics_process(delta: float) -> void:
	if hospedeiro == null or not is_instance_valid(hospedeiro):
		return
	var pos := hospedeiro.global_position
	var distancia := 0.0 if _ultima_posicao == Vector2.INF else pos.distance_to(_ultima_posicao)
	_ultima_posicao = pos
	if _ativos.is_empty():
		return
	for id: StringName in _ativos.keys():
		var estado: Estado = _ativos.get(id)
		if estado == null:
			continue
		if distancia > 0.01:
			estado.ao_mover(distancia)
		estado.ao_processar(delta)
		estado.restante -= delta
		if estado.restante <= 0.0 and _ativos.get(id) == estado:
			remover(id)
