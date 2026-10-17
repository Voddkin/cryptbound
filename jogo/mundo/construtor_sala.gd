class_name ConstrutorSala
extends RefCounted
## Monta uma Sala a partir de uma DefinicaoSala: camadas de chão/sombra/paredes, objetos de
## cenário, luzes, passagens, altares, escada e a grade de navegação. Determinístico pela semente.

const T := 16
# Tipos de face (paredes em vista 3/4: a face frontal tem até 2 tiles de altura)
const SEM_FACE := 0
const FACE_BAIXO := 1
const FACE_CIMA := 2
const FACE_UNICA := 3
const N := 1
const NE := 2
const L := 4
const SE := 8
const S := 16
const SO := 32
const O := 64
const NO := 128
const VIZINHOS := [[N, Vector2i(0, -1)], [NE, Vector2i(1, -1)], [L, Vector2i(1, 0)], [SE, Vector2i(1, 1)],
		[S, Vector2i(0, 1)], [SO, Vector2i(-1, 1)], [O, Vector2i(-1, 0)], [NO, Vector2i(-1, -1)]]

const COR_VELA := Color(1.0, 0.7, 0.4)


static func carregar(caminho: String, semente: int, itens: Array[ItemDados] = []) -> Sala:
	var def := DefinicaoSala.de_arquivo(caminho)
	if not def.valida():
		push_error("Sala inválida %s: %s" % [caminho, "; ".join(def.erros)])
		return null
	return construir(def, semente, itens)


static func construir(def: DefinicaoSala, semente: int, itens: Array[ItemDados] = []) -> Sala:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var ts := TilesetCatacumbas.obter()
	var meta := TilesetCatacumbas.meta()
	var sala := Sala.new()
	sala.name = "Sala_%s" % def.id
	sala.definicao = def
	sala.semente = semente

	sala.chao = _camada(ts, "Chao", -20)
	sala.add_child(sala.chao)
	sala.manchas = ManchasChao.new()
	sala.manchas.name = "Manchas"
	sala.manchas.z_index = -19
	sala.manchas.configurar(Rect2i(0, 0, def.largura * T, def.altura * T))
	sala.add_child(sala.manchas)
	sala.sombra = _camada(ts, "Sombra", -18)
	sala.add_child(sala.sombra)
	sala.decalques = Node2D.new()
	sala.decalques.name = "Decalques"
	sala.decalques.z_index = -17
	sala.add_child(sala.decalques)
	sala.mundo = Node2D.new()
	sala.mundo.name = "Mundo"
	sala.mundo.y_sort_enabled = true
	sala.add_child(sala.mundo)
	sala.paredes = _camada(ts, "Paredes", 0)
	sala.paredes.y_sort_enabled = true
	sala.mundo.add_child(sala.paredes)

	var pesos_chao: Array = meta["chao"]["pesos"]
	var linhas_face: Dictionary = meta["face"]["linhas"]
	var pesos_face: Dictionary = meta["face"]["pesos"]
	var indice_altar := 0
	var escada_feita := false

	for y in def.altura:
		for x in def.largura:
			var c := Vector2i(x, y)
			var ch := def.char_em(c)
			if ch == DefinicaoSala.PAREDE:
				_colocar_parede(sala, def, c, rng, linhas_face, pesos_face)
				continue
			sala.chao.set_cell(c, TilesetCatacumbas.FONTE_CHAO, TilesetCatacumbas.coord_chao(_sortear(rng, pesos_chao)))
			var mascara := _mascara(def, c)
			if mascara != 0:
				sala.sombra.set_cell(c, TilesetCatacumbas.FONTE_SOMBRA, TilesetCatacumbas.coord_mascara(mascara))
			var base := sala.centro_celula(c) + Vector2(0, T * 0.5 - 1)
			match ch:
				"r", "R":
					sala.pontos_inimigos.append({"tipo": &"ressequido", "onda": 1 if ch == "r" else 2, "celula": c})
				"l", "L":
					sala.pontos_inimigos.append({"tipo": &"lamuriante", "onda": 1 if ch == "l" else 2, "celula": c})
				"c":
					_velas(sala, base, rng)
				"C":
					_candelabro(sala, base, rng)
				"k":
					_obstaculo(sala, "res://arte/props/cranios.png", base, Vector2(14, 8))
				"u":
					_obstaculo(sala, "res://arte/props/urna.png", base, Vector2(8, 5))
				"t":
					_obstaculo(sala, "res://arte/props/caixao.png", base + Vector2(0, 4), Vector2(12, 14))
				"o":
					_decalque(sala, "res://arte/props/ossada_%d.png" % rng.randi_range(1, 3), sala.centro_celula(c), rng)
				"x":
					_decalque(sala, "res://arte/props/raizes_chao.png", sala.centro_celula(c), rng)
				"A":
					var altar := Altar.new()
					altar.position = base
					if indice_altar < itens.size():
						altar.item = itens[indice_altar]
					indice_altar += 1
					sala.altares.append(altar)
					sala.mundo.add_child(altar)
				"E":
					if not escada_feita:
						escada_feita = true
						var escada := Escada.new()
						escada.position = Vector2(c * T)
						sala.escada = escada
						sala.decalques.add_child(escada)
				".", ",":
					var chance := 0.035 if ch == "." else 0.4
					if rng.randf() < chance:
						var arquivo := "res://arte/props/ossada_%d.png" % rng.randi_range(1, 3) if rng.randf() < 0.7 else "res://arte/props/raizes_chao.png"
						_decalque(sala, arquivo, sala.centro_celula(c), rng)

	for simbolo in DefinicaoSala.PORTAS:
		var celulas := def.celulas_com(simbolo)
		if celulas.is_empty():
			continue
		var porta := Porta.new()
		porta.name = "Porta_%s" % simbolo
		porta.simbolo = simbolo
		porta.direcao = DefinicaoSala.DIRECOES[simbolo]
		porta.celulas = celulas
		porta.eh_saida = simbolo == def.saida
		sala.portas[simbolo] = porta
		sala.mundo.add_child(porta)

	sala.astar = _grade(def)
	sala.conectar_portas()
	return sala


