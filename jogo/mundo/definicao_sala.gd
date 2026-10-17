class_name DefinicaoSala
extends RefCounted
## Sala descrita em texto (dados/salas/<regiao>/<nome>.txt): cabeçalho "chave: valor",
## uma linha "---" e a grade. Legenda da grade:
##
##   #  parede              .  chão              ,  chão com mais detritos
##   ^ v < >  passagem (norte, sul, leste, oeste) — 2 células de largura
##   @  início da Coveira (salas sem porta de entrada)
##   r R  Ressequido (onda 1 / onda 2)      l L  Lamuriante (onda 1 / onda 2)
##   c  grupo de velas (luz)        C  candelabro (luz, bloqueia)
##   k  pilha de crânios (bloqueia) u  urna (bloqueia)        t  caixão (bloqueia)
##   o  ossada no chão              x  raízes no chão
##   A  altar de relíquia           E  escada de descida (bloco 2×2 de E)
##
## Cabeçalho: nome, tipo (inicio|combate|reliquia|descida|patamar), luz ("r g b"),
## entrada e saida (símbolo da passagem: ^ v < >).

const PAREDE := "#"
const PORTAS := ["^", "v", "<", ">"]
const BLOQUEIAM := ["#", "C", "k", "u", "t", "A"]
const VALIDOS := "#.,^v<>@rRlLcCkutoxAE"
const DIRECOES := {"^": Vector2i(0, -1), "v": Vector2i(0, 1), ">": Vector2i(1, 0), "<": Vector2i(-1, 0)}
const OPOSTA := {"^": "v", "v": "^", "<": ">", ">": "<"}

var id := ""
var nome := ""
var tipo := "combate"
var luz := Color(0.38, 0.34, 0.46)
var entrada := ""
var saida := ""
var linhas: PackedStringArray = []
var largura := 0
var altura := 0
var erros: Array[String] = []


static func de_arquivo(caminho: String) -> DefinicaoSala:
	var texto := FileAccess.get_file_as_string(caminho)
	var d := DefinicaoSala.de_texto(texto)
	d.id = caminho.get_file().get_basename()
	if texto.is_empty():
		d.erros.append("arquivo vazio ou inexistente: %s" % caminho)
	return d


static func de_texto(texto: String) -> DefinicaoSala:
	var d := DefinicaoSala.new()
	var partes := texto.replace("\r", "").split("\n---\n", false, 1)
	if partes.size() != 2:
		d.erros.append("falta a linha '---' separando cabeçalho e grade")
		return d
	for linha in partes[0].split("\n", false):
		var kv := linha.split(":", true, 1)
		if kv.size() != 2:
			continue
		var chave := kv[0].strip_edges()
		var valor := kv[1].strip_edges()
		match chave:
			"nome": d.nome = valor
			"tipo": d.tipo = valor
			"entrada": d.entrada = valor
			"saida": d.saida = valor
			"luz":
				var c := valor.split(" ", false)
				if c.size() == 3:
					d.luz = Color(float(c[0]), float(c[1]), float(c[2]))
	for linha in partes[1].split("\n", false):
		if linha.strip_edges() != "":
			d.linhas.append(linha.rstrip(" "))
	d.altura = d.linhas.size()
	d.largura = 0 if d.linhas.is_empty() else d.linhas[0].length()
	d._validar()
	return d


func valida() -> bool:
	return erros.is_empty()


func char_em(c: Vector2i) -> String:
	if c.x < 0 or c.y < 0 or c.y >= altura or c.x >= linhas[c.y].length():
		return PAREDE
	return linhas[c.y][c.x]


func eh_parede(c: Vector2i) -> bool:
	return char_em(c) == PAREDE


func andavel(c: Vector2i) -> bool:
	return not BLOQUEIAM.has(char_em(c))


func celulas_com(simbolo: String) -> Array[Vector2i]:
	var saida_lista: Array[Vector2i] = []
	for y in altura:
		for x in largura:
			if linhas[y][x] == simbolo:
				saida_lista.append(Vector2i(x, y))
	return saida_lista


