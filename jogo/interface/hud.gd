class_name Hud
extends CanvasLayer
## Interface durante a descida: velas, ossos, profundidade, relíquias, dica de interação,
## painel do item em foco, mensagens e nome da sala.

var _ossos: Label
var _profundidade: Label
var _reliquias: HBoxContainer
var _dica: Label
var _painel_item: PanelContainer
var _item_nome: Label
var _item_desc: Label
var _item_inscricao: Label
var _mensagem: Label
var _nome_sala: Label
var _tween_msg: Tween
var _tween_sala: Tween
var _dicas_controle: Label


func _ready() -> void:
	layer = 2
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = Tema.obter()
	add_child(raiz)

	# Canto superior esquerdo: velas e ossos
	var topo := VBoxContainer.new()
	topo.position = Vector2(8, 6)
	topo.add_theme_constant_override("separation", 2)
	raiz.add_child(topo)
	topo.add_child(VelasHud.new())
	var linha_ossos := HBoxContainer.new()
	linha_ossos.add_theme_constant_override("separation", 4)
	var icone := TextureRect.new()
	icone.texture = load("res://arte/interface/ossos.png") as Texture2D
	icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	linha_ossos.add_child(icone)
	_ossos = Tema.rotulo("0", Fontes.pequena(), Fontes.TAMANHO_PEQUENA)
	linha_ossos.add_child(_ossos)
	topo.add_child(linha_ossos)

	# Canto superior direito: profundidade e região
	_profundidade = Tema.rotulo("", Fontes.pequena(), Fontes.TAMANHO_PEQUENA, Tema.COR_TEXTO_FRACO)
	_profundidade.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_profundidade.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_profundidade.position = Vector2(640 - 8 - 200, 6)
	_profundidade.size = Vector2(200, 14)
	raiz.add_child(_profundidade)

	# Canto inferior esquerdo: relíquias
	_reliquias = HBoxContainer.new()
	_reliquias.position = Vector2(8, 360 - 24)
	_reliquias.add_theme_constant_override("separation", 3)
	raiz.add_child(_reliquias)

	# Dica de interação (centro-baixo)
	_dica = Tema.rotulo("")
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.position = Vector2(0, 360 - 30)
	_dica.size = Vector2(640, 20)
	raiz.add_child(_dica)

	# Painel do item em foco
	_painel_item = PanelContainer.new()
	_painel_item.visible = false
	_painel_item.custom_minimum_size = Vector2(300, 0)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 2)
	_item_nome = Tema.rotulo("", Fontes.titulo(), Fontes.TAMANHO_TITULO)
	_item_desc = Tema.rotulo("")
	_item_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_desc.custom_minimum_size = Vector2(284, 0)
	_item_inscricao = Tema.rotulo("", Fontes.pequena(), Fontes.TAMANHO_PEQUENA, Tema.COR_TEXTO_FRACO)
	_item_inscricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_inscricao.custom_minimum_size = Vector2(284, 0)
	coluna.add_child(_item_nome)
	coluna.add_child(_item_desc)
	coluna.add_child(_item_inscricao)
	_painel_item.add_child(coluna)
	raiz.add_child(_painel_item)

	# Mensagem central e nome da sala
	_mensagem = Tema.rotulo("", Fontes.titulo(), Fontes.TAMANHO_TITULO)
	_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensagem.position = Vector2(0, 52)
	_mensagem.size = Vector2(640, 24)
	_mensagem.modulate.a = 0.0
	raiz.add_child(_mensagem)
	_nome_sala = Tema.rotulo("", Fontes.titulo(), Fontes.TAMANHO_TITULO, Tema.COR_TEXTO_FRACO)
	_nome_sala.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome_sala.position = Vector2(0, 26)
	_nome_sala.size = Vector2(640, 24)
	_nome_sala.modulate.a = 0.0
	raiz.add_child(_nome_sala)

	# Dicas de controle (primeira sala)
	_dicas_controle = Tema.rotulo("", Fontes.pequena(), Fontes.TAMANHO_PEQUENA, Tema.COR_TEXTO)
	_dicas_controle.position = Vector2(8, 300)
	_dicas_controle.size = Vector2(400, 30)
	_dicas_controle.modulate.a = 0.0
	raiz.add_child(_dicas_controle)

	Eventos.ossos_mudaram.connect(func(total: int) -> void: _ossos.text = str(total))
	Eventos.profundidade_mudou.connect(func(_p: int) -> void: _atualizar_profundidade())
	Eventos.item_adquirido.connect(_ao_adquirir)
	Eventos.dica_interacao.connect(func(t: String) -> void: _dica.text = t)
	Eventos.item_em_foco.connect(_mostrar_item)
	Eventos.mensagem.connect(mostrar_mensagem)
	Eventos.sala_nomeada.connect(_mostrar_nome_sala)
	_ossos.text = str(Jogo.ossos)
	_atualizar_profundidade()
	_atualizar_reliquias()


