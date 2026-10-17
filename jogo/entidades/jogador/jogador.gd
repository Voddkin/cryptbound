class_name Jogador
extends CharacterBody2D
## A Coveira. Movimento em 8 direções com aceleração curta, combo de 3 golpes com janelas de
## cancelamento, golpe pesado carregado, esquiva com invulnerabilidade e imagens residuais,
## buffer de entrada, dano em velas, morte e interação com o cenário.
## A entrada vem de uma FonteEntrada (jogador humano, teste ou robô de demonstração).

enum Situacao { LIVRE, ATACANDO, CARREGANDO, ESQUIVANDO, ATINGIDO, MORTO, PARADO }
enum Fase { ANTECIPACAO, ATIVO, RECUPERACAO }

const VELOCIDADE := 92.0
const ACELERACAO := 950.0
const DESACELERACAO := 1250.0
const BUFFER := 0.12
const ESQUIVA_DURACAO := 0.24
const ESQUIVA_INVULNERAVEL := 0.18
const ESQUIVA_VEL_INICIAL := 265.0
const ESQUIVA_VEL_FINAL := 105.0
const ESQUIVA_RECARGA := 0.3
const INVULNERAVEL_APOS_DANO := 0.9
const CENTRO := Vector2(0, -9)
const SPRITE := "res://arte/personagens/coveira.json"
const SHADER := preload("res://jogo/efeitos/shaders/entidade.gdshader")
const CAMADA_MUNDO := 1
const CAMADA_JOGADOR := 1 << 1
const CAMADA_INIMIGOS := 1 << 2

signal morreu(info: DanoInfo)

var entrada: FonteEntrada = EntradaHumana.new()
var arma: ArmaDados
var estado: Situacao = Situacao.LIVRE
var corpo: AnimatedSprite2D
var arma_visual: ArmaPortada
var rastro: RastroGolpe
var caixa_golpe: CaixaGolpe
var caixa_dano: CaixaDano
var estados: Estados
var lanterna: LuzTremulante
var gatilhos := Gatilhos.new()
## Para onde o corpo está virado e para onde a Coveira mira.
var direcao_vista := Vector2.DOWN
var mira := Vector2.DOWN

var _relogio := 0.0
var _golpe: GolpeDados
var _fase: Fase = Fase.ANTECIPACAO
var _tempo_fase := 0.0
var _mira_golpe := Vector2.DOWN
var _indice_combo := 0
var _indice_atual := 0
var _inicio_golpe := -10.0
var _fim_ultimo_golpe := -10.0
var _pedido_ataque := -10.0
var _pedido_esquiva := -10.0
var _carga := 0.0
var _carga_pronta := false
var _esquiva_t := 0.0
var _inicio_esquiva := -10.0
var _esquiva_dir := Vector2.DOWN
var _recarga_esquiva := 0.0
var _esquiva_invulneravel := 0.0
var _residuo := 0.0
var _invulneravel := 0.0
var _atingido := 0.0
var _empurrao := Vector2.ZERO
var _interagiveis: Array[Interagivel] = []
var _foco: Interagivel
var _passo := 0.0
var _flash := 0.0
var _cor_flash := Color.WHITE
var _material: ShaderMaterial
var _poligono_golpe: CollisionPolygon2D
var _escala := Vector2.ONE


