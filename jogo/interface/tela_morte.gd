class_name TelaMorte
extends CanvasLayer
## Tela de morte: diz o que derrubou a Coveira, como responder da próxima vez e quanto
## ela avançou. A morte ensina.

var _raiz: Control
var _causa: Label
var _dica: Label
var _estatisticas: Label
var _primeiro: BotaoMenu


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.theme = Tema.obter()
	add_child(_raiz)
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.04, 0.93)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(fundo)
	var coluna := VBoxContainer.new()
	coluna.position = Vector2(40, 56)
	coluna.custom_minimum_size = Vector2(560, 0)
	coluna.add_theme_constant_override("separation", 8)
	_raiz.add_child(coluna)
	var titulo := Tema.rotulo(Textos.t("morte.titulo"), Fontes.titulo(), Fontes.TAMANHO_TITULO * 2, Tema.COR_PERIGO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)
	_causa = Tema.rotulo("")
	_causa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_causa)
	_dica = Tema.rotulo("", null, 0, Tema.COR_DESTAQUE)
	_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.custom_minimum_size = Vector2(560, 0)
	coluna.add_child(_dica)
	_estatisticas = Tema.rotulo("", Fontes.pequena(), Fontes.TAMANHO_PEQUENA, Tema.COR_TEXTO)
	_estatisticas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_estatisticas)
	var botoes := VBoxContainer.new()
	botoes.position = Vector2(260, 250)
	_raiz.add_child(botoes)
	_primeiro = BotaoMenu.new(Textos.t("morte.de_novo"))
	_primeiro.pressed.connect(func() -> void: Jogo.iniciar_descida())
	botoes.add_child(_primeiro)
	var menu := BotaoMenu.new(Textos.t("morte.menu"))
	menu.pressed.connect(func() -> void: Jogo.ir_para_titulo())
	botoes.add_child(menu)


func mostrar(info: DanoInfo) -> void:
	var inimigo := info.fonte_nome if info and info.fonte_nome != "" else Textos.t("morte.desconhecido")
	var ataque := info.ataque_nome if info and info.ataque_nome != "" else "—"
	_causa.text = Textos.t("morte.abatida_por", {"inimigo": inimigo, "ataque": ataque})
	_dica.text = Textos.t("morte.dica", {"dica": info.dica}) if info and info.dica != "" else ""
	_estatisticas.text = Textos.t("morte.estatisticas", {
		"prof": Jogo.profundidade, "salas": Jogo.salas_limpas, "abates": Jogo.abates,
		"ossos": Jogo.ossos, "tempo": Jogo.formatar_tempo(Jogo.tempo)})
	visible = true
	_raiz.modulate.a = 0.0
	create_tween().tween_property(_raiz, ^"modulate:a", 1.0, 0.8)
	_primeiro.grab_focus.call_deferred()
