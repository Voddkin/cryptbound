extends SceneTree
## Gera o arquivo de licenças de terceiros que acompanha o executável (o Godot é MIT e
## exige o aviso de copyright em toda distribuição). Uso:
##   godot --headless --path . -s res://ferramentas/pacote/licencas.gd -- <arquivo de saída>


func _init() -> void:
	var t := "LICENÇAS DE TERCEIROS — CRYPTBOUND\n\n"
	t += "Fontes Jacquard 12, Jersey 10 e Micro 5: (c) The Soft Type Project Authors,\n"
	t += "SIL Open Font License 1.1 (texto completo em OFL.txt).\n\n"
	t += "Godot Engine\n" + "=".repeat(60) + "\n" + Engine.get_license_text() + "\n\n"
	t += "Componentes de terceiros incluídos no Godot Engine\n" + "=".repeat(60) + "\n"
	for info in Engine.get_copyright_info():
		t += "\n- " + str(info["name"]) + "\n"
		for parte in info["parts"]:
			for c in parte["copyright"]:
				t += "    (c) " + str(c) + "\n"
			t += "    Licença: " + str(parte["license"]) + "\n"
	var licencas := Engine.get_license_info()
	t += "\n\nTextos das licenças\n" + "=".repeat(60) + "\n"
	for nome in licencas:
		t += "\n----- " + str(nome) + " -----\n" + str(licencas[nome]) + "\n"
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(t)
	f.close()
	quit()
