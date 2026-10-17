class_name Descida
extends Node2D
## A descida: monta a sequência de salas da profundidade atual, conduz as transições,
## a morte e a passagem para a profundidade seguinte. Dona da câmera, do HUD e dos menus.

const PASTA_SALAS := "res://dados/salas/catacumbas/"
const SALAS_COMBATE := ["pilares", "caixoes", "estreita"]
const PASTA_ITENS := "res://dados/itens/"

var jogador: Jogador
var camera: CameraJogo
var sala: Sala
var ambiente: CanvasModulate
var particulas: SistemaParticulas
var numeros: NumerosDano
var ondas: Node2D
var hud: Hud
var pausa: MenuPausa
var tela_morte: TelaMorte
var sequencia: Array[String] = []
var indice := 0
var transicionando := false
var _cortina: ColorRect
var _dicas_mostradas := false


func _ready() -> void:
	get_tree().root.theme = Tema.obter()
	if not Jogo.em_descida:
		Jogo.nova_descida()
	ambiente = CanvasModulate.new()
	add_child(ambiente)
	particulas = SistemaParticulas.new()
	particulas.z_index = 30
	add_child(particulas)
	ondas = Node2D.new()
	ondas.z_index = 20
	add_child(ondas)
	numeros = NumerosDano.new()
	numeros.z_index = 40
	add_child(numeros)

	jogador = Jogador.new()
	jogador.name = "Coveira"
	if Ambiente.em_demo():
		jogador.entrada = RoboDemo.new()
	add_child(jogador)
	camera = CameraJogo.new()
	jogador.add_child(camera)

	var vinheta := CanvasLayer.new()
	vinheta.layer = 1
	var tex := TextureRect.new()
	tex.texture = load("res://arte/interface/vinheta.png") as Texture2D
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vinheta.add_child(tex)
	add_child(vinheta)
	hud = Hud.new()
	add_child(hud)
	pausa = MenuPausa.new()
	add_child(pausa)
	tela_morte = TelaMorte.new()
	add_child(tela_morte)
	var camada_cortina := CanvasLayer.new()
	camada_cortina.layer = 10
	_cortina = ColorRect.new()
	_cortina.color = Color("0b0910")
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada_cortina.add_child(_cortina)
	add_child(camada_cortina)

	Eventos.jogador_morreu.connect(_ao_morrer)
	Audio.tocar_musica(&"catacumbas")
	gerar_sequencia()
	entrar_sala(0, true)


## Sequência da profundidade atual: chegada, combate, relicário, combate, arena e descida.
func gerar_sequencia() -> void:
	var combates := SALAS_COMBATE.duplicate()
	_embaralhar(combates)
	sequencia = ["entrada" if Jogo.profundidade == 1 else "patamar", combates[0], "relicario", combates[1], "arena", "descida"]


func _embaralhar(lista: Array) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := Jogo.rng.randi_range(0, i)
		var tmp: Variant = lista[i]
		lista[i] = lista[j]
		lista[j] = tmp


func _itens_do_relicario() -> Array[ItemDados]:
	var disponiveis: Array[ItemDados] = []
	for arquivo in ResourceLoader.list_directory(PASTA_ITENS):
		if not arquivo.ends_with(".tres"):
			continue
		var item := load(PASTA_ITENS + arquivo) as ItemDados
		if item and not Jogo.tem_item(item.id):
			disponiveis.append(item)
	disponiveis.sort_custom(func(a: ItemDados, b: ItemDados) -> bool: return a.id < b.id)
	_embaralhar(disponiveis)
	return disponiveis.slice(0, 3)


func entrar_sala(novo_indice: int, inicial: bool = false) -> void:
	transicionando = true
	jogador.parar(true)
	if not inicial:
		await _cobrir(true)
	indice = novo_indice
	jogador.limpar_interacoes()
	if sala:
		jogador.reparent(self, false)
		sala.queue_free()
		sala = null
	var nome := sequencia[indice]
	var itens: Array[ItemDados] = []
	if nome == "relicario":
		itens = _itens_do_relicario()
	sala = ConstrutorSala.carregar(PASTA_SALAS + nome + ".txt", Jogo.rng.randi(), itens)
	if sala == null:
		push_error("Falha ao montar a sala %s" % nome)
		return
	add_child(sala)
	move_child(sala, 1)
	sala.saida_atravessada.connect(_ao_atravessar)
	sala.descida_pedida.connect(_ao_descer)
	Efeitos.registrar(particulas, sala.manchas, numeros, ondas)
	particulas.manchas = sala.manchas
	ambiente.color = sala.definicao.luz
	jogador.reparent(sala.mundo, false)
	jogador.global_position = sala.posicao_chegada()
	jogador.direcao_vista = Vector2.UP
	jogador.reset_physics_interpolation()
	camera.definir_limites(sala.retangulo())
	camera.reset_smoothing()
	sala.iniciar(jogador)
	if nome == "entrada" and not _dicas_mostradas:
		_dicas_mostradas = true
		hud.mostrar_dicas_controle()
	await _cobrir(false)
	jogador.parar(false)
	transicionando = false


func _cobrir(cobrir: bool) -> void:
	var t := create_tween()
	t.tween_property(_cortina, ^"color:a", 1.0 if cobrir else 0.0, 0.22 if cobrir else 0.35)
	await t.finished


func _ao_atravessar() -> void:
	if transicionando or indice + 1 >= sequencia.size():
		return
	entrar_sala(indice + 1)


func _ao_descer() -> void:
	if transicionando:
		return
	transicionando = true
	Audio.tocar(&"descer")
	jogador.parar(true)
	await _cobrir(true)
	Jogo.descer()
	gerar_sequencia()
	hud.mostrar_mensagem(Textos.t("hud.nova_profundidade", {"n": Jogo.profundidade}), 2.2)
	entrar_sala(0, true)


func _ao_morrer(info: DanoInfo) -> void:
	tela_morte.mostrar(info)


func _exit_tree() -> void:
	Efeitos.limpar_registro()