func _atualizar_profundidade() -> void:
	_profundidade.text = "%s · %s" % [Textos.t("hud.profundidade", {"n": Jogo.profundidade}), Textos.t("hud.regiao.catacumbas")]


func _atualizar_reliquias() -> void:
	for filho in _reliquias.get_children():
		filho.queue_free()
	for item in Jogo.itens:
		var icone := TextureRect.new()
		icone.texture = item.icone
		icone.tooltip_text = item.nome
		_reliquias.add_child(icone)


func _ao_adquirir(item: ItemDados) -> void:
	_atualizar_reliquias()
	_mostrar_item(item)
	get_tree().create_timer(4.0, false).timeout.connect(func() -> void:
		if _item_nome.text == item.nome:
			_mostrar_item(null))


func _mostrar_item(item: ItemDados) -> void:
	if item == null:
		_painel_item.visible = false
		return
	_item_nome.text = item.nome
	_item_nome.add_theme_color_override("font_color", item.cor_raridade())
	_item_desc.text = item.descricao
	_item_inscricao.text = "“%s”" % item.inscricao
	_painel_item.visible = true
	_painel_item.reset_size()
	await get_tree().process_frame
	_painel_item.position = Vector2(roundf((640 - _painel_item.size.x) * 0.5), roundf(360 - 40 - _painel_item.size.y))


func mostrar_mensagem(texto: String, duracao: float = 1.6) -> void:
	_mensagem.text = texto
	if _tween_msg:
		_tween_msg.kill()
	_tween_msg = create_tween()
	_tween_msg.tween_property(_mensagem, ^"modulate:a", 1.0, 0.15)
	_tween_msg.tween_interval(duracao)
	_tween_msg.tween_property(_mensagem, ^"modulate:a", 0.0, 0.5)


func _mostrar_nome_sala(nome: String) -> void:
	_nome_sala.text = nome
	if _tween_sala:
		_tween_sala.kill()
	_tween_sala = create_tween()
	_tween_sala.tween_property(_nome_sala, ^"modulate:a", 1.0, 0.6)
	_tween_sala.tween_interval(2.0)
	_tween_sala.tween_property(_nome_sala, ^"modulate:a", 0.0, 1.0)


func mostrar_dicas_controle() -> void:
	var linhas := [
		Textos.t("dica.mover", {"tecla": Controles.nome_entrada(&"mover")}),
		Textos.t("dica.atacar", {"tecla": Controles.nome_entrada(&"atacar")}),
		Textos.t("dica.pesado", {"tecla": Controles.nome_entrada(&"pesado")}),
		Textos.t("dica.esquivar", {"tecla": Controles.nome_entrada(&"esquivar")}),
	]
	_dicas_controle.text = "\n".join(linhas)
	_dicas_controle.position = Vector2(8, 360 - 34 - 13 * linhas.size())
	var t := create_tween()
	t.tween_property(_dicas_controle, ^"modulate:a", 1.0, 0.8)
	t.tween_interval(14.0)
	t.tween_property(_dicas_controle, ^"modulate:a", 0.0, 1.5)
