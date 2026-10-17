extends Node
## Opções do jogador (áudio, vídeo, jogo), salvas em user://config.cfg.
## Valores inválidos ou arquivo corrompido são substituídos pelos padrões.

signal mudou(secao: StringName, chave: StringName, valor: Variant)

const CAMINHO := "user://config.cfg"

const PADROES := {
	&"audio": {&"geral": 0.8, &"musica": 0.7, &"efeitos": 0.9},
	&"video": {&"tela_cheia": false, &"vsync": true},
	&"jogo": {&"tremor": 1.0, &"numeros_dano": true},
}

var _valores: Dictionary = {}
## Preenchido quando o arquivo precisou ser restaurado; a interface pode exibir o aviso.
var aviso_pendente := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	carregar()
	aplicar_tudo()


func carregar(caminho: String = CAMINHO) -> void:
	_valores = PADROES.duplicate(true)
	if not FileAccess.file_exists(caminho):
		return
	var arquivo := ConfigFile.new()
	if arquivo.load(caminho) != OK:
		aviso_pendente = Textos.t("erro.configuracao")
		salvar(caminho)
		return
	var invalido := false
	for secao: StringName in PADROES:
		for chave: StringName in PADROES[secao]:
			var padrao: Variant = PADROES[secao][chave]
			var valor: Variant = arquivo.get_value(secao, chave, padrao)
			if typeof(valor) == TYPE_INT and typeof(padrao) == TYPE_FLOAT:
				valor = float(valor)
			if typeof(valor) != typeof(padrao):
				invalido = true
				valor = padrao
			if typeof(valor) == TYPE_FLOAT:
				valor = clampf(valor, 0.0, 1.0)
			_valores[secao][chave] = valor
	if invalido:
		aviso_pendente = Textos.t("erro.configuracao")
		salvar(caminho)


func salvar(caminho: String = CAMINHO) -> void:
	var arquivo := ConfigFile.new()
	for secao: StringName in _valores:
		for chave: StringName in _valores[secao]:
			arquivo.set_value(secao, chave, _valores[secao][chave])
	var erro := arquivo.save(caminho)
	if erro != OK:
		push_warning("Não foi possível salvar as configurações (%s)." % error_string(erro))


func obter(secao: StringName, chave: StringName) -> Variant:
	return _valores.get(secao, {}).get(chave, PADROES.get(secao, {}).get(chave))


func definir(secao: StringName, chave: StringName, valor: Variant) -> void:
	if not _valores.has(secao):
		return
	_valores[secao][chave] = valor
	_aplicar(secao, chave)
	salvar()
	mudou.emit(secao, chave, valor)


func aplicar_tudo() -> void:
	for secao: StringName in _valores:
		for chave: StringName in _valores[secao]:
			_aplicar(secao, chave)


func _aplicar(secao: StringName, chave: StringName) -> void:
	var valor: Variant = obter(secao, chave)
	match [secao, chave]:
		[&"audio", &"geral"]:
			_volume_barramento(&"Master", valor)
		[&"audio", &"musica"]:
			_volume_barramento(&"Musica", valor)
		[&"audio", &"efeitos"]:
			_volume_barramento(&"Efeitos", valor)
		[&"video", &"tela_cheia"]:
			if DisplayServer.get_name() == "headless":
				return
			var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if valor else DisplayServer.WINDOW_MODE_WINDOWED
			if DisplayServer.window_get_mode() != modo:
				DisplayServer.window_set_mode(modo)
		[&"video", &"vsync"]:
			if DisplayServer.get_name() == "headless":
				return
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if valor else DisplayServer.VSYNC_DISABLED)


func _volume_barramento(nome: StringName, linear: float) -> void:
	var indice := AudioServer.get_bus_index(nome)
	if indice < 0:
		return
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(indice, linear <= 0.001)
