extends Node
## Roteiro de captura das telas principais para revisão visual (não é um teste automático).
## Rode com renderização (não headless), por exemplo sob Xvfb:
##   godot --path . --rendering-driver opengl3 --fixed-fps 60 res://testes/captura/capturar_telas.tscn -- <pasta>
## Salva PNGs na resolução interna (640×360).

var _pasta := "res://../capturas/telas"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_pasta = args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://").path_join("capturas/telas")
	DirAccess.make_dir_recursive_absolute(_pasta)
	_roteiro.call_deferred()


func _quadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_pasta.path_join(nome + ".png"))
	print("captura: ", nome, " ", img.get_size())


func _roteiro() -> void:
	# 1. Título
	var titulo: Node = load("res://jogo/interface/tela_titulo.tscn").instantiate()
	add_child(titulo)
	await _quadros(90)
	await _foto("01_titulo")
	for botao in titulo._menu.get_children():
		if botao is BotaoMenu and (botao as BotaoMenu).text == Textos.t("titulo.creditos"):
			(botao as BotaoMenu).pressed.emit()
	await _quadros(5)
	await _foto("01b_creditos")
	titulo.queue_free()
	await _quadros(2)

	# 2. Primeira sala com as dicas de controle
	Jogo.nova_descida(77)
	var descida: Descida = load("res://jogo/mundo/descida.tscn").instantiate()
	add_child(descida)
	await _quadros(120)
	await _foto("02_antecamara")

	# 3. Painel de relíquia em foco + HUD com relíquias
	for id in ["presa_cao_de_cova", "sino_rachado"]:
		Jogo.adicionar_item(load("res://dados/itens/%s.tres" % id) as ItemDados, descida.jogador)
	Eventos.item_em_foco.emit(load("res://dados/itens/vela_perene.tres") as ItemDados)
	Eventos.dica_interacao.emit(Textos.t("hud.interagir", {"tecla": "E", "acao": Textos.t("hud.pegar", {"nome": "Vela Perene"})}))
	await _quadros(20)
	await _foto("03_painel_item")
	Eventos.item_em_foco.emit(null)
	Eventos.dica_interacao.emit("")

	# 4. Pausa com a lista de relíquias
	descida.pausa.abrir()
	await _quadros(10)
	await _foto("04_pausa")
	descida.pausa._abrir_config()
	await _quadros(10)
	await _foto("05_configuracoes")
	descida.pausa.fechar()
	await _quadros(5)

	# 5. Combate: Ressequido preparando e Lamuriante cantando ao lado da Coveira
	var sala := descida.sala
	var base := descida.jogador.global_position
	var erguidos: Array[Inimigo] = []
	for d in [[&"ressequido", Vector2(40, -10)], [&"lamuriante", Vector2(-60, -30)], [&"ressequido", Vector2(-30, 30)]]:
		var i := FabricaInimigos.criar(d[0])
		i.sala = sala
		i.position = base + d[1]
		sala.mundo.add_child(i)
		i.pular_surgimento()
		erguidos.append(i)
	await _quadros(40)
	erguidos[0].estados.aplicar(EstadoSangria.new())
	erguidos[2].estados.aplicar(EstadoAtordoado.new())
	await _quadros(10)
	await _foto("06_combate")

	# 6. Relicário sem relíquias novas (as três já foram levadas): oferendas e aviso
	Jogo.adicionar_item(load("res://dados/itens/vela_perene.tres") as ItemDados, descida.jogador)
	descida.entrar_sala(descida.sequencia.find("relicario"))
	await _quadros(50)
	await _foto("06b_relicario_vazio")

	# 7. Morte e tela de morte
	Jogo.perder_velas(Jogo.velas - 1)
	var golpe := DanoInfo.new()
	golpe.valor = 1.0
	golpe.velas = 1
	golpe.fonte_nome = "Ressequido"
	golpe.ataque_nome = "Investida"
	golpe.dica = (load("res://dados/inimigos/ressequido.tres") as InimigoDados).dica
	golpe.direcao = Vector2.LEFT
	descida.jogador.receber_dano(golpe)
	await _quadros(40)
	await _foto("07_tombando")
	await _quadros(200)
	await _foto("08_tela_morte")
	get_tree().quit()
