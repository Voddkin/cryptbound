extends CasoTeste
## Usa um caminho próprio (dentro de user://testes/) para não tocar no progresso real.

const CAMINHO := "user://testes/teste_progresso.json"

var _caminho_original := ""
var _dados_originais: Dictionary = {}


func antes_de_cada() -> void:
	_caminho_original = Salvamento.caminho
	_dados_originais = Salvamento.dados.duplicate(true)
	Salvamento.caminho = CAMINHO
	Salvamento.aviso_pendente = ""
	Ambiente.garantir_pasta(CAMINHO)
	_apagar()


func depois_de_cada() -> void:
	_apagar()
	Salvamento.caminho = _caminho_original
	Salvamento.dados = _dados_originais
	Salvamento.aviso_pendente = ""


func _apagar() -> void:
	for sufixo in ["", ".bak", ".tmp", ".corrompido"]:
		if FileAccess.file_exists(CAMINHO + sufixo):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO + sufixo))


func _escrever(texto: String, caminho: String = CAMINHO) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func _progresso(descidas: int) -> String:
	return JSON.stringify({"versao": 1, "descidas": descidas, "mortes": 1})


func teste_caminho_isolado_em_modo_teste() -> void:
	afirmar(Ambiente.em_teste(), "executor detectado como modo de teste")
	afirmar(_caminho_original.begins_with("user://testes/"), "progresso dos testes fica em user://testes/")
	afirmar(Config.caminho.begins_with("user://testes/"), "configurações dos testes ficam em user://testes/")


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
	afirmar(not FileAccess.file_exists(CAMINHO + ".tmp"), "nenhum .tmp sobra após gravação bem-sucedida")
	afirmar_igual(int(Salvamento._ler_valido(CAMINHO + ".bak").get("descidas", -1)), 1, ".bak guarda a gravação anterior")


func teste_arquivo_corrompido_usa_backup() -> void:
	Salvamento.carregar()
	Salvamento.registrar_descida(3, 5, 4, 100.0, true)
	Salvamento.registrar_descida(5, 5, 4, 100.0, true)  # .bak = versão com 1 descida
	_escrever("{ isto não é json")
	Salvamento.carregar()
	afirmar(Salvamento.aviso_pendente != "", "aviso de recuperação")
	afirmar_igual(Salvamento.dados["descidas"], 1, "dados recuperados do backup")
	afirmar_igual(int(Salvamento._ler_valido(CAMINHO).get("descidas", -1)), 1, "principal regravado com os dados recuperados")
	afirmar(FileAccess.file_exists(CAMINHO + ".corrompido"), "arquivo danificado preservado")


func teste_tmp_mais_novo_vence_backup() -> void:
	# Queda entre os dois renomeios: sem principal, .tmp (novo) e .bak (antigo).
	_escrever(_progresso(9), CAMINHO + ".tmp")
	_escrever(_progresso(2), CAMINHO + ".bak")
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["descidas"], 9, "a gravação mais nova (.tmp) é a recuperada")
	afirmar_igual(Salvamento.aviso_pendente, "", "recuperar de queda em gravação não é corrupção")
	afirmar_igual(int(Salvamento._ler_valido(CAMINHO).get("descidas", -1)), 9, "principal refeito a partir do .tmp")


func teste_corrompido_sem_backup_recomeca() -> void:
	_escrever("[1, 2, 3]")
	Salvamento.carregar()
	afirmar_igual(Salvamento.aviso_pendente, Textos.t("erro.salvamento_perdido"), "aviso de perda")
	afirmar_igual(Salvamento.dados["descidas"], 0, "progresso reiniciado")
	afirmar(FileAccess.file_exists(CAMINHO + ".corrompido"), "cópia do arquivo danificado preservada")


func teste_tipos_invalidos_rejeitam_o_arquivo_inteiro() -> void:
	_escrever(JSON.stringify({"versao": 1, "descidas": "muitas", "mortes": 5}))
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["mortes"], 0, "campo válido não é aproveitado de arquivo inválido")
	afirmar(Salvamento.aviso_pendente != "", "arquivo inválido gera aviso")
	_apagar()
	_escrever(JSON.stringify({"versao": 99, "descidas": 3}))
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["descidas"], 0, "versão futura desconhecida é rejeitada")


func teste_versao_antiga_ganha_campos_novos() -> void:
	_escrever(JSON.stringify({"versao": 1, "descidas": 7}))
	Salvamento.carregar()
	afirmar_igual(Salvamento.dados["descidas"], 7, "campo existente mantido")
	afirmar(Salvamento.dados.has("reliquias_vistas"), "campo ausente preenchido com padrão")
	afirmar_igual(Salvamento.aviso_pendente, "", "sem aviso")
