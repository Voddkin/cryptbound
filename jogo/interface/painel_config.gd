class_name PainelConfig
extends PanelContainer
## Configurações: volumes, tela cheia, sincronia vertical, intensidade do tremor e números
## de dano. Tudo é aplicado e salvo na hora (Config).

signal fechado

var _primeiro: Control
## Refazem o texto das opções liga/desliga (a tela cheia também muda pelo F11).
var _atualizadores: Array[Callable] = []


func _ready() -> void:
	custom_minimum_size = Vector2(320, 0)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	add_child(coluna)
	var titulo := Tema.rotulo(Textos.t("config.titulo"), Fontes.titulo(), Fontes.TAMANHO_TITULO, Tema.COR_DESTAQUE)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)
	_primeiro = _barra(coluna, "config.volume_geral", &"audio", &"geral")
	_barra(coluna, "config.volume_musica", &"audio", &"musica")
	_barra(coluna, "config.volume_efeitos", &"audio", &"efeitos")
	_barra(coluna, "config.tremor", &"jogo", &"tremor")
	_caixa(coluna, "config.tela_cheia", &"video", &"tela_cheia")
	_caixa(coluna, "config.vsync", &"video", &"vsync")
	_caixa(coluna, "config.numeros_dano", &"jogo", &"numeros_dano")
	var voltar := BotaoMenu.new(Textos.t("config.voltar"))
	voltar.pressed.connect(fechar)
	coluna.add_child(voltar)
	Config.mudou.connect(_ao_mudar_config)


func _ao_mudar_config(_secao: StringName, _chave: StringName, _valor: Variant) -> void:
	for atualizar in _atualizadores:
		atualizar.call()


func abrir() -> void:
	visible = true
	_primeiro.grab_focus.call_deferred()


func fechar() -> void:
	visible = false
	fechado.emit()


func _unhandled_input(evento: InputEvent) -> void:
	if visible and (evento.is_action_pressed(&"pausar") or evento.is_action_pressed(&"ui_cancel")):
		get_viewport().set_input_as_handled()
		Audio.tocar(&"ui_voltar")
		fechar()


func _barra(pai: Control, chave_texto: String, secao: StringName, chave: StringName) -> HSlider:
	var linha := HBoxContainer.new()
	var rotulo := Tema.rotulo(Textos.t(chave_texto))
	rotulo.custom_minimum_size = Vector2(150, 0)
	linha.add_child(rotulo)
	var barra := HSlider.new()
	barra.min_value = 0.0
	barra.max_value = 1.0
	barra.step = 0.05
	barra.value = float(Config.obter(secao, chave))
	barra.custom_minimum_size = Vector2(140, 14)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.value_changed.connect(func(v: float) -> void:
		Config.definir(secao, chave, v)
		if secao == &"audio":
			Audio.tocar(&"ui_mover"))
	linha.add_child(barra)
	pai.add_child(linha)
	return barra


func _caixa(pai: Control, chave_texto: String, secao: StringName, chave: StringName) -> void:
	var botao := BotaoMenu.new()
	var atualizar := func() -> void:
		var ligado := bool(Config.obter(secao, chave))
		botao.text = "%s: %s" % [Textos.t(chave_texto), Textos.t("config.ligado" if ligado else "config.desligado")]
	atualizar.call()
	_atualizadores.append(atualizar)
	botao.pressed.connect(func() -> void: Config.definir(secao, chave, not bool(Config.obter(secao, chave))))
	pai.add_child(botao)
