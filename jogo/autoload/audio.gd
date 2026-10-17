extends Node
## Barramentos, efeitos sonoros (com variações e variação de tom) e música em camadas
## (exploração + combate tocando sincronizadas, com transição de volume).

const PASTA_SFX := "res://audio/sfx/"
const PASTA_MUSICA := "res://audio/musica/"
const TAMANHO_POOL := 28
const SILENCIO_DB := -60.0

## id → lista de variações (ex.: &"pa_varrida" → [pa_varrida_1, pa_varrida_2]).
var _sfx: Dictionary[StringName, Array] = {}
var _pool: Array[AudioStreamPlayer2D] = []
var _pool_ui: Array[AudioStreamPlayer] = []
var _proximo := 0
var _proximo_ui := 0
## Último momento (ms) em que cada som tocou, para evitar empilhamento no mesmo quadro.
var _ultimo_toque: Dictionary[StringName, int] = {}

var _camada_exploracao: AudioStreamPlayer
var _camada_combate: AudioStreamPlayer
var _musica_atual: StringName = &""
var _tween_musica: Tween
var combate_ativo := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_barramentos()
	Config.aplicar_tudo()
	_carregar_sfx()
	for i in TAMANHO_POOL:
		var p := AudioStreamPlayer2D.new()
		p.bus = &"Efeitos"
		p.max_distance = 900.0
		p.attenuation = 0.6
		p.panning_strength = 0.6
		add_child(p)
		_pool.append(p)
	for i in 8:
		var u := AudioStreamPlayer.new()
		u.bus = &"Efeitos"
		add_child(u)
		_pool_ui.append(u)
	_camada_exploracao = _criar_tocador_musica()
	_camada_combate = _criar_tocador_musica()


func _criar_barramentos() -> void:
	for nome: StringName in [&"Musica", &"Efeitos"]:
		if AudioServer.get_bus_index(nome) >= 0:
			continue
		AudioServer.add_bus()
		var indice := AudioServer.bus_count - 1
		AudioServer.set_bus_name(indice, nome)
		AudioServer.set_bus_send(indice, &"Master")
	# Um leve eco nas catacumbas dá profundidade aos efeitos sem embolar a mixagem.
	var efeitos := AudioServer.get_bus_index(&"Efeitos")
	if AudioServer.get_bus_effect_count(efeitos) == 0:
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.55
		reverb.damping = 0.6
		reverb.wet = 0.12
		reverb.dry = 1.0
		AudioServer.add_bus_effect(efeitos, reverb)
	var master := AudioServer.get_bus_index(&"Master")
	if AudioServer.get_bus_effect_count(master) == 0:
		var limitador := AudioEffectHardLimiter.new()
		limitador.ceiling_db = -0.5
		AudioServer.add_bus_effect(master, limitador)


func _criar_tocador_musica() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = &"Musica"
	p.volume_db = SILENCIO_DB
	add_child(p)
	return p


func _carregar_sfx() -> void:
	if not DirAccess.dir_exists_absolute(PASTA_SFX):
		return
	for arquivo in ResourceLoader.list_directory(PASTA_SFX):
		if not (arquivo.ends_with(".wav") or arquivo.ends_with(".ogg")):
			continue
		var base := arquivo.get_basename()
		var partes := base.rsplit("_", true, 1)
		var id := StringName(base)
		if partes.size() == 2 and partes[1].is_valid_int():
			id = StringName(partes[0])
		var stream := load(PASTA_SFX + arquivo) as AudioStream
		if stream == null:
			continue
		if not _sfx.has(id):
			_sfx[id] = []
		_sfx[id].append(stream)


func existe(id: StringName) -> bool:
	return _sfx.has(id)


## Toca um efeito sonoro. Com posição, o som é posicional (panorâmico); sem, é de interface.
func tocar(id: StringName, posicao: Vector2 = Vector2.INF, variacao_tom: float = 0.08, volume_db: float = 0.0) -> void:
	var variacoes: Array = _sfx.get(id, [])
	if variacoes.is_empty():
		return
	var agora := Time.get_ticks_msec()
	if agora - int(_ultimo_toque.get(id, -1000)) < 30:
		return
	_ultimo_toque[id] = agora
	var stream: AudioStream = variacoes[randi() % variacoes.size()]
	var tom := 1.0 + randf_range(-variacao_tom, variacao_tom)
	if posicao == Vector2.INF:
		var u := _pool_ui[_proximo_ui]
		_proximo_ui = (_proximo_ui + 1) % _pool_ui.size()
		u.stream = stream
		u.pitch_scale = tom
		u.volume_db = volume_db
		u.play()
		return
	var p := _pool[_proximo]
	_proximo = (_proximo + 1) % _pool.size()
	p.stream = stream
	p.pitch_scale = tom
	p.volume_db = volume_db
	p.global_position = posicao
	p.play()


## Começa a música de uma região (camadas <id>_exploracao e <id>_combate).
func tocar_musica(id: StringName) -> void:
	if id == _musica_atual:
		return
	_musica_atual = id
	var exploracao := _carregar_musica("%s_exploracao" % id)
	var combate := _carregar_musica("%s_combate" % id)
	_camada_exploracao.stream = exploracao
	_camada_combate.stream = combate
	if exploracao:
		_camada_exploracao.play()
	if combate:
		_camada_combate.play()
	combate_ativo = false
	_transicionar(0.0, SILENCIO_DB, 2.5)


func parar_musica(duracao: float = 1.0) -> void:
	_musica_atual = &""
	_transicionar(SILENCIO_DB, SILENCIO_DB, duracao)
	# Depois do esmaecimento, para de fato (uma nova música mata este tween antes).
	_tween_musica.chain().tween_callback(_parar_tocadores_musica)


func _parar_tocadores_musica() -> void:
	_camada_exploracao.stop()
	_camada_combate.stop()


## Para todo som (ao fechar o jogo). A reprodução só é liberada pelo servidor de áudio
## alguns quadros depois — quem fecha o jogo espera um instante antes de sair.
func silenciar_tudo() -> void:
	_musica_atual = &""
	if _tween_musica:
		_tween_musica.kill()
	_parar_tocadores_musica()
	for p in _pool:
		p.stop()
	for u in _pool_ui:
		u.stop()


func definir_combate(ativo: bool) -> void:
	if ativo == combate_ativo or _musica_atual == &"":
		return
	combate_ativo = ativo
	if ativo:
		_transicionar(-6.0, 0.0, 0.6)
	else:
		_transicionar(0.0, SILENCIO_DB, 3.0)


func _transicionar(alvo_exploracao: float, alvo_combate: float, duracao: float) -> void:
	if _tween_musica:
		_tween_musica.kill()
	_tween_musica = create_tween().set_parallel()
	_tween_musica.tween_property(_camada_exploracao, ^"volume_db", alvo_exploracao, duracao)
	_tween_musica.tween_property(_camada_combate, ^"volume_db", alvo_combate, duracao)


func _carregar_musica(nome: String) -> AudioStream:
	for ext in [".ogg", ".wav"]:
		var caminho: String = PASTA_MUSICA + nome + ext
		if ResourceLoader.exists(caminho):
			var stream := load(caminho) as AudioStream
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			elif stream is AudioStreamWAV:
				var wav := stream as AudioStreamWAV
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				wav.loop_end = int(wav.get_length() * wav.mix_rate)
			return stream
	return null
