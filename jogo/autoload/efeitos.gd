extends Node
## "Suco" do combate: hitstop, tremor de tela, recuo de câmera, partículas, manchas
## e números de dano. A cena da descida registra os nós de desenho com `registrar`.

const TRAUMA_DECAIMENTO := 2.2
const ESCALA_HITSTOP := 0.03

var trauma := 0.0
## Deslocamento rápido da câmera na direção do impacto (decai sozinho).
var chute := Vector2.ZERO
## Escala de tempo fora do hitstop (câmera lenta da morte etc.).
var escala_base := 1.0

## Hitstop restante, em segundos de tempo NÃO escalado (determinístico com --fixed-fps).
var _hitstop_restante := 0.0
## Hitstop pedido desde o último `_process` (aplicado lá, nunca no meio do quadro).
var _hitstop_pedido := 0.0
## Escala que este nó gravou por último em Engine.time_scale. Só Efeitos grava a escala, e
## só dentro de `_process`: o motor lê a escala no início de cada iteração, então o `delta`
## de um quadro foi escalado exatamente por este valor. (Medir com a escala atual erra no
## quadro em que um golpe muda a escala durante a física — e cancelava todo hitstop.)
var _escala_aplicada := 1.0
var _particulas: SistemaParticulas
var _manchas: ManchasChao
var _numeros: NumerosDano
var _ondas: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func registrar(particulas: SistemaParticulas, manchas: ManchasChao, numeros: NumerosDano, ondas: Node2D) -> void:
	_particulas = particulas
	_manchas = manchas
	_numeros = numeros
	_ondas = ondas


func limpar_registro() -> void:
	_particulas = null
	_manchas = null
	_numeros = null
	_ondas = null
	trauma = 0.0
	chute = Vector2.ZERO
	escala_base = 1.0
	_hitstop_restante = 0.0
	_hitstop_pedido = 0.0
	_escala_aplicada = 1.0
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	# `delta` vem escalado pela escala aplicada no quadro anterior; desfazendo-a obtemos o
	# tempo "sem câmera lenta". Com --fixed-fps (vídeos e testes) isso é determinístico.
	var real := minf(delta / _escala_aplicada, 0.1)
	trauma = maxf(trauma - TRAUMA_DECAIMENTO * real, 0.0)
	chute = chute.lerp(Vector2.ZERO, minf(1.0, 18.0 * real))
	_hitstop_restante = maxf(_hitstop_restante - real, 0.0)
	if _hitstop_pedido > 0.0:
		_hitstop_restante = maxf(_hitstop_restante, _hitstop_pedido)
		_hitstop_pedido = 0.0
	var alvo := ESCALA_HITSTOP if _hitstop_restante > 0.0 else escala_base
	if not is_equal_approx(_escala_aplicada, alvo) or not is_equal_approx(Engine.time_scale, alvo):
		_escala_aplicada = alvo
		Engine.time_scale = alvo


## Congela a ação por um instante para dar peso ao impacto.
## Timers de jogo também desaceleram durante o hitstop (intencional: o mundo para).
func hitstop(duracao: float) -> void:
	if duracao <= 0.0:
		return
	_hitstop_pedido = maxf(_hitstop_pedido, duracao)


func em_hitstop() -> bool:
	return _hitstop_restante > 0.0 or _hitstop_pedido > 0.0


## Escala fora do hitstop (câmera lenta da morte etc.); vale a partir do próximo quadro.
func definir_escala_base(escala: float) -> void:
	escala_base = maxf(escala, 0.01)


func tremer(quantidade: float, direcao: Vector2 = Vector2.ZERO) -> void:
	var multiplicador: float = Config.obter(&"jogo", &"tremor")
	trauma = minf(trauma + quantidade * multiplicador, 1.0)
	if direcao != Vector2.ZERO:
		chute += direcao.normalized() * 3.0 * multiplicador


# --- Partículas e decalques ---------------------------------------------------

func impacto(posicao: Vector2, direcao: Vector2, material: StringName = &"osso") -> void:
	if _particulas == null:
		return
	_particulas.faiscas(posicao, direcao, 5)
	match material:
		&"osso":
			_particulas.estilhacos(posicao, direcao, 4, [Color("e8dcc0"), Color("b5a996"), Color("8f8379")], false)
		&"cera":
			_particulas.estilhacos(posicao, direcao, 5, [Color("f0e6cf"), Color("c9b896"), Color("6a3a8a")], true)
		&"carne":
			sangue(posicao, direcao, 6)


func sangue(posicao: Vector2, direcao: Vector2, quantidade: int) -> void:
	if _particulas == null:
		return
	_particulas.estilhacos(posicao, direcao, quantidade, [Color("a32b2b"), Color("6e1a22"), Color("3d0f16")], true)


func poeira(posicao: Vector2, quantidade: int = 3, direcao: Vector2 = Vector2.ZERO) -> void:
	if _particulas:
		_particulas.poeira(posicao, quantidade, direcao)


func estilhacos_terra(posicao: Vector2, quantidade: int = 7) -> void:
	if _particulas:
		_particulas.estilhacos(posicao, Vector2.UP, quantidade, [Color("46302a"), Color("6e4c3c"), Color("2a1b16")], false)


func cinzas_cera(posicao: Vector2, quantidade: int) -> void:
	if _particulas:
		_particulas.estilhacos(posicao, Vector2.UP, quantidade, [Color("f0e6cf"), Color("d8cfb8"), Color("a66cd0")], true)


func fumaca(posicao: Vector2, quantidade: int = 4) -> void:
	if _particulas:
		_particulas.fumaca(posicao, quantidade)


func mancha(posicao: Vector2, cor: Color, raio: int = 1) -> void:
	if _manchas:
		_manchas.manchar(posicao, cor, raio)


func numero(posicao: Vector2, valor: float, cor: Color = Color("f0e8d2"), critico: bool = false) -> void:
	if _numeros == null or not bool(Config.obter(&"jogo", &"numeros_dano")):
		return
	_numeros.adicionar(posicao, valor, cor, critico)


func onda(posicao: Vector2, raio: float, estilo: StringName = &"badalo") -> void:
	if _ondas == null:
		return
	var anel := AnelOnda.new()
	anel.raio_final = raio
	anel.estilo = estilo
	anel.position = posicao
	_ondas.add_child(anel)
