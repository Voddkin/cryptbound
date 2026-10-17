extends Node
## Registra o mapa de entradas padrão e acompanha qual dispositivo o jogador está usando.
## As ações são criadas em código para existir uma única fonte de verdade
## (e permitir remapeamento persistente no futuro).

signal dispositivo_mudou(usando_controle: bool)

const ZONA_MORTA := 0.25
const TEMPO_MOUSE_ATIVO := 4.0

var usando_controle := false
## Momento (em segundos) do último uso do mouse para mirar.
var _ultimo_uso_mouse := -100.0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_registrar_acoes()


func _registrar_acoes() -> void:
	_acao(&"mover_cima", [_tecla(KEY_W), _tecla(KEY_UP), _botao_controle(JOY_BUTTON_DPAD_UP), _eixo(JOY_AXIS_LEFT_Y, -1.0)])
	_acao(&"mover_baixo", [_tecla(KEY_S), _tecla(KEY_DOWN), _botao_controle(JOY_BUTTON_DPAD_DOWN), _eixo(JOY_AXIS_LEFT_Y, 1.0)])
	_acao(&"mover_esquerda", [_tecla(KEY_A), _tecla(KEY_LEFT), _botao_controle(JOY_BUTTON_DPAD_LEFT), _eixo(JOY_AXIS_LEFT_X, -1.0)])
	_acao(&"mover_direita", [_tecla(KEY_D), _tecla(KEY_RIGHT), _botao_controle(JOY_BUTTON_DPAD_RIGHT), _eixo(JOY_AXIS_LEFT_X, 1.0)])
	_acao(&"atacar", [_mouse(MOUSE_BUTTON_LEFT), _tecla(KEY_J), _botao_controle(JOY_BUTTON_X), _eixo(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_acao(&"pesado", [_mouse(MOUSE_BUTTON_RIGHT), _tecla(KEY_K), _botao_controle(JOY_BUTTON_Y), _eixo(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_acao(&"esquivar", [_tecla(KEY_SPACE), _tecla(KEY_SHIFT), _tecla(KEY_L), _botao_controle(JOY_BUTTON_A), _botao_controle(JOY_BUTTON_RIGHT_SHOULDER)])
	_acao(&"interagir", [_tecla(KEY_E), _tecla(KEY_F), _botao_controle(JOY_BUTTON_B)])
	_acao(&"pausar", [_tecla(KEY_ESCAPE), _tecla(KEY_P), _botao_controle(JOY_BUTTON_START)])
	_acao(&"tela_cheia", [_tecla(KEY_F11)])


func _acao(nome: StringName, eventos: Array[InputEvent]) -> void:
	if InputMap.has_action(nome):
		InputMap.action_erase_events(nome)
	else:
		InputMap.add_action(nome, ZONA_MORTA)
	for evento in eventos:
		InputMap.action_add_event(nome, evento)


func _tecla(codigo: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = codigo
	return e


func _mouse(botao: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = botao
	return e


func _botao_controle(botao: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = botao
	e.device = -1
	return e


func _eixo(eixo: JoyAxis, valor: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = eixo
	e.axis_value = valor
	e.device = -1
	return e


func _input(evento: InputEvent) -> void:
	var controle := usando_controle
	if evento is InputEventJoypadButton:
		controle = true
	elif evento is InputEventJoypadMotion:
		if absf((evento as InputEventJoypadMotion).axis_value) > 0.4:
			controle = true
	elif evento is InputEventMouseMotion:
		if (evento as InputEventMouseMotion).relative.length() > 2.0:
			controle = false
			_ultimo_uso_mouse = _agora()
	elif evento is InputEventMouseButton:
		controle = false
		_ultimo_uso_mouse = _agora()
	elif evento is InputEventKey:
		controle = false
	if controle != usando_controle:
		usando_controle = controle
		dispositivo_mudou.emit(usando_controle)
	if evento.is_action_pressed(&"tela_cheia"):
		Config.definir(&"video", &"tela_cheia", not bool(Config.obter(&"video", &"tela_cheia")))


func _agora() -> float:
	return Time.get_ticks_msec() / 1000.0


## Verdadeiro se o mouse foi usado recentemente para mirar (teclado + mouse).
func mouse_ativo() -> bool:
	return not usando_controle and _agora() - _ultimo_uso_mouse < TEMPO_MOUSE_ATIVO


## Direção do analógico direito, ou Vector2.ZERO se estiver em repouso.
func mira_analogica() -> Vector2:
	var controles := Input.get_connected_joypads()
	if controles.is_empty():
		return Vector2.ZERO
	var id: int = controles[0]
	var v := Vector2(Input.get_joy_axis(id, JOY_AXIS_RIGHT_X), Input.get_joy_axis(id, JOY_AXIS_RIGHT_Y))
	return v if v.length() > 0.3 else Vector2.ZERO


## Nome legível da tecla/botão de uma ação para o dispositivo atual.
func nome_entrada(acao: StringName) -> String:
	if usando_controle:
		match acao:
			&"atacar": return "X"
			&"pesado": return "Y"
			&"esquivar": return "A"
			&"interagir": return "B"
			&"pausar": return "Start"
			&"mover": return Textos.t("tecla.mover_controle")
	else:
		match acao:
			&"atacar": return Textos.t("tecla.mouse_esquerdo")
			&"pesado": return Textos.t("tecla.mouse_direito")
			&"esquivar": return Textos.t("tecla.espaco")
			&"interagir": return "E"
			&"pausar": return "Esc"
			&"mover": return Textos.t("tecla.mover_teclado")
	return String(acao)
