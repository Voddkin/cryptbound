extends Node
## Executor de testes. Rode com:
##   godot --headless --fixed-fps 60 --path . res://testes/executar_testes.tscn [-- filtro]
## (ou ferramentas/testar.sh). Procura testes/unit/teste_*.gd e testes/simulacao/teste_*.gd,
## executa cada método `teste_*` e encerra com código 0 (sucesso) ou 1 (falha).
##
## Um teste falha se: alguma afirmação falhar; o motor registrar erro de script/execução
## durante o teste (exceto erros declarados com `esperar_erro`); não fizer nenhuma afirmação;
## estourar o tempo. Scripts de teste inválidos também contam como falha.

const PASTAS := ["res://testes/unit/", "res://testes/simulacao/"]
const LIMITE_POR_TESTE := 30.0
const LIMITE_TOTAL := 900.0


## Captura erros do motor (inclusive de outras threads) para atribuí-los ao teste atual.
class ColetorErros:
	extends Logger

	var _mutex := Mutex.new()
	var _erros: Array[String] = []

	func _log_error(funcao: String, arquivo: String, linha: int, codigo: String, motivo: String,
			_editor: bool, tipo: int, _pilhas: Array[ScriptBacktrace]) -> void:
		if tipo == ERROR_TYPE_WARNING:
			return
		var texto := motivo if motivo != "" else codigo
		_mutex.lock()
		_erros.append("%s (%s:%d em %s)" % [texto, arquivo.get_file(), linha, funcao])
		_mutex.unlock()

	func _log_message(_mensagem: String, _erro: bool) -> void:
		pass

	func coletar() -> Array[String]:
		_mutex.lock()
		var copia := _erros.duplicate()
		_erros.clear()
		_mutex.unlock()
		return copia


var _filtro := ""
var _coletor := ColetorErros.new()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_filtro = args[0]
	OS.add_logger(_coletor)
	# Vigia global: nada (cena trocada, corrotina morta) pode deixar o processo pendurado.
	get_tree().create_timer(LIMITE_TOTAL, true, false, true).timeout.connect(_estourou_tempo_total)
	_executar.call_deferred()


func _estourou_tempo_total() -> void:
	print("RESULTADO: tempo total esgotado (%ds) — execução abortada" % int(LIMITE_TOTAL))
	get_tree().quit(1)


func _executar() -> void:
	var total := 0
	var falhos: Array[String] = []
	var inicio := Time.get_ticks_msec()
	_coletor.coletar()
	for pasta: String in PASTAS:
		var arquivos := DirAccess.get_files_at(pasta)
		arquivos.sort()
		for arquivo in arquivos:
			if not (arquivo.begins_with("teste_") and arquivo.ends_with(".gd")):
				continue
			var script := load(pasta + arquivo) as GDScript
			var erros_carga := _coletor.coletar()
			if script == null or not script.can_instantiate() or not erros_carga.is_empty():
				falhos.append(arquivo)
				print("  FALHA %s: script inválido" % arquivo)
				for e in erros_carga:
					print("        - %s" % e)
				continue
			var metodos: Array[String] = []
			for metodo in script.get_script_method_list():
				var nome: String = metodo["name"]
				if nome.begins_with("teste_") and not metodos.has(nome):
					metodos.append(nome)
			if metodos.is_empty():
				falhos.append(arquivo)
				print("  FALHA %s: nenhum método teste_*" % arquivo)
				continue
			for nome in metodos:
				if _filtro != "" and not (arquivo + ":" + nome).contains(_filtro):
					continue
				total += 1
				var rotulo := "%s:%s" % [arquivo.get_basename(), nome]
				var instancia: Variant = script.new()
				if not instancia is CasoTeste:
					falhos.append(rotulo)
					print("  FALHA %s: o script não estende CasoTeste" % rotulo)
					break
				var caso := instancia as CasoTeste
				add_child(caso)
				_coletor.coletar()
				caso.antes_de_cada()
				var concluido := [false]
				var executar := func() -> void:
					await caso.call(nome)
					concluido[0] = true
				executar.call()
				var limite := Time.get_ticks_msec() + int(LIMITE_POR_TESTE * 1000.0)
				while not concluido[0] and Time.get_ticks_msec() < limite:
					await get_tree().process_frame
				if not concluido[0]:
					caso.falhas.append("tempo esgotado (%ds)" % int(LIMITE_POR_TESTE))
				caso.depois_de_cada()
				for erro in _coletor.coletar():
					if not caso.erro_esperado(erro):
						caso.falhas.append("erro do motor: %s" % erro)
				if caso.afirmacoes == 0 and caso.falhas.is_empty():
					caso.falhas.append("nenhuma afirmação executada")
				if caso.falhas.is_empty():
					print("  ok    %s (%d afirmações)" % [rotulo, caso.afirmacoes])
				else:
					print("  FALHA %s" % rotulo)
					for f in caso.falhas:
						print("        - %s" % f)
					falhos.append(rotulo)
				caso.queue_free()
				# Limpa qualquer estado global alterado pelo teste.
				get_tree().paused = false
				Efeitos.limpar_registro()
				await get_tree().process_frame
	var segundos := (Time.get_ticks_msec() - inicio) / 1000.0
	print("")
	print("RESULTADO: %d testes, %d falhas (%.1fs)" % [total, falhos.size(), segundos])
	OS.remove_logger(_coletor)
	get_tree().quit(1 if not falhos.is_empty() or total == 0 else 0)
