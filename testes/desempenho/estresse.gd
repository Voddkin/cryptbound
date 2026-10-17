extends Node
## Cena de estresse (não é um teste automático): uma descida real com o robô de
## demonstração, 30 inimigos erguidos de uma vez e rajadas constantes de partículas.
## Mede o tempo de quadro e imprime média, p95 e pior caso.
## `-- --inimigos=N` muda a quantidade (0 = linha de base).
## Rode com renderização (sob Xvfb, por exemplo) e sem --fixed-fps, para medir tempo real:
##   godot --path . --rendering-driver opengl3 res://testes/desempenho/estresse.tscn -- --demo

var inimigos := 30
const QUADROS_AQUECIMENTO := 120
const QUADROS_MEDIDOS := 900

var _descida: Descida
var _tempos: PackedFloat64Array = []
var _processo: PackedFloat64Array = []
var _fisica: PackedFloat64Array = []
var _ultimo_us := 0
var _quadro := 0
var _maximo_nos := 0
var _maximo_desenhos := 0


func _ready() -> void:
	Engine.max_fps = 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--inimigos="):
			inimigos = int(arg.get_slice("=", 1))
	Jogo.nova_descida(1234)
	_descida = load("res://jogo/mundo/descida.tscn").instantiate()
	add_child(_descida)


func _process(_delta: float) -> void:
	_quadro += 1
	var agora := Time.get_ticks_usec()
	if _quadro == 30:
		_erguer_horda()
	if _quadro % 20 == 0:
		_rajada()
	# Mantém a Coveira de pé para o estresse durar.
	if Jogo.velas < 3:
		Jogo.curar(Jogo.velas_max)
	if _quadro > QUADROS_AQUECIMENTO and _ultimo_us > 0:
		_tempos.append((agora - _ultimo_us) / 1000.0)
		_processo.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		_fisica.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_maximo_nos = maxi(_maximo_nos, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		_maximo_desenhos = maxi(_maximo_desenhos, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_ultimo_us = agora
	if _tempos.size() >= QUADROS_MEDIDOS:
		_relatar()
		get_tree().quit()


func _erguer_horda() -> void:
	var sala := _descida.sala
	var tipos: Array[StringName] = [&"ressequido", &"ressequido", &"lamuriante"]
	var erguidos := 0
	for i in inimigos:
		var c := sala.celula_livre_aleatoria(_descida.jogador.global_position, 48.0)
		if c.x < 0:
			continue
		var inimigo := FabricaInimigos.criar(tipos[i % tipos.size()])
		inimigo.sala = sala
		inimigo.position = sala.centro_celula(c) + Vector2(0, 4)
		sala.mundo.add_child(inimigo)
		inimigo.pular_surgimento()
		erguidos += 1
	print("estresse: %d inimigos erguidos na sala '%s'" % [erguidos, sala.definicao.id])


func _rajada() -> void:
	var centro := _descida.sala.retangulo().get_center()
	var p := centro + Vector2(randf_range(-120, 120), randf_range(-60, 60))
	Efeitos.sangue(p, Vector2.RIGHT.rotated(randf() * TAU), 12)
	Efeitos.poeira(p, 6)
	Efeitos.cinzas_cera(p, 8)
	Efeitos.fumaca(p, 4)
	Efeitos.numero(p, randi_range(1, 9))


func _relatar() -> void:
	var ordenados := _tempos.duplicate()
	ordenados.sort()
	var soma := 0.0
	for t in _tempos:
		soma += t
	var media := soma / _tempos.size()
	var p95 := ordenados[int(ordenados.size() * 0.95)]
	var p99 := ordenados[int(ordenados.size() * 0.99)]
	var vivos := get_tree().get_nodes_in_group(&"inimigos").size()
	print("ESTRESSE: %d quadros | média %.2f ms (%.0f FPS) | p95 %.2f ms | p99 %.2f ms | pior %.2f ms" % [
		_tempos.size(), media, 1000.0 / media, p95, p99, ordenados[-1]])
	print("ESTRESSE: processo médio %.2f ms | física média %.2f ms | nós (máx) %d | desenhos/quadro (máx) %d | inimigos vivos no fim %d" % [
		_media(_processo), _media(_fisica), _maximo_nos, _maximo_desenhos, vivos])


func _media(valores: PackedFloat64Array) -> float:
	var soma := 0.0
	for v in valores:
		soma += v
	return soma / maxf(valores.size(), 1.0)
