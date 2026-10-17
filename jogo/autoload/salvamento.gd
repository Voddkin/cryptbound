extends Node
## Progresso persistente entre descidas (JSON versionado em user://).
##
## Gravação: escreve <arquivo>.tmp, relê e valida; o principal válido vira <arquivo>.bak
## (por renomeação, nunca por cópia) e o .tmp é renomeado para o principal.
## Em qualquer instante de uma queda existe pelo menos uma cópia íntegra, e a mais nova
## é sempre preferida: principal → .tmp → .bak. Arquivo danificado é preservado como
## .corrompido e o jogador recebe um aviso em pt-BR.

const VERSAO := 1
const NOME_ARQUIVO := "progresso.json"

const PADRAO := {
	"versao": VERSAO,
	"descidas": 0,
	"mortes": 0,
	"maior_profundidade": 0,
	"abates_total": 0,
	"salas_total": 0,
	"tempo_total": 0.0,
	"reliquias_vistas": [],
}

var caminho := ""
var dados: Dictionary = {}
## Mensagem para a interface quando houve recuperação de dados.
var aviso_pendente := ""


func _ready() -> void:
	caminho = Ambiente.pasta_dados() + NOME_ARQUIVO
	carregar()


func carregar() -> void:
	aviso_pendente = ""
	var principal_existe := FileAccess.file_exists(caminho)
	var lido := _ler_valido(caminho)
	if not lido.is_empty():
		dados = lido
		return
	var origem := ""
	for sufixo in [".tmp", ".bak"]:
		lido = _ler_valido(caminho + sufixo)
		if not lido.is_empty():
			origem = sufixo
			break
	if principal_existe:
		_preservar_corrompido()
		aviso_pendente = Textos.t("erro.salvamento_corrompido") if origem != "" else Textos.t("erro.salvamento_perdido")
	elif origem == ".bak":
		# Sem principal e sem .tmp: a gravação mais recente se perdeu, só sobrou o backup.
		aviso_pendente = Textos.t("erro.salvamento_corrompido")
	dados = lido if origem != "" else PADRAO.duplicate(true)
	salvar()


## Lê e valida um arquivo; devolve {} se não existir ou for inválido.
func _ler_valido(arquivo: String) -> Dictionary:
	if not FileAccess.file_exists(arquivo):
		return {}
	var texto := FileAccess.get_file_as_string(arquivo)
	if texto.is_empty():
		return {}
	var json := JSON.new()
	if json.parse(texto) != OK:
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return _validar(json.data)


## Garante tipos e campos; aceita versões antigas preenchendo campos novos com o padrão.
## Um campo presente com tipo errado invalida o arquivo inteiro.
func _validar(bruto: Dictionary) -> Dictionary:
	var versao: Variant = bruto.get("versao")
	if typeof(versao) not in [TYPE_INT, TYPE_FLOAT] or int(versao) < 1 or int(versao) > VERSAO:
		return {}
	var limpo := PADRAO.duplicate(true)
	for chave: String in PADRAO:
		if not bruto.has(chave):
			continue
		var padrao: Variant = PADRAO[chave]
		var valor: Variant = bruto[chave]
		match typeof(padrao):
			TYPE_INT:
				if typeof(valor) not in [TYPE_INT, TYPE_FLOAT]:
					return {}
				limpo[chave] = maxi(int(valor), 0)
			TYPE_FLOAT:
				if typeof(valor) not in [TYPE_INT, TYPE_FLOAT]:
					return {}
				limpo[chave] = maxf(float(valor), 0.0)
			TYPE_ARRAY:
				if typeof(valor) != TYPE_ARRAY:
					return {}
				var lista: Array = []
				for v: Variant in valor:
					if typeof(v) == TYPE_STRING:
						lista.append(v)
				limpo[chave] = lista
	limpo["versao"] = VERSAO
	return limpo


func salvar() -> bool:
	Ambiente.garantir_pasta(caminho)
	var absoluto := ProjectSettings.globalize_path(caminho)
	var tmp := caminho + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Não foi possível gravar o progresso (%s)." % error_string(FileAccess.get_open_error()))
		return false
	var escreveu := f.store_string(JSON.stringify(dados, "\t"))
	f.close()
	# Disco cheio e afins podem truncar o arquivo sem erro: só promove o que relê íntegro.
	if not escreveu or _ler_valido(tmp).is_empty():
		push_warning("A gravação do progresso falhou na verificação; o arquivo anterior foi mantido.")
		DirAccess.remove_absolute(absoluto + ".tmp")
		return false
	if FileAccess.file_exists(caminho) and not _ler_valido(caminho).is_empty():
		var erro_bak := DirAccess.rename_absolute(absoluto, absoluto + ".bak")
		if erro_bak != OK:
			push_warning("Não foi possível guardar a cópia de segurança (%s)." % error_string(erro_bak))
	var erro := DirAccess.rename_absolute(absoluto + ".tmp", absoluto)
	if erro != OK:
		push_warning("Não foi possível finalizar a gravação do progresso (%s)." % error_string(erro))
		return false
	return true


func _preservar_corrompido() -> void:
	var absoluto := ProjectSettings.globalize_path(caminho)
	DirAccess.copy_absolute(absoluto, absoluto + ".corrompido")


## Registra o fim de uma descida e salva.
func registrar_descida(profundidade: int, abates: int, salas: int, tempo: float, morreu: bool) -> void:
	dados["descidas"] = int(dados.get("descidas", 0)) + 1
	if morreu:
		dados["mortes"] = int(dados.get("mortes", 0)) + 1
	dados["maior_profundidade"] = maxi(int(dados.get("maior_profundidade", 0)), profundidade)
	dados["abates_total"] = int(dados.get("abates_total", 0)) + abates
	dados["salas_total"] = int(dados.get("salas_total", 0)) + salas
	dados["tempo_total"] = float(dados.get("tempo_total", 0.0)) + tempo
	salvar()


func registrar_reliquia_vista(id: StringName) -> void:
	var vistas: Array = dados.get("reliquias_vistas", [])
	if not vistas.has(String(id)):
		vistas.append(String(id))
		dados["reliquias_vistas"] = vistas
		salvar()
