extends Node2D
## Tela de título: uma cripta viva ao fundo (velas, poeira no ar), o nome do jogo e o menu.

const SALA_FUNDO := "res://dados/salas/catacumbas/titulo.txt"

var _menu: VBoxContainer
var _config: PainelConfig
var _creditos: PanelContainer
var _primeiro: BotaoMenu


func _ready() -> void:
	get_tree().paused = false
	get_tree().root.theme = Tema.obter()
	Efeitos.limpar_registro()
	var fundo := ConstrutorSala.carregar(SALA_FUNDO, 7)
	if fundo:
		add_child(fundo)
		var ambiente := CanvasModulate.new()
		ambiente.color = fundo.definicao.luz
		add_child(ambiente)
		var camera := Camera2D.new()
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		camera.position = fundo.retangulo().get_center() + Vector2(0, 8)
		add_child(camera)
		_poeira(fundo.retangulo())
	Audio.tocar_musica(&"titulo")
	_montar_interface()
	if Ambiente.em_demo():
		Jogo.iniciar_descida.call_deferred()


func _poeira(area: Rect2) -> void:
	var p := CPUParticles2D.new()
	var img := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	p.texture = ImageTexture.create_from_image(img)
	p.amount = 70
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.position = area.get_center()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size * 0.5
	p.direction = Vector2(0.3, -1.0)
	p.spread = 40.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	p.color = Color(0.95, 0.85, 0.65, 0.35)
	p.z_index = 25
	add_child(p)


func _montar_interface() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	var vinheta := TextureRect.new()
	vinheta.texture = load("res://arte/interface/vinheta.png") as Texture2D
	camada.add_child(vinheta)
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.theme = Tema.obter()
	camada.add_child(raiz)

	var logo := Tema.rotulo("CRYPTBOUND", Fontes.titulo(), Fontes.TAMANHO_TITULO * 3, Color("f2e8d0"))
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.position = Vector2(0, 40)
	logo.size = Vector2(640, 70)
	logo.add_theme_color_override("font_shadow_color", Color("5c1520"))
	logo.add_theme_constant_override("shadow_offset_x", 2)
	logo.add_theme_constant_override("shadow_offset_y", 2)
	raiz.add_child(logo)
	var subtitulo := Tema.rotulo(Textos.t("titulo.subtitulo"), null, 0, Tema.COR_TEXTO_FRACO)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.position = Vector2(0, 112)
	subtitulo.size = Vector2(640, 20)
	raiz.add_child(subtitulo)

	# Faixa escura suave atrás do menu (legibilidade sobre o cenário iluminado)
	var fundo_menu := ColorRect.new()
	fundo_menu.color = Color(0.04, 0.035, 0.06, 0.55)
	fundo_menu.position = Vector2(236, 162)
	fundo_menu.size = Vector2(168, 96)
	raiz.add_child(fundo_menu)
	_menu = VBoxContainer.new()
	_menu.position = Vector2(262, 170)
	_menu.add_theme_constant_override("separation", 2)
	raiz.add_child(_menu)
	_primeiro = _botao("titulo.iniciar", func() -> void: Jogo.iniciar_descida())
	_botao("titulo.configuracoes", func() -> void:
		_menu.visible = false
		_config.abrir())
	_botao("titulo.creditos", func() -> void:
		_menu.visible = false
		_creditos.visible = true
		_creditos.get_child(0).get_child(1).grab_focus())
	_botao("titulo.sair", func() -> void: Jogo.sair())

	var rodape := Tema.rotulo(Textos.t("titulo.versao", {"v": ProjectSettings.get_setting("application/config/version")}), Fontes.pequena(), Fontes.TAMANHO_PEQUENA, Tema.COR_TEXTO_FRACO)
	rodape.position = Vector2(8, 360 - 16)
	raiz.add_child(rodape)
	var recorde := int(Salvamento.dados.get("maior_profundidade", 0))
	if recorde > 0:
		var r := Tema.rotulo(Textos.t("titulo.recorde", {"n": recorde}), Fontes.pequena(), Fontes.TAMANHO_PEQUENA, Tema.COR_TEXTO_FRACO)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.position = Vector2(640 - 8 - 300, 360 - 16)
		r.size = Vector2(300, 14)
		raiz.add_child(r)
	var avisos: Array[String] = []
	for aviso in [Salvamento.aviso_pendente, Config.aviso_pendente]:
		if aviso != "":
			avisos.append(aviso)
	if not avisos.is_empty():
		var a := Tema.rotulo("\n".join(avisos), Fontes.pequena(), Fontes.TAMANHO_PEQUENA, Tema.COR_PERIGO)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		a.position = Vector2(0, 140)
		a.size = Vector2(640, 26)
		raiz.add_child(a)
		Salvamento.aviso_pendente = ""
		Config.aviso_pendente = ""

	_config = PainelConfig.new()
	_config.visible = false
	_config.position = Vector2(160, 150)
	_config.fechado.connect(_voltar_ao_menu)
	raiz.add_child(_config)

	_creditos = PanelContainer.new()
	_creditos.visible = false
	_creditos.position = Vector2(110, 140)
	_creditos.custom_minimum_size = Vector2(420, 0)
	var coluna := VBoxContainer.new()
	var texto := Tema.rotulo(Textos.t("creditos.texto"), Fontes.pequena(), Fontes.TAMANHO_PEQUENA)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(400, 0)
	coluna.add_child(texto)
	var voltar := BotaoMenu.new(Textos.t("creditos.voltar"))
	voltar.pressed.connect(func() -> void:
		_creditos.visible = false
		_voltar_ao_menu())
	coluna.add_child(voltar)
	_creditos.add_child(coluna)
	raiz.add_child(_creditos)
	_primeiro.grab_focus.call_deferred()


func _botao(chave: String, acao: Callable) -> BotaoMenu:
	var b := BotaoMenu.new(Textos.t(chave))
	b.pressed.connect(acao)
	_menu.add_child(b)
	return b


func _voltar_ao_menu() -> void:
	_menu.visible = true
	_primeiro.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
	if _creditos.visible and (evento.is_action_pressed(&"pausar") or evento.is_action_pressed(&"ui_cancel")):
		_creditos.visible = false
		Audio.tocar(&"ui_voltar")
		_voltar_ao_menu()
