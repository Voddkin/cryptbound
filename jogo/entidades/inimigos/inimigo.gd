class_name Inimigo
extends CharacterBody2D
## Base dos inimigos: surgimento, dano com flash e empurrão, postura (golpes que interrompem),
## estados alterados, morte com restos que ficam no chão, ossos, navegação e barra de vida.
## Subclasses implementam `_configurar` e `_pensar`.

signal morreu(inimigo: Inimigo)

enum Fase { SURGINDO, ATIVO, ATINGIDO, MORRENDO, MORTO }

const CAMADA_MUNDO := 1
const CAMADA_JOGADOR := 1 << 1
const CAMADA_INIMIGOS := 1 << 2
const SHADER := preload("res://jogo/efeitos/shaders/entidade.gdshader")
const DURACAO_SURGIR := 0.55
const ATRITO_EMPURRAO := 900.0

var dados: InimigoDados
var sala: Sala
var vida := 1.0
var vida_max := 1.0
var fase: Fase = Fase.SURGINDO
var atraso_surgimento := 0.0
var corpo: AnimatedSprite2D
var estados: Estados
var caixa_dano: CaixaDano
var caixa_golpe: CaixaGolpe
var alvo: Node2D
## Velocidade decidida pela IA neste quadro (o empurrão soma por cima).
var velocidade_desejada := Vector2.ZERO
var olhando := 1

var _material: ShaderMaterial
var _flash := 0.0
var _empurrao := Vector2.ZERO
var _tempo_atingido := 0.0
var _tempo_surgir := 0.0
var _barra := 0.0
var _caminho: PackedVector2Array = []
var _tempo_caminho := 0.0
var _sombra: Polygon2D
var _forma_corpo: CollisionShape2D


func _caminho_sprite() -> String:
	return ""


func _caminho_dados() -> String:
	return ""


## Monta formas, caixas de golpe e luzes específicas.
func _configurar() -> void:
	pass


## IA de um quadro de física (só roda em Fase.ATIVO e sem estado que impeça ação).
func _pensar(_delta: float) -> void:
	pass


## A postura do inimigo cede a este golpe? (superarmadura durante ataques etc.)
func pode_ser_interrompido(_info: DanoInfo) -> bool:
	return true


func ao_ser_interrompido(_info: DanoInfo) -> void:
	pass


func _ready() -> void:
	add_to_group(&"inimigos")
	if dados == null:
		dados = load(_caminho_dados()) as InimigoDados
	collision_layer = CAMADA_INIMIGOS
	collision_mask = CAMADA_MUNDO | CAMADA_JOGADOR | CAMADA_INIMIGOS
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	vida_max = roundf(dados.vida * Jogo.fator_profundidade())
	vida = vida_max
	_sombra = Polygon2D.new()
	_sombra.polygon = _elipse(7.0, 2.5)
	_sombra.color = Color(0, 0, 0, 0.4)
	add_child(_sombra)
	corpo = BibliotecaSprites.criar_animado(_caminho_sprite())
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	corpo.material = _material
	add_child(corpo)
	estados = Estados.new()
	estados.name = "Estados"
	add_child(estados)
	_forma_corpo = CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 5.0
	_forma_corpo.shape = circ
	_forma_corpo.position = Vector2(0, -3)
	add_child(_forma_corpo)
	caixa_dano = CaixaDano.new()
	caixa_dano.dono = self
	caixa_dano.collision_layer = CAMADA_INIMIGOS
	caixa_dano.collision_mask = 0
	caixa_dano.monitorable = false
	add_child(caixa_dano)
	_configurar()
	alvo = get_tree().get_first_node_in_group(&"jogador") as Node2D
	corpo.scale = Vector2(1.0, 0.0)
	corpo.visible = atraso_surgimento <= 0.0


func _elipse(rx: float, ry: float) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pontos.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pontos


func adicionar_forma_dano(forma: Shape2D, posicao: Vector2) -> void:
	var cs := CollisionShape2D.new()
	cs.shape = forma
	cs.position = posicao
	caixa_dano.add_child(cs)


func criar_caixa_golpe(forma: Shape2D) -> CaixaGolpe:
	caixa_golpe = CaixaGolpe.new()
	caixa_golpe.collision_layer = 0
	caixa_golpe.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape2D.new()
	cs.shape = forma
	caixa_golpe.add_child(cs)
	caixa_golpe.fabricar_dano = _fabricar_dano_ataque
	add_child(caixa_golpe)
	return caixa_golpe


