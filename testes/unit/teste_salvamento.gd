extends CasoTeste
## Usa um caminho próprio para não tocar no progresso real do jogador.

const CAMINHO := "user://teste_progresso.json"

var _caminho_original := ""
var _dados_originais: Dictionary = {}


func antes_de_cada() -> void:
	_caminho_original = Salvamento.caminho
	_dados_originais = Salvamento.dados.duplicate(true)
	Salvamento.caminho = CAMINHO
	Salvamento.aviso_pendente = ""
	_apagar()


func depois_de_cada() -> void:
	_apagar()
	Salvamento.caminho = _caminho_original
	Salvamento.dados = _dados_originais
	Salvamento.aviso_pendente = ""


func _apagar() -> void:
	for sufixo in ["", ".bak", ".tmp", ".corrompido"]:
		var absoluto := ProjectSettings.globalize_path(CAMINHO + sufixo)
		if FileAccess.file_exists(CAMINHO + sufixo):
			DirAccess.remove_absolute(absoluto)


func _escrever(texto: String, caminho: String = CAMINHO) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func teste_ida_e_volta() -> void:
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["descidas"], 0, "progresso novo começa zerado")
	Salvamento.registrar_descida(4, 12, 7, 300.0, true)
	Salvamento.registrar_descida(2, 3, 2, 60.0, false)
	Salvamento.dados = {}
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["descidas"], 2, "descidas")
	afirmar_igual(Salvamento.dados["mortes"], 1, "mortes")
	afirmar_igual(Salvamento.dados["maior_profundidade"], 4, "maior profundidade")
	afirmar_igual(Salvamento.dados["abates_total"], 15, "abates")
	afirmar_proximo(Salvamento.dados["tempo_total"], 360.0, 0.01, "tempo total")
	afirmar_igual(Salvamento.aviso_pendente, "", "sem aviso em leitura normal")


func teste_arquivo_corrompido_usa_backup() -> void:
	Salvamento.carregar()
	Salvamento.registrar_descida(3, 5, 4, 100.0, true)
	Salvamento.registrar_descida(5, 5, 4, 100.0, true)  # cria .bak com a versão anterior
	_escrever("{ isto não é json")
	Salvamento.carregar()
	afirmar(Salvamento.aviso_pendente != "", "aviso de recuperação")
	afirmar(int(Salvamento.dados["descidas"]) >= 1, "dados recuperados do backup")
	afirmar(FileAccess.file_exists(CAMINHO), "arquivo regravado")


func teste_corrompido_sem_backup_recomeca() -> void:
	_escrever("[1, 2, 3]")
	Salvamento.carregar()
	afirmar(Salvamento.aviso_pendente != "", "aviso de perda")
	afirmar_igual(Salvamento.dados["descidas"], 0, "progresso reiniciado")
	afirmar(FileAccess.file_exists(CAMINHO + ".corrompido"), "cópia do arquivo danificado preservada")


func teste_tipos_invalidos_sao_rejeitados() -> void:
	_escrever(JSON.stringify({"versao": 1, "descidas": "muitas"}))
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["descidas"], 0, "campo com tipo errado invalida o arquivo")
	_escrever(JSON.stringify({"versao": 99, "descidas": 3}))
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["descidas"], 0, "versão futura desconhecida é rejeitada")


func teste_versao_antiga_ganha_campos_novos() -> void:
	_escrever(JSON.stringify({"versao": 1, "descidas": 7}))
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["descidas"], 7, "campo existente mantido")
	afirmar(Salvamento.dados.has("reliquias_vistas"), "campo ausente preenchido com padrão")
	afirmar_igual(Salvamento.aviso_pendente, "", "sem aviso")
