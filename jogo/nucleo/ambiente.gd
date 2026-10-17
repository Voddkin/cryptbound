class_name Ambiente
extends RefCounted
## Em que modo o jogo foi iniciado. Testes e demonstrações gravam em pastas próprias,
## para nunca tocar no progresso e nas configurações reais do jogador.
##
## Modos (argumentos depois de `--` na linha de comando):
##   --demo        robô joga sozinho (capturas e vídeos)
##   --testes      executor de testes (também detectado pela cena do executor)


static func em_teste() -> bool:
	for arg in OS.get_cmdline_args():
		if arg.ends_with("executar_testes.tscn"):
			return true
	return OS.get_cmdline_user_args().has("--testes")


static func em_demo() -> bool:
	return OS.get_cmdline_user_args().has("--demo")


## Pasta base dos dados graváveis (termina com "/").
static func pasta_dados() -> String:
	if em_teste():
		return "user://testes/"
	if em_demo():
		return "user://demo/"
	return "user://"


static func garantir_pasta(caminho: String) -> void:
	var pasta := caminho.get_base_dir()
	if not DirAccess.dir_exists_absolute(pasta):
		DirAccess.make_dir_recursive_absolute(pasta)