func _fabricar_dano_ataque(alvo_atingido: Node2D) -> DanoInfo:
	var info := DanoInfo.new()
	info.valor = 1.0
	info.velas = dados.velas_de_dano
	info.atacante = self
	info.fonte_nome = dados.nome
	info.ataque_nome = dados.ataque
	info.dica = dados.dica
	info.direcao = (alvo_atingido.global_position - global_position).normalized()
	info.empurrao = 170.0
	info.hitstop = 0.08
	info.tremor = 0.45
	return info


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta * 9.0, 0.0)
	_material.set_shader_parameter(&"flash", _flash)
	_material.set_shader_parameter(&"realce", estados.cor_realce())
	_barra = maxf(_barra - delta, 0.0)
	if fase == Fase.MORTO:
		return
	if fase == Fase.MORRENDO:
		velocidade_desejada = Vector2.ZERO
		_mover(delta)
		return
	match fase:
		Fase.SURGINDO:
			_surgir(delta)
			return
		Fase.ATINGIDO:
			velocidade_desejada = Vector2.ZERO
			_tempo_atingido -= delta
			if _tempo_atingido <= 0.0:
				fase = Fase.ATIVO
		Fase.ATIVO:
			if estados.impede_acao():
				velocidade_desejada = Vector2.ZERO
			else:
				_pensar(delta)
	_mover(delta)
	if _barra > 0.0:
		queue_redraw()


func _surgir(delta: float) -> void:
	if atraso_surgimento > 0.0:
		atraso_surgimento -= delta
		if atraso_surgimento <= 0.0:
			corpo.visible = true
		return
	if _tempo_surgir == 0.0:
		Efeitos.poeira(global_position, 6)
		Efeitos.estilhacos_terra(global_position)
	_tempo_surgir += delta
	var k := clampf(_tempo_surgir / DURACAO_SURGIR, 0.0, 1.0)
	# Sai da terra: cresce a partir dos pés com um pequeno exagero no fim.
	corpo.scale = Vector2(1.0 + 0.25 * (1.0 - k), ease(k, 0.4) * (1.0 + 0.15 * sin(k * PI)))
	if k >= 1.0:
		corpo.scale = Vector2.ONE
		fase = Fase.ATIVO
		caixa_dano.monitorable = true


## Pula a animação de surgimento (usado por testes).
func pular_surgimento() -> void:
	atraso_surgimento = 0.0
	corpo.visible = true
	corpo.scale = Vector2.ONE
	fase = Fase.ATIVO
	caixa_dano.monitorable = true


func _mover(delta: float) -> void:
	velocity = velocidade_desejada + _empurrao
	_empurrao = _empurrao.move_toward(Vector2.ZERO, ATRITO_EMPURRAO * delta)
	move_and_slide()
	if absf(velocidade_desejada.x) > 2.0:
		olhando = 1 if velocidade_desejada.x > 0.0 else -1
	corpo.flip_h = olhando < 0


func olhar_para(posicao: Vector2) -> void:
	if absf(posicao.x - global_position.x) > 1.0:
		olhando = 1 if posicao.x > global_position.x else -1


## Vai até `destino` em linha reta se houver visão; senão segue o caminho do A*.
func mover_para(destino: Vector2, velocidade: float, delta: float) -> void:
	var direcao := Vector2.ZERO
	if sala == null or sala.visao_livre(global_position + Vector2(0, -3), destino + Vector2(0, -3)):
		direcao = (destino - global_position).normalized()
		_caminho = PackedVector2Array()
	else:
		_tempo_caminho -= delta
		if _tempo_caminho <= 0.0 or _caminho.is_empty():
			_tempo_caminho = 0.35
			_caminho = sala.caminho(global_position, destino)
		while _caminho.size() > 1 and global_position.distance_to(_caminho[0]) < 6.0:
			_caminho.remove_at(0)
		if not _caminho.is_empty():
			direcao = (_caminho[0] - global_position).normalized()
	velocidade_desejada = (direcao + _separacao() * 0.8).limit_length(1.0) * velocidade


func _separacao() -> Vector2:
	var empurra := Vector2.ZERO
	for outro in get_tree().get_nodes_in_group(&"inimigos"):
		if outro == self or not (outro is Inimigo) or (outro as Inimigo).fase >= Fase.MORRENDO:
			continue
		var d := global_position - (outro as Node2D).global_position
		var dist := d.length()
		if dist > 0.01 and dist < 16.0:
			empurra += d / dist * (1.0 - dist / 16.0)
	return empurra


