class_name Fontes
extends RefCounted
## Fontes bitmap do jogo, geradas por ferramentas/arte/gerar_fontes.py.
## Use sempre os tamanhos nativos (ou múltiplos inteiros) para manter os pixels nítidos.

const TAMANHO_TITULO := 21
const TAMANHO_TEXTO := 19
const TAMANHO_PEQUENA := 11

static var _cache: Dictionary[String, Font] = {}


static func titulo() -> Font:
	return _carregar("res://fontes/jacquard12.fnt")


static func texto() -> Font:
	return _carregar("res://fontes/jersey10.fnt")


static func pequena() -> Font:
	return _carregar("res://fontes/micro5.fnt")


static func _carregar(caminho: String) -> Font:
	if _cache.has(caminho):
		return _cache[caminho]
	var fonte: Font = null
	if ResourceLoader.exists(caminho):
		fonte = load(caminho) as Font
	if fonte is FontFile:
		# Fontes bitmap: tamanhos múltiplos do nativo escalam em passos inteiros (pixels nítidos).
		(fonte as FontFile).fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	if fonte == null:
		fonte = ThemeDB.fallback_font
	_cache[caminho] = fonte
	return fonte
