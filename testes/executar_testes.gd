extends Node
## Executor de testes. Rode com:
##   godot --headless --path . res://testes/executar_testes.tscn [-- filtro]
## Procura testes/unit/teste_*.gd e testes/simulacao/teste_*.gd, executa cada método
## `teste_*`, imprime o resumo e encerra com código 0 (sucesso) ou 1 (falha).

const PASTAS := ["res://testes/unit/", "res://testes/simulacao/"]
const LIMITE_POR_TESTE := 30.0

var _filtro := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_filtro = args[0]
	_executar.call_deferred()


func _executar() -> void:
	var total := 0
	var falhos: Array[String] = []
	var inicio := Time.get_ticks_msec()
	for pasta: String in PASTAS:
		var arquivos := DirAccess.get_files_at(pasta)
		arquivos.sort()
		for arquivo in arquivos:
			if not (arquivo.begins_with("teste_") and arquivo.ends_with(".gd")):
				continue
			var script := load(pasta + arquivo) as GDScript
			if script == null:
				falhos.append("%s: não foi possível carregar o script" % arquivo)
				continue
			for metodo in script.get_script_method_list():
				var nome: String = metodo["name"]
				if not nome.begins_with("teste_"):
					continue
				if _filtro != "" and not (arquivo + ":" + nome).contains(_filtro):
					continue
				total += 1
				var caso: CasoTeste = script.new()
				add_child(caso)
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
				var rotulo := "%s:%s" % [arquivo.get_basename(), nome]
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
	get_tree().quit(1 if not falhos.is_empty() or total == 0 else 0)