func distancia_alvo() -> float:
	return global_position.distance_to(alvo.global_position) if is_instance_valid(alvo) else INF


func alvo_vivo() -> bool:
	return is_instance_valid(alvo) and alvo.has_method(&"esta_vivo") and alvo.esta_vivo()


func receber_dano(info: DanoInfo) -> bool:
	if fase in [Fase.SURGINDO, Fase.MORRENDO, Fase.MORTO]:
		return false
	vida -= info.valor
	_barra = 2.5
	var de_estado := info.tem_tag(&"estado")
	if info.valor > 0.0:
		_flash = 0.6 if de_estado else 1.0
		var cor := Color("e8574a") if de_estado else (Color("f7bb47") if info.interrupcao == DanoInfo.Interrupcao.FORTE else Color("f2e8d0"))
		Efeitos.numero(global_position + Vector2(0, -16), info.valor, cor)
		if de_estado:
			Audio.tocar(&"sangria", global_position, 0.15, -6.0)
		else:
			Audio.tocar(dados.som_acerto, global_position)
			Efeitos.impacto(global_position + Vector2(0, -10), info.direcao, dados.material)
	var cede := pode_ser_interrompido(info)
	if info.empurrao > 0.0 and info.direcao != Vector2.ZERO:
		_empurrao += info.direcao.normalized() * info.empurrao * (1.0 if cede else 0.25)
	Eventos.golpe_acertou.emit(info, self)
	if vida <= 0.0:
		morrer(info)
		return true
	if cede and info.interrupcao != DanoInfo.Interrupcao.NENHUMA:
		fase = Fase.ATINGIDO
		_tempo_atingido = 0.35 if info.interrupcao == DanoInfo.Interrupcao.FORTE else 0.16
		if caixa_golpe:
			caixa_golpe.desativar()
		ao_ser_interrompido(info)
	return true


func morrer(info: DanoInfo) -> void:
	if fase >= Fase.MORRENDO:
		return
	fase = Fase.MORRENDO
	_barra = 0.0
	queue_redraw()
	estados.limpar()
	if caixa_golpe:
		caixa_golpe.desativar()
	caixa_dano.set_deferred(&"monitorable", false)
	_forma_corpo.set_deferred(&"disabled", true)
	corpo.play(&"morte")
	Audio.tocar(dados.som_morte, global_position)
	Efeitos.tremer(0.2, info.direcao)
	_soltar_ossos()
	Eventos.inimigo_morreu.emit(self, info)
	morreu.emit(self)
	corpo.animation_finished.connect(_virar_resto, CONNECT_ONE_SHOT)


func _soltar_ossos() -> void:
	var quantidade := randi_range(dados.ossos_min, dados.ossos_max)
	var destino: Node = sala.mundo if sala else get_parent()
	for i in quantidade:
		var impulso := Vector2.from_angle(randf() * TAU) * randf_range(20.0, 55.0)
		destino.add_child.call_deferred(Coletavel.criar(Coletavel.Tipo.OSSO, 1, global_position + Vector2(0, -2), impulso))


## Os restos ficam no chão até a Coveira sair da sala (a história da luta fica visível).
func _virar_resto() -> void:
	fase = Fase.MORTO
	_sombra.visible = false
	z_index = -16
	set_physics_process(false)
	_material.set_shader_parameter(&"flash", 0.0)
	_material.set_shader_parameter(&"realce", Color(0, 0, 0, 0))
	corpo.modulate = Color(0.8, 0.78, 0.82)


func esta_vivo() -> bool:
	return fase < Fase.MORRENDO


func _draw() -> void:
	if _barra <= 0.0 or fase >= Fase.MORRENDO:
		return
	var largura := 14.0
	var y := -float(corpo.sprite_frames.get_frame_texture(corpo.animation, 0).get_height()) - 3.0
	var fracao := clampf(vida / vida_max, 0.0, 1.0)
	var alfa := clampf(_barra / 0.4, 0.0, 1.0)
	draw_rect(Rect2(-largura * 0.5 - 1, y - 1, largura + 2, 4), Color(0.04, 0.035, 0.06, alfa))
	draw_rect(Rect2(-largura * 0.5, y, largura, 2), Color(0.25, 0.08, 0.1, alfa))
	draw_rect(Rect2(-largura * 0.5, y, roundf(largura * fracao), 2), Color(0.85, 0.3, 0.26, alfa))
