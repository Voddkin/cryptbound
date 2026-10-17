class_name Ressequido
extends Inimigo
## Cadáver seco movido por raízes. Avança devagar e dá uma investida telegrafada
## (tremor + olho brilhando por 0,55 s). Durante a preparação e a investida, só golpes
## FORTES (pancada do combo, golpe pesado, badalo) o interrompem; depois da investida fica
## exposto por um bom tempo. Perto de uma Lamuriante, fica mais rápido.

enum Acao { PERSEGUIR, PREPARAR, INVESTIR, RECUPERAR }

const ALCANCE := 46.0
const PREPARO := 0.55
const TRAVA_MIRA := 0.15
const DURACAO_INVESTIDA := 0.24
const VELOCIDADE_INVESTIDA := 215.0
const RECUPERACAO := 0.75

var acao: Acao = Acao.PERSEGUIR
var _tempo := 0.0
var _recarga := 0.6
var _direcao_ataque := Vector2.RIGHT
var _fortalecido := 0.0
var _olho: PointLight2D
var _forma_golpe: CircleShape2D


func _caminho_sprite() -> String:
	return "res://arte/personagens/ressequido.json"


func _caminho_dados() -> String:
	return "res://dados/inimigos/ressequido.tres"


func _configurar() -> void:
	var caixa := RectangleShape2D.new()
	caixa.size = Vector2(12, 16)
	adicionar_forma_dano(caixa, Vector2(0, -9))
	_forma_golpe = CircleShape2D.new()
	_forma_golpe.radius = 9.0
	criar_caixa_golpe(_forma_golpe)
	_olho = PointLight2D.new()
	_olho.texture = preload("res://arte/luzes/luz_pequena.png")
	_olho.color = Color("4fc4b0")
	_olho.energy = 0.35
	_olho.texture_scale = 0.4
	_olho.position = BibliotecaSprites.ponto(_caminho_sprite(), "olho")
	add_child(_olho)
	_recarga = randf_range(0.4, 1.0)


## Chamado pela Lamuriante a cada quadro enquanto este Ressequido está no alcance dela.
func fortalecer(duracao: float) -> void:
	_fortalecido = maxf(_fortalecido, duracao)


func esta_fortalecido() -> bool:
	return _fortalecido > 0.0


func _pensar(delta: float) -> void:
	_fortalecido = maxf(_fortalecido - delta, 0.0)
	var ritmo := 1.45 if esta_fortalecido() else 1.0
	corpo.speed_scale = ritmo
	_olho.position = Vector2(absf(_olho.position.x) * olhando, _olho.position.y)
	match acao:
		Acao.PERSEGUIR:
			_tocar(&"andar")
			_olho.energy = 0.35
			corpo.offset.x = -BibliotecaSprites.carregar(_caminho_sprite())["origem"].x
			if not alvo_vivo():
				velocidade_desejada = Vector2.ZERO
				return
			_recarga -= delta * ritmo
			var dist := distancia_alvo()
			if dist < ALCANCE and _recarga <= 0.0 and sala and sala.visao_livre(global_position, alvo.global_position):
				_iniciar_preparo()
			else:
				mover_para(alvo.global_position, dados.velocidade * ritmo, delta)
		Acao.PREPARAR:
			velocidade_desejada = Vector2.ZERO
			_tempo -= delta * ritmo
			# A mira acompanha a Coveira e trava pouco antes do bote: esquivar tarde funciona.
			if _tempo > TRAVA_MIRA and is_instance_valid(alvo):
				_direcao_ataque = (alvo.global_position - global_position).normalized()
				olhar_para(alvo.global_position)
			var tremor := 1.0 if int(_tempo * 40.0) % 2 == 0 else -1.0
			corpo.offset.x = -BibliotecaSprites.carregar(_caminho_sprite())["origem"].x + tremor
			_olho.energy = lerpf(1.4, 0.4, _tempo / PREPARO)
			if _tempo <= 0.0:
				_iniciar_investida()
		Acao.INVESTIR:
			_tempo -= delta
			var k := 1.0 - _tempo / DURACAO_INVESTIDA
			velocidade_desejada = _direcao_ataque * VELOCIDADE_INVESTIDA * (1.0 - 0.55 * k)
			caixa_golpe.position = _direcao_ataque * 10.0 + Vector2(0, -8)
			if _tempo <= 0.0:
				caixa_golpe.desativar()
				acao = Acao.RECUPERAR
				_tempo = RECUPERACAO
				_tocar(&"recuperar")
		Acao.RECUPERAR:
			velocidade_desejada = velocidade_desejada.move_toward(Vector2.ZERO, 600.0 * delta)
			_olho.energy = 0.15
			_tempo -= delta
			if _tempo <= 0.0:
				acao = Acao.PERSEGUIR
				_recarga = randf_range(0.7, 1.1)


func _iniciar_preparo() -> void:
	acao = Acao.PREPARAR
	_tempo = PREPARO
	_direcao_ataque = (alvo.global_position - global_position).normalized()
	olhar_para(alvo.global_position)
	_tocar(&"preparar")
	Audio.tocar(&"ressequido_preparar", global_position)


func _iniciar_investida() -> void:
	acao = Acao.INVESTIR
	_tempo = DURACAO_INVESTIDA
	_tocar(&"investir")
	corpo.offset.x = -BibliotecaSprites.carregar(_caminho_sprite())["origem"].x
	caixa_golpe.position = _direcao_ataque * 10.0 + Vector2(0, -8)
	caixa_golpe.ativar()
	Audio.tocar(&"ressequido_investida", global_position)
	Efeitos.poeira(global_position, 3, -_direcao_ataque)


func pode_ser_interrompido(info: DanoInfo) -> bool:
	if acao == Acao.PREPARAR or acao == Acao.INVESTIR:
		return info.interrupcao == DanoInfo.Interrupcao.FORTE
	return true


func ao_ser_interrompido(_info: DanoInfo) -> void:
	acao = Acao.PERSEGUIR
	_recarga = 0.9
	corpo.offset.x = -BibliotecaSprites.carregar(_caminho_sprite())["origem"].x
	_tocar(&"dano")


func _tocar(anim: StringName) -> void:
	if corpo.animation != anim or not corpo.is_playing():
		corpo.play(anim)