func _ready() -> void:
	add_to_group(&"jogador")
	collision_layer = CAMADA_JOGADOR
	collision_mask = CAMADA_MUNDO | CAMADA_INIMIGOS
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if arma == null:
		arma = Jogo.arma if Jogo.arma else load("res://dados/armas/pa_de_coveiro.tres") as ArmaDados

	var sombra := Polygon2D.new()
	var pontos := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pontos.append(Vector2(cos(a) * 6.0, sin(a) * 2.2))
	sombra.polygon = pontos
	sombra.color = Color(0, 0, 0, 0.42)
	add_child(sombra)

	arma_visual = ArmaPortada.new()
	arma_visual.configurar(arma)
	add_child(arma_visual)
	corpo = BibliotecaSprites.criar_animado(SPRITE, &"parado_baixo")
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	corpo.material = _material
	add_child(corpo)
	rastro = RastroGolpe.new()
	rastro.z_index = 2
	add_child(rastro)

	var forma := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 4.5
	forma.shape = circ
	forma.position = Vector2(0, -3)
	add_child(forma)

	caixa_dano = CaixaDano.new()
	caixa_dano.dono = self
	caixa_dano.collision_layer = CAMADA_JOGADOR
	caixa_dano.collision_mask = 0
	var forma_d := CollisionShape2D.new()
	var circ_d := CircleShape2D.new()
	circ_d.radius = 5.5
	forma_d.shape = circ_d
	forma_d.position = CENTRO + Vector2(0, 2)
	caixa_dano.add_child(forma_d)
	add_child(caixa_dano)

	caixa_golpe = CaixaGolpe.new()
	caixa_golpe.collision_layer = 0
	caixa_golpe.collision_mask = CAMADA_INIMIGOS
	_poligono_golpe = CollisionPolygon2D.new()
	caixa_golpe.add_child(_poligono_golpe)
	caixa_golpe.fabricar_dano = _fabricar_dano
	caixa_golpe.acertou.connect(_ao_acertar)
	add_child(caixa_golpe)

	estados = Estados.new()
	estados.name = "Estados"
	add_child(estados)

	lanterna = LuzTremulante.new(Color(1.0, 0.78, 0.5), 0.95, 1.9, 4242)
	lanterna.intensidade_tremor = 0.06
	lanterna.position = BibliotecaSprites.ponto(SPRITE, "lanterna")
	add_child(lanterna)


# --- Laço principal -----------------------------------------------------------

func _physics_process(delta: float) -> void:
	_relogio += delta
	gatilhos.avancar(delta)
	_invulneravel = maxf(_invulneravel - delta, 0.0)
	_esquiva_invulneravel = maxf(_esquiva_invulneravel - delta, 0.0)
	_recarga_esquiva = maxf(_recarga_esquiva - delta, 0.0)
	_flash = maxf(_flash - delta * 6.0, 0.0)
	_material.set_shader_parameter(&"flash", _flash)
	_material.set_shader_parameter(&"cor_flash", _cor_flash)
	_material.set_shader_parameter(&"realce", estados.cor_realce())
	corpo.visible = estado == Situacao.MORTO or _invulneravel <= 0.0 or int(_relogio * 16.0) % 2 == 0

	if estado == Situacao.MORTO or estado == Situacao.PARADO:
		velocity = velocity.move_toward(Vector2.ZERO, DESACELERACAO * delta)
		move_and_slide()
		_animar(delta)
		return

	entrada.atualizar(self, delta)
	if entrada.atacar:
		_pedido_ataque = _relogio
	if entrada.esquivar:
		_pedido_esquiva = _relogio
	if entrada.mirar != Vector2.ZERO:
		mira = entrada.mirar.normalized()
	elif entrada.mover.length() > 0.2 and estado == Situacao.LIVRE:
		mira = entrada.mover.normalized()

	match estado:
		Situacao.LIVRE: _estado_livre(delta)
		Situacao.ATACANDO: _estado_atacando(delta)
		Situacao.CARREGANDO: _estado_carregando(delta)
		Situacao.ESQUIVANDO: _estado_esquivando(delta)
		Situacao.ATINGIDO: _estado_atingido(delta)

	velocity += _empurrao
	move_and_slide()
	velocity -= _empurrao
	_empurrao = _empurrao.move_toward(Vector2.ZERO, 900.0 * delta)

	if entrada.interagir and _foco and estado == Situacao.LIVRE:
		_foco.interagir(self)
	_atualizar_foco()
	_animar(delta)
	entrada.limpar_pressoes()


func _mover_com(alvo: Vector2, delta: float) -> void:
	var taxa := ACELERACAO if alvo.length() > velocity.length() else DESACELERACAO
	velocity = velocity.move_toward(alvo, taxa * delta)


func _quer_atacar() -> bool:
	if _relogio - _pedido_ataque <= BUFFER:
		_pedido_ataque = -10.0
		return true
	return false