static func _camada(ts: TileSet, nome: String, z: int) -> TileMapLayer:
	var camada := TileMapLayer.new()
	camada.name = nome
	camada.tile_set = ts
	camada.z_index = z
	return camada


static func _sortear(rng: RandomNumberGenerator, pesos: Array) -> int:
	var total := 0.0
	for p: Variant in pesos:
		total += float(p)
	var r := rng.randf() * total
	for i in pesos.size():
		r -= float(pesos[i])
		if r <= 0.0:
			return i
	return pesos.size() - 1


static func _mascara(def: DefinicaoSala, c: Vector2i) -> int:
	var m := 0
	for v: Array in VIZINHOS:
		if def.eh_parede(c + (v[1] as Vector2i)):
			m |= int(v[0])
	return m


static func tipo_face(def: DefinicaoSala, c: Vector2i) -> int:
	if not def.eh_parede(c):
		return SEM_FACE
	var abaixo := c + Vector2i.DOWN
	if not def.eh_parede(abaixo) and abaixo.y < def.altura:
		return FACE_BAIXO if def.eh_parede(c + Vector2i.UP) else FACE_UNICA
	if abaixo.y < def.altura and tipo_face(def, abaixo) == FACE_BAIXO:
		return FACE_CIMA
	return SEM_FACE


static func _colocar_parede(sala: Sala, def: DefinicaoSala, c: Vector2i, rng: RandomNumberGenerator, linhas_face: Dictionary, pesos_face: Dictionary) -> void:
	var tipo := tipo_face(def, c)
	if tipo == SEM_FACE:
		sala.paredes.set_cell(c, TilesetCatacumbas.FONTE_TOPO, TilesetCatacumbas.coord_mascara(_mascara(def, c)))
		return
	var chave: String = {FACE_BAIXO: "baixo", FACE_CIMA: "cima", FACE_UNICA: "unica"}[tipo]
	var linhas: Array = linhas_face[chave]
	var linha := int(linhas[_sortear(rng, pesos_face[chave])])
	var esquerda := tipo_face(def, c + Vector2i.LEFT) != tipo
	var direita := tipo_face(def, c + Vector2i.RIGHT) != tipo
	var coluna := (1 if esquerda else 0) + (2 if direita else 0)
	sala.paredes.set_cell(c, TilesetCatacumbas.FONTE_FACE, Vector2i(coluna, linha))


static func _velas(sala: Sala, base: Vector2, rng: RandomNumberGenerator) -> void:
	var no := Node2D.new()
	no.position = base
	var sprite := BibliotecaSprites.criar_animado("res://arte/props/velas.json", &"acesas")
	sprite.frame = rng.randi_range(0, 2)
	sprite.speed_scale = rng.randf_range(0.8, 1.2)
	no.add_child(sprite)
	var luz := LuzTremulante.new(COR_VELA, 0.85, 1.25, rng.randi())
	luz.position = Vector2(0, -10)
	no.add_child(luz)
	sala.mundo.add_child(no)


static func _candelabro(sala: Sala, base: Vector2, rng: RandomNumberGenerator) -> void:
	var no := StaticBody2D.new()
	no.position = base
	no.collision_layer = 1
	no.collision_mask = 0
	var sprite := BibliotecaSprites.criar_animado("res://arte/props/candelabro.json", &"aceso")
	sprite.frame = rng.randi_range(0, 2)
	no.add_child(sprite)
	_forma(no, Vector2(6, 4), Vector2(0, -2))
	var luz := LuzTremulante.new(COR_VELA, 1.05, 1.7, rng.randi())
	luz.position = Vector2(0, -22)
	no.add_child(luz)
	sala.mundo.add_child(no)


static func _obstaculo(sala: Sala, png: String, base: Vector2, tamanho: Vector2) -> void:
	var no := StaticBody2D.new()
	no.position = base
	no.collision_layer = 1
	no.collision_mask = 0
	no.add_child(BibliotecaSprites.criar_estatico(png))
	_forma(no, tamanho, Vector2(0, -tamanho.y * 0.5))
	sala.mundo.add_child(no)


static func _forma(corpo: Node2D, tamanho: Vector2, posicao: Vector2) -> void:
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = tamanho
	forma.shape = ret
	forma.position = posicao
	corpo.add_child(forma)


static func _decalque(sala: Sala, png: String, centro: Vector2, rng: RandomNumberGenerator) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(png) as Texture2D
	sprite.position = centro + Vector2(rng.randi_range(-3, 3), rng.randi_range(-3, 3))
	sprite.flip_h = rng.randf() < 0.5
	sprite.modulate = Color(1, 1, 1, 0.85)
	sala.decalques.add_child(sprite)


static func _grade(def: DefinicaoSala) -> AStarGrid2D:
	var a := AStarGrid2D.new()
	a.region = Rect2i(0, 0, def.largura, def.altura)
	a.cell_size = Vector2(T, T)
	a.offset = Vector2(T, T) * 0.5
	a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	a.update()
	for y in def.altura:
		for x in def.largura:
			var c := Vector2i(x, y)
			if not def.andavel(c):
				a.set_point_solid(c, true)
	return a
