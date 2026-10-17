class_name Tema
extends RefCounted
## Tema visual da interface, montado em código (fontes bitmap, painel 9-fatias, cores).

const COR_TEXTO := Color("ddd0b6")
const COR_TEXTO_FRACO := Color("8c8189")
const COR_DESTAQUE := Color("f7bb47")
const COR_PERIGO := Color("e8574a")
const COR_SOMBRA := Color(0.04, 0.035, 0.06, 0.9)

static var _tema: Theme


static func obter() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = Fontes.texto()
	t.default_font_size = Fontes.TAMANHO_TEXTO
	for tipo in ["Label", "Button", "CheckBox", "RichTextLabel"]:
		t.set_color("font_color", tipo, COR_TEXTO)
		t.set_color("font_shadow_color", tipo, COR_SOMBRA)
		t.set_constant("shadow_offset_x", tipo, 1)
		t.set_constant("shadow_offset_y", tipo, 1)
	t.set_color("default_color", "RichTextLabel", COR_TEXTO)
	t.set_font("normal_font", "RichTextLabel", Fontes.texto())
	t.set_font_size("normal_font_size", "RichTextLabel", Fontes.TAMANHO_TEXTO)
	# Botões: sem caixa; o foco é mostrado pela cor e pelo marcador (BotaoMenu).
	var vazio := StyleBoxEmpty.new()
	for estilo in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		t.set_stylebox(estilo, "Button", vazio)
		t.set_stylebox(estilo, "CheckBox", vazio)
	t.set_color("font_hover_color", "Button", COR_DESTAQUE)
	t.set_color("font_focus_color", "Button", COR_DESTAQUE)
	t.set_color("font_pressed_color", "Button", Color("fff0b0"))
	t.set_color("font_hover_color", "CheckBox", COR_DESTAQUE)
	t.set_color("font_focus_color", "CheckBox", COR_DESTAQUE)
	t.set_stylebox("panel", "PanelContainer", painel())
	t.set_stylebox("panel", "Panel", painel())
	# Barras deslizantes em estilo de pixel
	var trilho := StyleBoxFlat.new()
	trilho.bg_color = Color("241c2b")
	trilho.content_margin_top = 2
	trilho.content_margin_bottom = 2
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = Color("9c3a14")
	t.set_stylebox("slider", "HSlider", trilho)
	t.set_stylebox("grabber_area", "HSlider", cheio)
	t.set_stylebox("grabber_area_highlight", "HSlider", cheio)
	var pegador := _textura_quadrada(6, Color("f7bb47"))
	t.set_icon("grabber", "HSlider", pegador)
	t.set_icon("grabber_highlight", "HSlider", _textura_quadrada(6, Color("fff0b0")))
	_tema = t
	return t


static func painel() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://arte/interface/painel.png") as Texture2D
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_texture_margin(lado, 6)
		sb.set_content_margin(lado, 8)
	return sb


static func _textura_quadrada(lado: int, cor: Color) -> ImageTexture:
	var img := Image.create_empty(lado, lado, false, Image.FORMAT_RGBA8)
	img.fill(cor)
	return ImageTexture.create_from_image(img)


static func rotulo(texto: String, fonte: Font = null, tamanho: int = 0, cor: Color = COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	if fonte:
		l.add_theme_font_override("font", fonte)
	if tamanho > 0:
		l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l