func _quer_esquivar() -> bool:
	if _recarga_esquiva <= 0.0 and _relogio - _pedido_esquiva <= BUFFER:
		_pedido_esquiva = -10.0
		return true
	return false


# --- Estados ---------------------------------------------------------------------

func _estado_livre(delta: float) -> void:
	var dir := entrada.mover.limit_length(1.0)
	_mover_com(dir * VELOCIDADE, delta)
	if entrada.mirar != Vector2.ZERO:
		direcao_vista = entrada.mirar
	elif dir.length() > 0.1:
		direcao_vista = dir
	if _quer_esquivar():
		_iniciar_esquiva()
	elif entrada.pesado:
		_iniciar_carga()
	elif _quer_atacar():
		_iniciar_golpe_combo()


func _iniciar_golpe_combo() -> void:
	if _relogio - _fim_ultimo_golpe > arma.tempo_combo or _indice_combo >= arma.combo.size():
		_indice_combo = 0
	_iniciar_golpe(arma.combo[_indice_combo], _indice_combo)


func _iniciar_golpe(golpe: GolpeDados, indice: int) -> void:
	estado = Situacao.ATACANDO
	_golpe = golpe
	_indice_atual = indice
	_inicio_golpe = _relogio
	_fase = Fase.ANTECIPACAO
	_tempo_fase = golpe.antecipacao
	_mira_golpe = mira
	direcao_vista = mira
	_construir_area(golpe, _mira_golpe)
	arma_visual.iniciar_golpe(golpe, _mira_golpe)
	_escala = Vector2(0.92, 1.08)


func _estado_atacando(delta: float) -> void:
	_tempo_fase -= delta
	match _fase:
		Fase.ANTECIPACAO:
			velocity = velocity.move_toward(Vector2.ZERO, DESACELERACAO * delta)
			if _quer_esquivar():
				_encerrar_golpe(false)
				_iniciar_esquiva()
				return
			if _tempo_fase <= 0.0:
				_entrar_ativo()
		Fase.ATIVO:
			velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
			if _tempo_fase <= 0.0:
				caixa_golpe.desativar()
				_fase = Fase.RECUPERACAO
				_tempo_fase = _golpe.recuperacao
		Fase.RECUPERACAO:
			_mover_com(entrada.mover.limit_length(1.0) * VELOCIDADE * 0.35, delta)
			var cancelavel := _tempo_fase <= _golpe.recuperacao * (1.0 - _golpe.janela_cancelamento)
			if cancelavel:
				# Pedidos feitos durante o golpe atual valem quando a janela abre (apertar
				# repetidamente encadeia o combo sem precisar acertar o tempo exato).
				if _recarga_esquiva <= 0.0 and _pedido_esquiva > _inicio_golpe:
					_pedido_esquiva = -10.0
					_encerrar_golpe(true)
					_iniciar_esquiva()
					return
				var eh_combo := _indice_atual >= 0 and _indice_atual < arma.combo.size() - 1
				if eh_combo and _pedido_ataque > _inicio_golpe + _golpe.antecipacao * 0.5:
					_pedido_ataque = -10.0
					_encerrar_golpe(true)
					_iniciar_golpe(arma.combo[_indice_atual + 1], _indice_atual + 1)
					return
			if _tempo_fase <= 0.0:
				_encerrar_golpe(true)
				estado = Situacao.LIVRE


func _entrar_ativo() -> void:
	_fase = Fase.ATIVO
	_tempo_fase = _golpe.ativo
	velocity = _mira_golpe * _golpe.avanco
	caixa_golpe.ativar()
	rastro.iniciar(_mira_golpe, _golpe, _indice_atual < 0)
	Audio.tocar(_golpe.som, global_position)
	_escala = Vector2(1.1, 0.9)
	if _indice_atual < 0:
		# Cavada: impacto no chão em volta da Coveira.
		Audio.tocar(&"impacto_pesado", global_position)
		Efeitos.onda(global_position + _mira_golpe * 12.0, _golpe.alcance * 0.9, &"poeira")
		Efeitos.poeira(global_position + _mira_golpe * 14.0, 8)
		Efeitos.tremer(0.25, _mira_golpe)


