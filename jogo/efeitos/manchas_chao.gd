class_name ManchasChao
extends Sprite2D
## Camada de manchas permanentes da sala (sangue, cera derretida). Pintada pixel a pixel
## numa imagem do tamanho da sala; a textura só é reenviada quando algo mudou.

var _imagem: Image
var _textura: ImageTexture
var _origem := Vector2i.ZERO
var _sujo := false


func configurar(retangulo: Rect2i) -> void:
	_origem = retangulo.position
	_imagem = Image.create_empty(maxi(retangulo.size.x, 1), maxi(retangulo.size.y, 1), false, Image.FORMAT_RGBA8)
	_textura = ImageTexture.create_from_image(_imagem)
	texture = _textura
	centered = false
	position = Vector2(_origem)
	_sujo = false


func manchar(posicao_global: Vector2, cor: Color, raio: int = 0) -> void:
	if _imagem == null:
		return
	var local := Vector2i(posicao_global.floor()) - _origem
	for dy in range(-raio, raio + 1):
		for dx in range(-raio, raio + 1):
			if raio > 0 and dx * dx + dy * dy > raio * raio:
				continue
			var p := local + Vector2i(dx, dy)
			if p.x < 0 or p.y < 0 or p.x >= _imagem.get_width() or p.y >= _imagem.get_height():
				continue
			var atual := _imagem.get_pixelv(p)
			var nova := cor
			nova.a = clampf(atual.a + cor.a * 0.85, 0.0, 0.92)
			if atual.a > 0.0:
				nova = Color(atual.lerp(cor, 0.5), nova.a)
			_imagem.set_pixelv(p, nova)
	_sujo = true


func _process(_delta: float) -> void:
	if _sujo and _textura:
		_textura.update(_imagem)
		_sujo = false


func pixel(posicao_global: Vector2) -> Color:
	if _imagem == null:
		return Color(0, 0, 0, 0)
	var local := Vector2i(posicao_global.floor()) - _origem
	if local.x < 0 or local.y < 0 or local.x >= _imagem.get_width() or local.y >= _imagem.get_height():
		return Color(0, 0, 0, 0)
	return _imagem.get_pixelv(local)
