class_name MenuPausa
extends CanvasLayer
## Pausa: continuar, recomeçar, configurações, menu principal, sair — e a lista das
## relíquias carregadas com suas descrições (para entender as combinações).

var _fundo: ColorRect
var _menu: VBoxContainer
var _reliquias: VBoxContainer
var _config: PainelConfig
var _primeiro: BotaoMenu


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.theme = Tema.obter()
	add_child(raiz)
	_fundo = ColorRect.new()
	_fundo.color = Color(0.04, 0.035, 0.06, 0.82)
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(_fundo)
	var titulo := Tema.rotulo(Textos.t("pausa.titulo"), Fontes.titulo(), Fontes.TAMANHO_TITULO * 2, Tema.COR_DESTAQUE)
	titulo.position = Vector2(48, 36)
	raiz.add_child(titulo)
	_menu = VBoxContainer.new()
	_menu.position = Vector2(60, 100)
	_menu.add_theme_constant_override("separation", 2)
	raiz.add_child(_menu)
	_primeiro = _botao("pausa.continuar", fechar)
	_botao("pausa.recomecar", func() -> void:
		fechar()
		Jogo.encerrar_descida_sem_morte()
		Jogo.iniciar_descida())
	_botao("pausa.configuracoes", _abrir_config)
	_botao("pausa.menu", func() -> void:
		get_tree().paused = false
		Jogo.ir_para_titulo())
	_botao("pausa.sair", func() -> void: get_tree().quit())
	var painel := PanelContainer.new()
	painel.position = Vector2(300, 60)
	painel.custom_minimum_size = Vector2(310, 0)
	raiz.add_child(painel)
	_reliquias = VBoxContainer.new()
	_reliquias.add_theme_constant_override("separation", 4)
	painel.add_child(_reliquias)
	_config = PainelConfig.new()
	_config.visible = false
	_config.position = Vector2(160, 70)
	_config.fechado.connect(func() -> void:
		_menu.visible = true
		_primeiro.grab_focus())
	raiz.add_child(_config)


func _botao(chave: String, acao: Callable) -> BotaoMenu:
	var b := BotaoMenu.new(Textos.t(chave))
	b.pressed.connect(acao)
	_menu.add_child(b)
	return b


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed(&"pausar"):
		return
	if visible and not _config.visible:
		get_viewport().set_input_as_handled()
		fechar()
	elif not visible and _pode_abrir():
		get_viewport().set_input_as_handled()
		abrir()


func _pode_abrir() -> bool:
	var jogador := get_tree().get_first_node_in_group(&"jogador")
	return jogador != null and jogador.esta_vivo()


func abrir() -> void:
	_preencher_reliquias()
	visible = true
	_menu.visible = true
	get_tree().paused = true
	_primeiro.grab_focus.call_deferred()


func fechar() -> void:
	visible = false
	_config.visible = false
	get_tree().paused = false


func _abrir_config() -> void:
	_menu.visible = false
	_config.abrir()


func _preencher_reliquias() -> void:
	for filho in _reliquias.get_children():
		filho.queue_free()
	_reliquias.add_child(Tema.rotulo(Textos.t("pausa.reliquias"), Fontes.titulo(), Fontes.TAMANHO_TITULO, Tema.COR_DESTAQUE))
	if Jogo.itens.is_empty():
		_reliquias.add_child(Tema.rotulo(Textos.t("pausa.sem_reliquias"), null, 0, Tema.COR_TEXTO_FRACO))
		return
	for item in Jogo.itens:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 6)
		var icone := TextureRect.new()
		icone.texture = item.icone
		icone.stretch_mode = TextureRect.STRETCH_KEEP
		linha.add_child(icone)
		var textos := VBoxContainer.new()
		textos.add_child(Tema.rotulo(item.nome, null, 0, item.cor_raridade()))
		var desc := Tema.rotulo(item.descricao, Fontes.pequena(), Fontes.TAMANHO_PEQUENA)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(260, 0)
		textos.add_child(desc)
		linha.add_child(textos)
		_reliquias.add_child(linha)
