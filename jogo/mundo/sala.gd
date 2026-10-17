class_name Sala
extends Node2D
## Uma sala montada a partir de uma DefinicaoSala. Conduz o encontro: tranca as passagens,
## ergue as ondas de inimigos, libera a sala quando todos caem e oferece navegação (A*) e
## linha de visão aos inimigos.

signal limpa
signal saida_atravessada
signal descida_pedida

enum Situacao { OCIOSA, AGUARDANDO_ENTRADA, COMBATE, LIMPA }

const T := 16

var definicao: DefinicaoSala
var semente := 0
var estado: Situacao = Situacao.OCIOSA

# Camadas (montadas pelo ConstrutorSala)
var chao: TileMapLayer
var sombra: TileMapLayer
var decalques: Node2D
var manchas: ManchasChao
var mundo: Node2D
var paredes: TileMapLayer
var portas: Dictionary[String, Porta] = {}
var altares: Array[Altar] = []
var escada: Escada
var astar: AStarGrid2D
## Cada ponto: {"tipo": &"ressequido", "onda": 1, "celula": Vector2i}
var pontos_inimigos: Array[Dictionary] = []

var onda_atual := 0
var vivos: Array[Node2D] = []
var _jogador: Node2D
var _rng := RandomNumberGenerator.new()
var _ultima_morte := Vector2.ZERO


func largura_px() -> float:
	return definicao.largura * T


func altura_px() -> float:
	return definicao.altura * T


func retangulo() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(largura_px(), altura_px()))


func centro_celula(c: Vector2i) -> Vector2:
	return Vector2(c * T) + Vector2(T, T) * 0.5


func celula_de(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))