func _encerrar_golpe(completo: bool) -> void:
	caixa_golpe.desativar()
	arma_visual.repousar()
	_fim_ultimo_golpe = _relogio
	if completo and _indice_atual >= 0 and _indice_atual < arma.combo.size() - 1:
		_indice_combo = _indice_atual + 1
	else:
		_indice_combo = 0


func _iniciar_carga() -> void:
	estado = Situacao.CARREGANDO
	_carga = 0.0
	_carga_pronta = false
	arma_visual.carregar(mira)


func _estado_carregando(delta: float) -> void:
	_carga += delta
	direcao_vista = mira
	_mover_com(entrada.mover.limit_length(1.0) * VELOCIDADE * 0.45, delta)
	if not _carga_pronta and _carga >= arma.carga_pesado:
		_carga_pronta = true
		_flash = 0.7
		_cor_flash = Color("f7bb47")
		Audio.tocar(&"carga_pronta", global_position)
	if _quer_esquivar():
		arma_visual.repousar()
		_iniciar_esquiva()
		return
	if not entrada.pesado:
		if _carga_pronta:
			_iniciar_golpe(arma.pesado, -1)
		else:
			arma_visual.repousar()
			estado = Situacao.LIVRE


func _iniciar_esquiva() -> void:
	estado = Situacao.ESQUIVANDO
	_esquiva_t = 0.0
	_inicio_esquiva = _relogio
	_esquiva_dir = entrada.mover.normalized() if entrada.mover.length() > 0.2 else direcao_vista.normalized()
	if _esquiva_dir == Vector2.ZERO:
		_esquiva_dir = Vector2.DOWN
	direcao_vista = _esquiva_dir
	_esquiva_invulneravel = ESQUIVA_INVULNERAVEL
	collision_mask = CAMADA_MUNDO
	_escala = Vector2(1.25, 0.78)
	_residuo = 0.0
	Audio.tocar(&"esquiva", global_position)
	Efeitos.poeira(global_position, 4, -_esquiva_dir)
	Eventos.jogador_esquivou.emit(self)
	gatilhos.disparar(&"ao_esquivar", ContextoEfeito.new(self, null, null, global_position), Jogo.itens)


func _estado_esquivando(delta: float) -> void:
	_esquiva_t += delta
	var k := clampf(_esquiva_t / ESQUIVA_DURACAO, 0.0, 1.0)
	velocity = _esquiva_dir * lerpf(ESQUIVA_VEL_INICIAL, ESQUIVA_VEL_FINAL, pow(k, 0.7))
	_residuo -= delta
	if _residuo <= 0.0:
		_residuo = 0.035
		_deixar_residuo()
	if k >= 1.0:
		_sair_da_esquiva()
		estado = Situacao.LIVRE
		_escala = Vector2(0.9, 1.1)
		# Ataque pedido durante a esquiva sai logo em seguida (esquiva → contra-ataque).
		if _pedido_ataque > _inicio_esquiva:
			_pedido_ataque = _relogio


## Volta a colidir com inimigos e começa a recarga (fim normal ou golpe no fim da esquiva).
func _sair_da_esquiva() -> void:
	collision_mask = CAMADA_MUNDO | CAMADA_INIMIGOS
	_recarga_esquiva = ESQUIVA_RECARGA


func _estado_atingido(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, DESACELERACAO * delta)
	_atingido -= delta
	if _atingido <= 0.0:
		estado = Situacao.LIVRE


# --- Golpes ----------------------------------------------------------------------

func _construir_area(golpe: GolpeDados, direcao: Vector2) -> void:
	var pontos := PackedVector2Array()
	var arco := deg_to_rad(golpe.arco_graus)
	var centro := direcao.angle()
	var segmentos := 8
	pontos.append(CENTRO + direcao * golpe.alcance_minimo)
	for i in segmentos + 1:
		var a := centro - arco * 0.5 + arco * float(i) / segmentos
		pontos.append(CENTRO + Vector2.from_angle(a) * golpe.alcance)
	_poligono_golpe.polygon = pontos


