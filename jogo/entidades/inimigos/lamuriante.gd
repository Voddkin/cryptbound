class_name Lamuriante
extends Inimigo
## Figura velada de cera com velas acesas na cabeça. Mantém distância, lança a Lamúria
## (onda lenta, telegrafada por 0,75 s) e fortalece os Ressequidos ao alcance — um fio de
## luz roxa mostra quem está ligado a ela. Golpes FORTES interrompem o lamento.

enum Acao { VAGAR, PREPARAR, LANCAR }

const ALCANCE_FIO := 112.0
const DISTANCIA_MIN := 78.0
const DISTANCIA_MAX := 150.0
const PREPARO := 0.75

var acao: Acao = Acao.VAGAR
var _tempo := 0.0
var _recarga := 2.0
var _ligados: Array[Ressequido] = []
var _t := 0.0
var _brilho: PointLight2D
var _sentido_rodeio := 1.0


func _caminho_sprite() -> String:
	return "res://arte/personagens/lamuriante.json"


func _caminho_dados() -> String:
	return "res://dados/inimigos/lamuriante.tres"


func _configurar() -> void:
	var caixa := RectangleShape2D.new()
	caixa.size = Vector2(14, 24)
	adicionar_forma_dano(caixa, Vector2(0, -14))
	var velas := LuzTremulante.new(Color(1.0, 0.72, 0.45), 0.8, 0.9, get_instance_id())
	velas.position = Vector2(0, -30)
	add_child(velas)
	_brilho = PointLight2D.new()
	_brilho.texture = preload("res://arte/luzes/luz_suave.png")
	_brilho.color = Color("9a5cd0")
	_brilho.energy = 0.0
	_brilho.texture_scale = 0.8
	_brilho.position = Vector2(0, -18)
	add_child(_brilho)
	_recarga = randf_range(1.2, 2.2)
	_sentido_rodeio = 1.0 if randf() < 0.5 else -1.0


func _pensar(delta: float) -> void:
	_t += delta
	corpo.position.y = roundf(sin(_t * 2.2) * 1.5) - 2.0
	_atualizar_fios()
	if not alvo_vivo():
		velocidade_desejada = Vector2.ZERO
		return
	olhar_para(alvo.global_position)
	match acao:
		Acao.VAGAR:
			_tocar(&"flutuar")
			_brilho.energy = move_toward(_brilho.energy, 0.0, delta * 2.0)
			var dist := distancia_alvo()
			var visao := sala == null or sala.visao_livre(global_position + Vector2(0, -12), alvo.global_position + Vector2(0, -8))
			if dist < DISTANCIA_MIN:
				var fuga := (global_position - alvo.global_position).normalized()
				mover_para(global_position + fuga * 32.0, dados.velocidade * 1.1, delta)
			elif dist > DISTANCIA_MAX or not visao:
				mover_para(alvo.global_position, dados.velocidade, delta)
			else:
				var lado := (global_position - alvo.global_position).normalized().orthogonal() * _sentido_rodeio
				velocidade_desejada = (lado + _separacao()).limit_length(1.0) * dados.velocidade * 0.6
			_recarga -= delta
			if _recarga <= 0.0 and visao and dist < 220.0:
				acao = Acao.PREPARAR
				_tempo = PREPARO
				_tocar(&"preparar")
				Audio.tocar(&"lamuriante_lamento", global_position, 0.05)
		Acao.PREPARAR:
			velocidade_desejada = Vector2.ZERO
			_tempo -= delta
			_brilho.energy = lerpf(1.3, 0.2, _tempo / PREPARO)
			if _tempo <= 0.0:
				_lancar()
		Acao.LANCAR:
			velocidade_desejada = Vector2.ZERO
			_tempo -= delta
			_brilho.energy = move_toward(_brilho.energy, 0.0, delta * 3.0)
			if _tempo <= 0.0:
				acao = Acao.VAGAR
				_recarga = randf_range(2.3, 3.0)
				if randf() < 0.35:
					_sentido_rodeio = -_sentido_rodeio


func _lancar() -> void:
	acao = Acao.LANCAR
	_tempo = 0.45
	_tocar(&"lancar")
	Audio.tocar(&"lamuria_disparo", global_position)
	var origem := global_position + Vector2(0, -14)
	var projetil := ProjetilLamuria.new()
	projetil.direcao = (alvo.global_position + Vector2(0, -8) - origem).normalized()
	projetil.dados_origem = dados
	projetil.atirador = self
	projetil.position = origem
	(sala.mundo if sala else get_parent()).add_child(projetil)


func _atualizar_fios() -> void:
	_ligados.clear()
	for outro in get_tree().get_nodes_in_group(&"inimigos"):
		if outro is Ressequido and (outro as Ressequido).esta_vivo() and (outro as Ressequido).fase == Fase.ATIVO:
			if global_position.distance_to((outro as Node2D).global_position) < ALCANCE_FIO:
				(outro as Ressequido).fortalecer(0.25)
				_ligados.append(outro)
	queue_redraw()


func pode_ser_interrompido(info: DanoInfo) -> bool:
	if acao == Acao.PREPARAR:
		return info.interrupcao == DanoInfo.Interrupcao.FORTE
	return true


func ao_ser_interrompido(_info: DanoInfo) -> void:
	acao = Acao.VAGAR
	_recarga = 1.4
	_brilho.energy = 0.0
	_tocar(&"dano")


func morrer(info: DanoInfo) -> void:
	_ligados.clear()
	queue_redraw()
	super.morrer(info)
	Efeitos.cinzas_cera(global_position + Vector2(0, -16), 10)


func _tocar(anim: StringName) -> void:
	if corpo.animation != anim or not corpo.is_playing():
		corpo.play(anim)


func _draw() -> void:
	super._draw()
	if fase >= Fase.MORRENDO:
		return
	# Fio de luz roxa até cada Ressequido fortalecido (leitura clara da prioridade).
	var origem := Vector2(0, -18)
	for r in _ligados:
		if not is_instance_valid(r):
			continue
		var destino := to_local(r.global_position + Vector2(0, -10))
		var cor := Color("9a5cd0")
		cor.a = 0.45 + 0.2 * sin(_t * 9.0)
		var meio := (origem + destino) * 0.5 + Vector2(0, 4 + sin(_t * 3.0) * 3.0)
		draw_polyline(PackedVector2Array([origem, meio, destino]), cor, 1.0)