func andavel(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= definicao.largura or c.y >= definicao.altura:
		return false
	return not astar.is_point_solid(c)


func ondas_totais() -> int:
	var maior := 0
	for p in pontos_inimigos:
		maior = maxi(maior, int(p["onda"]))
	return maior


## Onde a Coveira aparece ao entrar nesta sala.
func posicao_chegada() -> Vector2:
	if definicao.entrada != "":
		return centro_celula(definicao.celula_dentro_da_porta(definicao.entrada)) + Vector2(0, 4)
	var inicio := definicao.celulas_com("@")
	return centro_celula(inicio[0]) + Vector2(0, 4) if not inicio.is_empty() else retangulo().get_center()


## Caminho (pontos em pixels) de `de` até `para`, contornando paredes e objetos.
func caminho(de: Vector2, para: Vector2) -> PackedVector2Array:
	# Objetos (caixões, crânios) colidem só com parte da célula: quem encosta neles pode
	# estar numa célula sólida da grade. Nesse caso usa a vizinha andável mais próxima.
	var a := _andavel_mais_proxima(de)
	var b := _andavel_mais_proxima(para)
	if a.x < 0 or b.x < 0:
		return PackedVector2Array()
	return astar.get_point_path(a, b, true)


func _andavel_mais_proxima(p: Vector2) -> Vector2i:
	var c := celula_de(p)
	if andavel(c):
		return c
	var melhor := Vector2i(-1, -1)
	var melhor_dist := INF
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var v := c + Vector2i(dx, dy)
			if andavel(v) and centro_celula(v).distance_squared_to(p) < melhor_dist:
				melhor = v
				melhor_dist = centro_celula(v).distance_squared_to(p)
	return melhor


## Linha de visão em grade (paredes e objetos altos bloqueiam). As células das duas pontas
## não contam: quem encosta num objeto baixo pode estar com os pés numa célula "sólida".
func visao_livre(de: Vector2, para: Vector2) -> bool:
	var celula_de_origem := celula_de(de)
	var celula_de_destino := celula_de(para)
	var dist := de.distance_to(para)
	var passos := int(ceil(dist / 4.0))
	for i in range(1, passos):
		var c := celula_de(de.lerp(para, float(i) / passos))
		if c == celula_de_origem or c == celula_de_destino:
			continue
		if definicao.eh_parede(c) or (astar.is_in_boundsv(c) and astar.is_point_solid(c) and not _eh_porta(c)):
			return false
	return true


func _eh_porta(c: Vector2i) -> bool:
	return DefinicaoSala.PORTAS.has(definicao.char_em(c))


## Célula andável aleatória longe de `evitar` (para reforços de profundidade).
func celula_livre_aleatoria(evitar: Vector2, distancia_minima: float) -> Vector2i:
	for tentativa in 60:
		var c := Vector2i(_rng.randi_range(1, definicao.largura - 2), _rng.randi_range(1, definicao.altura - 2))
		if definicao.char_em(c) in [".", ","] and andavel(c) and centro_celula(c).distance_to(evitar) >= distancia_minima:
			return c
	return Vector2i(-1, -1)


func iniciar(jogador: Node2D) -> void:
	_jogador = jogador
	_rng.seed = semente
	Eventos.sala_entrou.emit(self)
	if definicao.nome != "":
		Eventos.sala_nomeada.emit(definicao.nome)
	if ondas_totais() > 0:
		estado = Situacao.AGUARDANDO_ENTRADA
	else:
		_marcar_limpa(false)


func _physics_process(_delta: float) -> void:
	if estado != Situacao.AGUARDANDO_ENTRADA or _jogador == null:
		return
	# Só tranca quando a Coveira já está toda dentro (longe da passagem de entrada).
	var c := celula_de(_jogador.global_position)
	if _eh_porta(c):
		return
	var entrada_c := definicao.celula_dentro_da_porta(definicao.entrada) if definicao.entrada != "" else c
	if definicao.entrada != "" and centro_celula(entrada_c).distance_to(_jogador.global_position) < 18.0:
		return
	_comecar_combate()


func _comecar_combate() -> void:
	estado = Situacao.COMBATE
	for porta: Porta in portas.values():
		porta.trancar()
		_definir_porta_solida(porta, true)
	Audio.tocar(&"porta_fechar", _jogador.global_position)
	Audio.definir_combate(true)
	Eventos.combate_iniciou.emit(self)
	Eventos.mensagem.emit(Textos.t("hud.portas_trancadas"), 1.6)
	_proxima_onda()


func _proxima_onda() -> void:
	onda_atual += 1
	Eventos.onda_iniciou.emit(self, onda_atual)
	if onda_atual > 1:
		Eventos.mensagem.emit(Textos.t("hud.onda"), 1.4)
	var celulas: Array[Dictionary] = []
	for p in pontos_inimigos:
		if int(p["onda"]) == onda_atual:
			celulas.append(p)
	# Reforços por profundidade: +1 Ressequido na primeira onda a cada profundidade além da 1ª.
	if onda_atual == 1:
		for i in mini(Jogo.profundidade - 1, 3):
			var c := celula_livre_aleatoria(_jogador.global_position, 96.0)
			if c.x >= 0:
				celulas.append({"tipo": &"ressequido", "onda": 1, "celula": c})
	var atraso := 0.0
	for p in celulas:
		_erguer(p["tipo"], centro_celula(p["celula"]) + Vector2(0, 4), atraso)
		atraso += 0.12


func _erguer(tipo: StringName, posicao: Vector2, atraso: float) -> void:
	var inimigo := FabricaInimigos.criar(tipo)
	if inimigo == null:
		return
	inimigo.sala = self
	inimigo.position = posicao
	inimigo.atraso_surgimento = atraso
	vivos.append(inimigo)
	inimigo.morreu.connect(_ao_morrer)
	mundo.add_child(inimigo)


func _ao_morrer(inimigo: Node2D) -> void:
	_ultima_morte = inimigo.global_position
	vivos.erase(inimigo)
	if not vivos.is_empty() or estado != Situacao.COMBATE:
		return
	if onda_atual < ondas_totais():
		get_tree().create_timer(0.9, false).timeout.connect(_proxima_onda)
	else:
		_marcar_limpa(true)


func _marcar_limpa(apos_combate: bool) -> void:
	estado = Situacao.LIMPA
	for porta: Porta in portas.values():
		porta.destrancar()
		_definir_porta_solida(porta, false)
	if apos_combate:
		Audio.tocar(&"porta_abrir", _jogador.global_position)
		Audio.tocar(&"sala_limpa")
		Audio.definir_combate(false)
		Eventos.mensagem.emit(Textos.t("hud.sala_limpa"), 1.8)
		Eventos.sala_limpa.emit(self)
		_recompensa()
	limpa.emit()


func _recompensa() -> void:
	# Um toco de vela às vezes: mais provável quando a Coveira está ferida.
	var chance := 0.25 + (0.35 if Jogo.velas < Jogo.velas_max else 0.0)
	if _rng.randf() < chance:
		var pos := _ultima_morte if _ultima_morte != Vector2.ZERO else retangulo().get_center()
		mundo.add_child(Coletavel.criar(Coletavel.Tipo.VELA, 1, pos, Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-30, 30))))


func _definir_porta_solida(porta: Porta, solida: bool) -> void:
	for c in porta.celulas:
		astar.set_point_solid(c, solida)


func conectar_portas() -> void:
	for porta: Porta in portas.values():
		porta.atravessada.connect(func(_p: Porta) -> void: saida_atravessada.emit())
	for altar in altares:
		altar.escolhido.connect(_ao_escolher_altar)
	if escada:
		escada.descer.connect(func() -> void: descida_pedida.emit())


func _ao_escolher_altar(escolhido: Altar) -> void:
	for altar in altares:
		if altar != escolhido:
			altar.desfazer()
	Eventos.item_em_foco.emit(null)
