extends Node
## "Suco" do combate: hitstop, tremor de tela, recuo de câmera, partículas, manchas
## e números de dano. A cena da descida registra os nós de desenho com `registrar`.

const TRAUMA_DECAIMENTO := 2.2

var trauma := 0.0
## Deslocamento rápido da câmera na direção do impacto (decai sozinho).
var chute := Vector2.ZERO
## Escala de tempo fora do hitstop (câmera lenta da morte etc.).
var escala_base := 1.0

## Hitstop restante, em segundos de tempo NÃO escalado (determinístico com --fixed-fps).
var _hitstop_restante := 0.0
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
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	# `delta` vem escalado por Engine.time_scale; desfazendo a escala obtemos o tempo do
	# jogo "sem câmera lenta". Com --fixed-fps (vídeos e testes) isso é determinístico.
	var escala := Engine.time_scale
	var real := minf(delta / escala if escala > 0.0001 else delta, 0.1)
	trauma = maxf(trauma - TRAUMA_DECAIMENTO * real, 0.0)
	chute = chute.lerp(Vector2.ZERO, minf(1.0, 18.0 * real))
	if _hitstop_restante > 0.0:
		_hitstop_restante -= real
		if _hitstop_restante <= 0.0:
			_hitstop_restante = 0.0
			Engine.time_scale = escala_base
	elif not is_equal_approx(Engine.time_scale, escala_base):
		Engine.time_scale = escala_base


## Congela a ação por um instante para dar peso ao impacto.
## Timers de jogo também desaceleram durante o hitstop (intencional: o mundo para).
func hitstop(duracao: float) -> void:
	if duracao <= 0.0:
		return
	_hitstop_restante = maxf(_hitstop_restante, duracao)
	Engine.time_scale = 0.03


func em_hitstop() -> bool:
	return _hitstop_restante > 0.0


func definir_escala_base(escala: float) -> void:
	escala_base = escala
	if _hitstop_restante <= 0.0:
		Engine.time_scale = escala


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
