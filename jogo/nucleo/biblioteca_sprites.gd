class_name BibliotecaSprites
extends RefCounted
## Lê os metadados JSON gerados por ferramentas/arte/ e monta SpriteFrames (com cache).
## Convenção: a origem do sprite (pés) fica na posição do nó; `offset = -origem`.

static var _cache: Dictionary[String, Dictionary] = {}


static func carregar(caminho_json: String) -> Dictionary:
	if _cache.has(caminho_json):
		return _cache[caminho_json]
	var texto := FileAccess.get_file_as_string(caminho_json)
	var meta: Variant = JSON.parse_string(texto)
	if typeof(meta) != TYPE_DICTIONARY:
		push_error("Metadados de sprite inválidos: %s" % caminho_json)
		return {}
	var textura := load(caminho_json.get_base_dir().path_join(meta["imagem"])) as Texture2D
	var tamanho := Vector2i(int(meta["quadro"][0]), int(meta["quadro"][1]))
	var colunas := int(meta["colunas"])
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for nome: String in meta["animacoes"]:
		var anim: Dictionary = meta["animacoes"][nome]
		frames.add_animation(nome)
		frames.set_animation_speed(nome, float(anim["fps"]))
		frames.set_animation_loop(nome, bool(anim["loop"]))
		for indice: Variant in anim["quadros"]:
			var i := int(indice)
			var atlas := AtlasTexture.new()
			atlas.atlas = textura
			atlas.region = Rect2((i % colunas) * tamanho.x, (i / colunas) * tamanho.y, tamanho.x, tamanho.y)
			frames.add_frame(nome, atlas)
	var origem := Vector2(float(meta["origem"][0]), float(meta["origem"][1]))
	var pontos: Dictionary[String, Vector2] = {}
	for nome: String in meta.get("pontos", {}):
		var p: Array = meta["pontos"][nome]
		# Pontos relativos à origem (pés), prontos para usar como posição local.
		pontos[nome] = Vector2(float(p[0]), float(p[1])) - origem
	var resultado := {"frames": frames, "origem": origem, "tamanho": tamanho, "pontos": pontos}
	_cache[caminho_json] = resultado
	return resultado


## Cria um AnimatedSprite2D já posicionado com os pés na origem do nó.
static func criar_animado(caminho_json: String, animacao: StringName = &"") -> AnimatedSprite2D:
	var dados := carregar(caminho_json)
	var sprite := AnimatedSprite2D.new()
	if dados.is_empty():
		return sprite
	sprite.sprite_frames = dados["frames"]
	sprite.centered = false
	sprite.offset = -dados["origem"]
	if animacao != &"":
		sprite.play(animacao)
	elif sprite.sprite_frames.get_animation_names().size() > 0:
		sprite.play(sprite.sprite_frames.get_animation_names()[0])
	return sprite


static func ponto(caminho_json: String, nome: String) -> Vector2:
	var dados := carregar(caminho_json)
	if dados.is_empty():
		return Vector2.ZERO
	return dados["pontos"].get(nome, Vector2.ZERO)


## Sprite estático com a base (pés) na origem do nó.
static func criar_estatico(caminho_png: String, base_y: float = -1.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(caminho_png) as Texture2D
	sprite.centered = false
	if sprite.texture:
		var tam := sprite.texture.get_size()
		sprite.offset = Vector2(-floorf(tam.x / 2.0), -(tam.y if base_y < 0.0 else base_y))
	return sprite