func _fabricar_dano(alvo: Node2D) -> DanoInfo:
	var info := DanoInfo.new()
	info.valor = _golpe.dano
	info.atacante = self
	info.fonte_nome = "Coveira"
	info.ataque_nome = _golpe.nome
	var para_alvo := (alvo.global_position - global_position).normalized()
	info.direcao = (para_alvo + _mira_golpe).normalized()
	info.empurrao = _golpe.empurrao
	info.interrupcao = _golpe.interrupcao
	info.hitstop = _golpe.hitstop
	info.tremor = _golpe.tremor
	info.tags = _golpe.tags.duplicate()
	return info


func _ao_acertar(alvo: Node2D, info: DanoInfo) -> void:
	Efeitos.hitstop(info.hitstop)
	Efeitos.tremer(info.tremor, info.direcao)
	var ctx := ContextoEfeito.new(self, alvo, info, alvo.global_position)
	gatilhos.disparar(&"ao_acertar", ctx, Jogo.itens)
	if alvo.has_method(&"esta_vivo") and not alvo.esta_vivo():
		gatilhos.disparar(&"ao_eliminar", ctx, Jogo.itens)


# --- Dano e morte ---------------------------------------------------------------

func invulneravel() -> bool:
	return _invulneravel > 0.0 or _esquiva_invulneravel > 0.0 or estado == Situacao.MORTO


func receber_dano(info: DanoInfo) -> bool:
	if invulneravel() or estado == Situacao.PARADO:
		return false
	Jogo.perder_velas(info.velas)
	_invulneravel = INVULNERAVEL_APOS_DANO
	_flash = 1.0
	_cor_flash = Color("e8574a")
	Efeitos.hitstop(maxf(info.hitstop, 0.07))
	Efeitos.tremer(maxf(info.tremor, 0.45), info.direcao)
	Efeitos.sangue(global_position + CENTRO, info.direcao, 5)
	Audio.tocar(&"jogador_dano", global_position, 0.04)
	Audio.tocar(&"vela_apagar", global_position)
	_empurrao = info.direcao.normalized() * info.empurrao
	if estado == Situacao.ATACANDO or estado == Situacao.CARREGANDO:
		_encerrar_golpe(false)
	elif estado == Situacao.ESQUIVANDO:
		_sair_da_esquiva()
	Eventos.jogador_atingido.emit(info)
	gatilhos.disparar(&"ao_sofrer_dano", ContextoEfeito.new(self, info.atacante, info, global_position), Jogo.itens)
	if Jogo.velas <= 0:
		_morrer(info)
	else:
		estado = Situacao.ATINGIDO
		_atingido = 0.2
	return true


func _morrer(info: DanoInfo) -> void:
	estado = Situacao.MORTO
	collision_mask = CAMADA_MUNDO
	caixa_golpe.desativar()
	arma_visual.visible = false
	lanterna.energia_base = 0.4
	corpo.play(&"morte")
	Audio.parar_musica(1.5)
	Audio.tocar(&"morte_jogador")
	Efeitos.definir_escala_base(0.35)
	Jogo.registrar_morte(info)
	get_tree().create_timer(1.6, true, false, true).timeout.connect(func() -> void:
		Efeitos.definir_escala_base(1.0)
		morreu.emit(info)
		Eventos.jogador_morreu.emit(info))


func esta_vivo() -> bool:
	return estado != Situacao.MORTO


## Congela a Coveira (transições de sala, menus).
func parar(sim: bool) -> void:
	if estado == Situacao.MORTO:
		return
	if sim:
		if estado == Situacao.ATACANDO or estado == Situacao.CARREGANDO:
			_encerrar_golpe(false)
		estado = Situacao.PARADO
		collision_mask = CAMADA_MUNDO | CAMADA_INIMIGOS
		velocity = Vector2.ZERO
	else:
		estado = Situacao.LIVRE


# --- Interação -------------------------------------------------------------------

