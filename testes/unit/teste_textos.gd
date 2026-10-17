extends CasoTeste
## Lint dos textos visíveis: toda chave usada existe; nada de texto provisório ou inglês
## acidental nos textos e nos dados.

const PROIBIDOS := ["TODO", "FIXME", "placeholder", "lorem", "ipsum", "XXX", "teste123"]
## Palavras em inglês que denunciam texto esquecido (com espaços para evitar falsos positivos).
const INGLES := [" the ", " and ", " you ", " your ", "Start game", "Settings", "Quit", "Loading", "Game Over", "Press "]


func _arquivos(pasta: String, extensao: String) -> Array[String]:
	var saida: Array[String] = []
	var dir := DirAccess.open(pasta)
	if dir == null:
		return saida
	for arquivo in dir.get_files():
		if arquivo.ends_with(extensao):
			saida.append(pasta.path_join(arquivo))
	for sub in dir.get_directories():
		saida.append_array(_arquivos(pasta.path_join(sub), extensao))
	return saida


func teste_chaves_usadas_existem() -> void:
	var regex := RegEx.create_from_string("Textos\\.t\\(\"([a-z0-9_.]+)\"")
	var usadas := {}
	for caminho in _arquivos("res://jogo", ".gd"):
		if caminho.ends_with("textos/textos.gd"):
			continue  # o próprio arquivo de textos tem exemplos na documentação
		var codigo := FileAccess.get_file_as_string(caminho)
		for m in regex.search_all(codigo):
			usadas[m.get_string(1)] = caminho
	afirmar(usadas.size() > 20, "o lint encontrou as chaves usadas (%d)" % usadas.size())
	for chave: String in usadas:
		afirmar(Textos.existe(chave), "chave '%s' usada em %s existe" % [chave, usadas[chave]])


func teste_toda_chave_definida_e_usada() -> void:
	# Chaves mortas escondem mensagens que o jogador deveria ver (ou sobram de código velho).
	# Vale qualquer uso literal: Textos.t("chave"), a chave passada a um auxiliar ou uma família
	# montada em tempo de execução ("estado.%s" % id).
	var codigo := ""
	for caminho in _arquivos("res://jogo", ".gd"):
		if not caminho.ends_with("textos/textos.gd"):
			codigo += FileAccess.get_file_as_string(caminho)
	var mortas: Array[String] = []
	for chave: String in Textos.TEXTOS:
		if not codigo.contains("\"%s\"" % chave) and not codigo.contains("\"%s.%%s\"" % chave.get_slice(".", 0)):
			mortas.append(chave)
	afirmar(mortas.is_empty(), "chaves definidas e nunca usadas: %s" % ", ".join(mortas))


func teste_textos_sem_provisorio_nem_ingles() -> void:
	var textos: Array[String] = []
	for chave: String in Textos.TEXTOS:
		# Créditos citam nomes próprios estrangeiros exigidos pelas licenças (autores das fontes).
		if chave == "creditos.texto":
			continue
		textos.append(Textos.TEXTOS[chave])
	for caminho in _arquivos("res://dados", ".tres"):
		var recurso := load(caminho)
		for campo in ["nome", "descricao", "inscricao", "ataque", "dica"]:
			if campo in recurso and typeof(recurso.get(campo)) == TYPE_STRING:
				textos.append(recurso.get(campo))
	for caminho in _arquivos("res://dados/salas", ".txt"):
		var def := DefinicaoSala.de_arquivo(caminho)
		textos.append(def.nome)
	var problemas := 0
	for t in textos:
		var minusculo := " %s " % t.to_lower()
		for p in PROIBIDOS:
			if minusculo.contains(p.to_lower()):
				problemas += 1
				falhas.append("texto provisório: '%s'" % t)
		for p in INGLES:
			if minusculo.contains(p.to_lower()):
				problemas += 1
				falhas.append("possível inglês: '%s'" % t)
	afirmar(textos.size() > 60, "textos verificados: %d" % textos.size())
	afirmar_igual(problemas, 0, "nenhum texto suspeito")


func teste_formatacao_de_campos() -> void:
	afirmar_igual(Textos.t("hud.profundidade", {"n": 3}), "Profundidade 3", "campo substituído")
	esperar_erro("Texto ausente")
	afirmar_igual(Textos.t("nao.existe"), "nao.existe", "chave ausente devolve a própria chave")
