extends Node
## Teste de fumaça (fora da suíte, demora minutos): o robô de demonstração joga descidas com
## várias sementes, sem renderização e em quadros fixos, e o roteiro aponta onde ele TRAVOU
## (60 s de jogo sem progresso), morreu ou chegou à profundidade-alvo.
## Uso:
##   godot --headless --fixed-fps 60 --path . res://testes/fumaca/robo_fumaca.tscn -- --demo \
##     --sementes=1,2,3,4,5 --prof=3
## Sai com código 1 se alguma descida travou.

const QUADROS_SEM_PROGRESSO := 60 * 60
const QUADROS_MAXIMOS := 60 * 60 * 10

var _sementes: Array[int] = [1, 2, 3, 4, 5]
var _prof_alvo := 3
var _descida: Descida
var _semente := 0
var _marca := ""
var _parado := 0
var _quadros := 0
var _resultados: Array[String] = []
var _travou := false
var _trocando := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sementes="):
			_sementes.clear()
			for s in arg.get_slice("=", 1).split(",", false):
				_sementes.append(int(s))
		elif arg.begins_with("--prof="):
			_prof_alvo = int(arg.get_slice("=", 1))
	_proxima.call_deferred()


func _proxima() -> void:
	_trocando = true
	if _descida:
		_descida.queue_free()
		_descida = null
		await get_tree().process_frame
	if _sementes.is_empty():
		print("\n".join(_resultados))
		print("FUMAÇA: %d descidas, %s" % [_resultados.size(), "ALGUMA TRAVOU" if _travou else "nenhuma travou"])
		get_tree().quit(1 if _travou else 0)
		return
	_semente = _sementes.pop_front()
	get_tree().paused = false
	Jogo.nova_descida(_semente)
	_descida = load("res://jogo/mundo/descida.tscn").instantiate()
	add_child(_descida)
	_marca = ""
	_parado = 0
	_quadros = 0
	_trocando = false


func _physics_process(_delta: float) -> void:
	if _trocando or _descida == null or _descida.sala == null:
		return
	_quadros += 1
	var sala := _descida.sala
	var vivos := get_tree().get_nodes_in_group(&"inimigos").filter(func(n: Node) -> bool: return n is Inimigo and (n as Inimigo).esta_vivo()).size()
	# Progresso: mudar de profundidade, de sala, de estado da sala ou abater alguém.
	var marca := "%d|%d|%d|%d" % [Jogo.profundidade, _descida.indice, sala.estado, Jogo.abates]
	if marca != _marca:
		_marca = marca
		_parado = 0
	else:
		_parado += 1
	var onde := "prof %d, sala %s (%s), %d inimigos vivos, %d abates, %s" % [
		Jogo.profundidade, _descida.sequencia[_descida.indice], Sala.Situacao.keys()[sala.estado],
		vivos, Jogo.abates, Jogo.formatar_tempo(_quadros / 60.0)]
	if not Jogo.em_descida:
		_registrar("morreu    semente %d: %s" % [_semente, onde])
	elif Jogo.profundidade >= _prof_alvo:
		_registrar("chegou    semente %d: %s" % [_semente, onde])
	elif _parado > QUADROS_SEM_PROGRESSO:
		var pos := _descida.jogador.global_position
		var restos: Array[String] = []
		for c in get_tree().get_nodes_in_group(&"coletaveis"):
			var celula := sala.celula_de((c as Node2D).global_position)
			restos.append("%s em %s%s" % [Coletavel.Tipo.keys()[(c as Coletavel).tipo], celula, "" if sala.andavel(celula) else " (não andável)"])
		_registrar("TRAVOU    semente %d: %s; Coveira em %s (célula %s); coletáveis: %s" % [_semente, onde, pos.round(), sala.celula_de(pos), ", ".join(restos) if not restos.is_empty() else "nenhum"])
		_travou = true
	elif _quadros > QUADROS_MAXIMOS:
		_registrar("esgotou   semente %d: %s" % [_semente, onde])


func _registrar(linha: String) -> void:
	print(linha)
	_resultados.append(linha)
	_proxima.call_deferred()
	_trocando = true