func registrar_interagivel(i: Interagivel) -> void:
	if not _interagiveis.has(i):
		_interagiveis.append(i)


func remover_interagivel(i: Interagivel) -> void:
	_interagiveis.erase(i)


## Esquece interações da sala anterior (chamado nas transições).
func limpar_interacoes() -> void:
	_interagiveis.clear()
	_foco = null
	_texto_foco = ""
	Eventos.dica_interacao.emit("")
	Eventos.item_em_foco.emit(null)


func _atualizar_foco() -> void:
	if _foco != null and not is_instance_valid(_foco):
		_foco = null
	var melhor: Interagivel = null
	var menor := INF
	for i in _interagiveis:
		if not is_instance_valid(i) or i.texto_acao() == "":
			continue
		var d := global_position.distance_to(i.global_position)
		if d < menor:
			menor = d
			melhor = i
	var texto := "" if melhor == null else Textos.t("hud.interagir", {"tecla": Controles.nome_entrada(&"interagir"), "acao": melhor.texto_acao()})
	if melhor != _foco or (melhor and texto != _texto_foco):
		_foco = melhor
		_texto_foco = texto
		Eventos.dica_interacao.emit(texto)
		Eventos.item_em_foco.emit(melhor.item_associado() if melhor else null)


var _texto_foco := ""


# --- Visual ----------------------------------------------------------------------

func _deixar_residuo() -> void:
	var fantasma := Sprite2D.new()
	fantasma.texture = corpo.sprite_frames.get_frame_texture(corpo.animation, corpo.frame)
	fantasma.centered = false
	fantasma.offset = corpo.offset
	fantasma.flip_h = corpo.flip_h
	fantasma.global_position = global_position
	fantasma.modulate = Color(0.55, 0.85, 0.8, 0.55)
	fantasma.z_index = -1
	get_parent().add_child(fantasma)
	var t := fantasma.create_tween()
	t.tween_property(fantasma, ^"modulate:a", 0.0, 0.2)
	t.tween_callback(fantasma.queue_free)


func _animar(delta: float) -> void:
	_escala = _escala.lerp(Vector2.ONE, minf(1.0, 12.0 * delta))
	corpo.scale = _escala
	var sufixo := "baixo"
	if absf(direcao_vista.x) > absf(direcao_vista.y) * 0.9:
		sufixo = "lado"
		corpo.flip_h = direcao_vista.x < 0.0
	elif direcao_vista.y < 0.0:
		sufixo = "cima"
		corpo.flip_h = false
	else:
		corpo.flip_h = false
	var nome := "parado_" + sufixo
	match estado:
		Situacao.MORTO:
			nome = "morte"
		Situacao.ESQUIVANDO:
			nome = "esquiva_" + sufixo
		Situacao.ATINGIDO:
			nome = "dano_" + sufixo
		_:
			if velocity.length() > 12.0:
				nome = "correr_" + sufixo
				_passo -= delta
				if _passo <= 0.0:
					_passo = 0.27
					Audio.tocar(&"passo", global_position, 0.12)
					Efeitos.poeira(global_position, 1)
	if corpo.animation != nome:
		corpo.play(nome)
	# Arma: atualiza pose e decide se fica atrás do corpo
	var fase := 0
	var progresso := 0.0
	if estado == Situacao.ATACANDO and _golpe:
		fase = int(_fase)
		var total := [_golpe.antecipacao, _golpe.ativo, _golpe.recuperacao][fase] as float
		progresso = 1.0 - clampf(_tempo_fase / maxf(total, 0.001), 0.0, 1.0)
	arma_visual.atualizar(delta, fase, progresso, mira, direcao_vista, clampf(_carga / arma.carga_pesado, 0.0, 1.0))
	arma_visual.visible = estado != Situacao.MORTO and estado != Situacao.ESQUIVANDO
	var atras := arma_visual.atras_do_corpo()
	if atras and arma_visual.get_index() > corpo.get_index():
		move_child(arma_visual, corpo.get_index())
	elif not atras and arma_visual.get_index() < corpo.get_index():
		move_child(arma_visual, corpo.get_index())
