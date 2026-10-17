class_name TilesetCatacumbas
extends RefCounted
## TileSet das Catacumbas montado em código a partir dos atlas gerados
## (arte/tiles/catacumbas/*.png + tiles.json). Ordem obrigatória no Godot 4.7:
## camada de física → add_source → create_tile → polígonos de colisão.

const PASTA := "res://arte/tiles/catacumbas/"
const T := 16
const FONTE_CHAO := 0
const FONTE_TOPO := 1
const FONTE_FACE := 2
const FONTE_SOMBRA := 3
## Camada de física "mundo" (bit 1).
const CAMADA_MUNDO := 1

static var _tileset: TileSet
static var _meta: Dictionary = {}


static func obter() -> TileSet:
	if _tileset != null:
		return _tileset
	_meta = JSON.parse_string(FileAccess.get_file_as_string(PASTA + "tiles.json"))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, CAMADA_MUNDO)
	ts.set_physics_layer_collision_mask(0, 0)
	_adicionar_atlas(ts, FONTE_CHAO, "chao.png", Vector2i(4, 4), false)
	_adicionar_atlas(ts, FONTE_TOPO, "topo.png", Vector2i(16, 16), true)
	var linhas_face := 0
	for tipo: String in _meta["face"]["linhas"]:
		linhas_face += (_meta["face"]["linhas"][tipo] as Array).size()
	_adicionar_atlas(ts, FONTE_FACE, "face.png", Vector2i(4, linhas_face), true)
	_adicionar_atlas(ts, FONTE_SOMBRA, "sombra.png", Vector2i(16, 16), false)
	_tileset = ts
	return ts


static func meta() -> Dictionary:
	obter()
	return _meta


static func _adicionar_atlas(ts: TileSet, id: int, arquivo: String, grade: Vector2i, solido: bool) -> void:
	var fonte := TileSetAtlasSource.new()
	fonte.texture = load(PASTA + arquivo) as Texture2D
	fonte.texture_region_size = Vector2i(T, T)
	ts.add_source(fonte, id)
	var meio := T / 2.0
	var quadrado := PackedVector2Array([Vector2(-meio, -meio), Vector2(meio, -meio), Vector2(meio, meio), Vector2(-meio, meio)])
	for y in grade.y:
		for x in grade.x:
			var c := Vector2i(x, y)
			fonte.create_tile(c)
			if solido:
				var dados := fonte.get_tile_data(c, 0)
				dados.add_collision_polygon(0)
				dados.set_collision_polygon_points(0, 0, quadrado)


## Coordenada no atlas de chão a partir de um índice de variante (0..15).
static func coord_chao(indice: int) -> Vector2i:
	return Vector2i(indice % 4, indice / 4)


static func coord_mascara(mascara: int) -> Vector2i:
	return Vector2i(mascara % 16, mascara / 16)