## Célula de chão logo para dentro da passagem (onde a Coveira aparece ao chegar).
func celula_dentro_da_porta(simbolo: String) -> Vector2i:
	var celulas := celulas_com(simbolo)
	if celulas.is_empty():
		return Vector2i(-1, -1)
	var para_dentro: Vector2i = -DIRECOES[simbolo]
	var soma := Vector2.ZERO
	for c in celulas:
		soma += Vector2(c)
	var centro := soma / celulas.size()
	# Anda da passagem para dentro até achar chão comum.
	var c := Vector2i(roundi(centro.x), roundi(centro.y))
	for i in 8:
		if char_em(c) != simbolo and andavel(c):
			return c
		c += para_dentro
	return c


func _validar() -> void:
	if altura < 5 or largura < 5:
		erros.append("grade pequena demais (%dx%d)" % [largura, altura])
		return
	for y in altura:
		if linhas[y].length() != largura:
			erros.append("linha %d com largura %d (esperado %d)" % [y, linhas[y].length(), largura])
		for x in linhas[y].length():
			var ch := linhas[y][x]
			if not VALIDOS.contains(ch):
				erros.append("caractere desconhecido '%s' em (%d, %d)" % [ch, x, y])
			var na_borda := x == 0 or y == 0 or x == largura - 1 or y == altura - 1
			if na_borda and ch != PAREDE and not PORTAS.has(ch):
				erros.append("borda aberta em (%d, %d): '%s'" % [x, y, ch])
	if not erros.is_empty():
		return
	if tipo not in ["inicio", "combate", "reliquia", "descida", "patamar"]:
		erros.append("tipo desconhecido: %s" % tipo)
	for simbolo in [entrada, saida]:
		if simbolo != "" and celulas_com(simbolo).is_empty():
			erros.append("passagem '%s' declarada mas ausente da grade" % simbolo)
	for p in PORTAS:
		var n := celulas_com(p).size()
		if n > 0 and p != entrada and p != saida:
			erros.append("passagem '%s' na grade mas não declarada como entrada/saída" % p)
	if entrada == "" and celulas_com("@").size() != 1:
		erros.append("sala sem entrada precisa de exatamente um '@'")
	if tipo == "descida" and celulas_com("E").size() != 4:
		erros.append("sala de descida precisa de uma escada 2×2 (quatro 'E')")
	if tipo == "reliquia" and celulas_com("A").size() < 1:
		erros.append("sala de relíquia sem altar")
	if not erros.is_empty():
		return
	# Tudo que importa precisa ser alcançável a partir da chegada.
	var origem := celula_dentro_da_porta(entrada) if entrada != "" else celulas_com("@")[0]
	var alcancavel := _inundar(origem)
	var importantes: Array[Vector2i] = []
	for s in ["r", "R", "l", "L"]:
		importantes.append_array(celulas_com(s))
	if saida != "":
		importantes.append(celula_dentro_da_porta(saida))
	for c in celulas_com("E"):
		importantes.append(c)
	for c in celulas_com("A"):
		importantes.append(c + Vector2i(0, 1))
	for c in importantes:
		var alvo := c
		if char_em(c) == "E":
			# a escada não é andável no A*, mas precisa estar encostada em algo alcançável
			var vizinho_ok := false
			for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if alcancavel.has(c + d):
					vizinho_ok = true
			if not vizinho_ok:
				erros.append("escada em (%d, %d) inalcançável" % [c.x, c.y])
			continue
		if not alcancavel.has(alvo):
			erros.append("posição (%d, %d) '%s' inalcançável a partir da chegada" % [c.x, c.y, char_em(c)])


func _inundar(origem: Vector2i) -> Dictionary:
	var visitados := {origem: true}
	var fila: Array[Vector2i] = [origem]
	while not fila.is_empty():
		var c: Vector2i = fila.pop_front()
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n := c + d
			if visitados.has(n) or n.x < 0 or n.y < 0 or n.x >= largura or n.y >= altura:
				continue
			if andavel(n) and char_em(n) != "E":
				visitados[n] = true
				fila.append(n)
	return visitados
