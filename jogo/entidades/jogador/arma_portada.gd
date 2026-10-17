class_name ArmaPortada
extends Node2D
## Visual da arma na mão da Coveira: gira em volta do corpo seguindo a mira, recua na
## antecipação, varre o arco no golpe ativo e volta ao repouso. Só visual — o acerto é da
## CaixaGolpe do jogador.

enum Modo { REPOUSO, GOLPE, CARGA }

const RAIO_REPOUSO := 5.0

var sprite: Sprite2D
var modo: Modo = Modo.REPOUSO
var _golpe: GolpeDados
var _mira := Vector2.DOWN
var _angulo := PI * 0.5
var _raio := RAIO_REPOUSO
var _t := 0.0


func configurar(arma: ArmaDados) -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.centered = false
		add_child(sprite)
	sprite.texture = arma.sprite
	sprite.offset = -arma.empunhadura


func iniciar_golpe(golpe: GolpeDados, mira: Vector2) -> void:
	modo = Modo.GOLPE
	_golpe = golpe
	_mira = mira


func carregar(mira: Vector2) -> void:
	modo = Modo.CARGA
	_mira = mira


func repousar() -> void:
	modo = Modo.REPOUSO


## fase: 0 antecipação, 1 ativo, 2 recuperação; progresso 0..1 dentro da fase.
func atualizar(delta: float, fase: int, progresso: float, mira: Vector2, vista: Vector2, carga: float) -> void:
	_t += delta
	var alvo_angulo := _angulo
	var alvo_raio := RAIO_REPOUSO
	match modo:
		Modo.REPOUSO:
			# Pá apoiada, apontando para a frente e levemente para baixo.
			var base := vista.angle()
			var lado := 1.0 if vista.x >= 0.0 else -1.0
			alvo_angulo = base + 0.75 * lado
			alvo_raio = RAIO_REPOUSO + sin(_t * 3.0) * 0.5
			_angulo = lerp_angle(_angulo, alvo_angulo, minf(1.0, 14.0 * delta))
			_raio = lerpf(_raio, alvo_raio, minf(1.0, 14.0 * delta))
		Modo.CARGA:
			_mira = mira
			var lado := 1.0 if mira.x >= 0.0 else -1.0
			alvo_angulo = mira.angle() - 1.9 * lado
			_angulo = lerp_angle(_angulo, alvo_angulo, minf(1.0, 18.0 * delta))
			_raio = RAIO_REPOUSO + 1.0 + carga * 1.5
		Modo.GOLPE:
			var arco := deg_to_rad(_golpe.arco_graus)
			var centro := _mira.angle()
			var sentido := float(_golpe.sentido_giro)
			if sentido == 0.0:
				# Estocada/pancada: a pá avança na direção da mira e volta.
				_angulo = centro
				match fase:
					0: _raio = lerpf(RAIO_REPOUSO, 2.0, progresso)
					1: _raio = lerpf(2.0, _golpe.alcance * 0.55, ease(progresso, 0.3))
					2: _raio = lerpf(_golpe.alcance * 0.55, RAIO_REPOUSO, ease(progresso, 2.0))
			else:
				var inicio := centro - arco * 0.5 * sentido
				var fim := centro + arco * 0.5 * sentido
				match fase:
					0: _angulo = lerp_angle(_angulo, inicio - 0.35 * sentido, minf(1.0, progresso * 1.5))
					1: _angulo = lerpf(inicio, fim, ease(progresso, 0.35))
					2: _angulo = fim
				_raio = RAIO_REPOUSO + (3.0 if fase == 1 else 1.0)
	position = Vector2.from_angle(_angulo) * _raio + Vector2(0, -9)
	rotation = _angulo
	# Lâmina nunca de cabeça para baixo
	if sprite:
		sprite.flip_v = cos(_angulo) < 0.0


## A arma fica atrás do corpo quando aponta para cima.
func atras_do_corpo() -> bool:
	return sin(_angulo) < -0.35
