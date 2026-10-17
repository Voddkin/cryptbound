extends Node
## Estado da descida atual (a "run") e navegação entre telas.
## O progresso permanente fica em `Salvamento`; aqui só o que morre com a descida.

const CENA_TITULO := "res://jogo/interface/tela_titulo.tscn"
const CENA_DESCIDA := "res://jogo/mundo/descida.tscn"
const VELAS_INICIAIS := 6
const MAX_VELAS := 12

var rng := RandomNumberGenerator.new()
var semente: int = 0
var em_descida := false

var profundidade := 1
var ossos := 0
var velas := VELAS_INICIAIS
var velas_max := VELAS_INICIAIS
var itens: Array[ItemDados] = []
var arma: ArmaDados

var abates := 0
var salas_limpas := 0
var tempo := 0.0
## Golpe que derrubou a Coveira (para a tela de morte).
var causa_morte: DanoInfo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Eventos.inimigo_morreu.connect(func(_i: Node2D, _info: DanoInfo) -> void: abates += 1)
	Eventos.sala_limpa.connect(func(_s: Node) -> void: salas_limpas += 1)


func _process(delta: float) -> void:
	if em_descida and not get_tree().paused:
		tempo += delta


## Reinicia o estado para uma nova descida. `nova_semente` < 0 sorteia uma semente.
func nova_descida(nova_semente: int = -1) -> void:
	semente = nova_semente if nova_semente >= 0 else int(Time.get_unix_time_from_system() * 1000.0) % 2147483647
	rng.seed = semente
	profundidade = 1
	ossos = 0
	velas_max = VELAS_INICIAIS
	velas = VELAS_INICIAIS
	itens.clear()
	arma = load("res://dados/armas/pa_de_coveiro.tres") as ArmaDados
	abates = 0
	salas_limpas = 0
	tempo = 0.0
	causa_morte = null
	em_descida = true
	Eventos.velas_mudaram.emit(velas, velas_max)
	Eventos.ossos_mudaram.emit(ossos)


func adicionar_item(item: ItemDados, jogador: Node2D = null) -> void:
	itens.append(item)
	Salvamento.registrar_reliquia_vista(item.id)
	var ctx := ContextoEfeito.new(jogador, null, null, jogador.global_position if jogador else Vector2.ZERO)
	for efeito in item.efeitos:
		if efeito and efeito.gatilho == &"ao_adquirir":
			efeito.executar(ctx)
	Eventos.item_adquirido.emit(item)


func tem_item(id: StringName) -> bool:
	for item in itens:
		if item.id == id:
			return true
	return false


func perder_velas(quantidade: int) -> void:
	velas = maxi(velas - quantidade, 0)
	Eventos.velas_mudaram.emit(velas, velas_max)


func curar(quantidade: int) -> void:
	velas = mini(velas + quantidade, velas_max)
	Eventos.velas_mudaram.emit(velas, velas_max)


func alterar_velas_max(delta: int) -> void:
	velas_max = clampi(velas_max + delta, 1, MAX_VELAS)
	velas = mini(velas, velas_max)
	Eventos.velas_mudaram.emit(velas, velas_max)


func adicionar_ossos(quantidade: int) -> void:
	ossos += quantidade
	Eventos.ossos_mudaram.emit(ossos)


func descer() -> void:
	profundidade += 1
	Eventos.profundidade_mudou.emit(profundidade)


## Multiplicador de dificuldade da profundidade atual (vida e quantidade de inimigos).
func fator_profundidade() -> float:
	return 1.0 + 0.22 * float(profundidade - 1)


func registrar_morte(info: DanoInfo) -> void:
	causa_morte = info
	em_descida = false
	Salvamento.registrar_descida(profundidade, abates, salas_limpas, tempo, true)


func encerrar_descida_sem_morte() -> void:
	if em_descida:
		em_descida = false
		Salvamento.registrar_descida(profundidade, abates, salas_limpas, tempo, false)


func ir_para_titulo() -> void:
	encerrar_descida_sem_morte()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(CENA_TITULO)


func iniciar_descida() -> void:
	nova_descida()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(CENA_DESCIDA)


static func formatar_tempo(segundos: float) -> String:
	var s := int(segundos)
	return "%d:%02d" % [s / 60, s % 60]
