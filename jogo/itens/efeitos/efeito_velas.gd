@tool
class_name EfeitoVelas
extends EfeitoDados
## Altera as velas (vida) da Coveira: aumenta o máximo e/ou acende velas.

@export var aumento_maximo: int = 0
@export var cura: int = 0


func executar(_ctx: ContextoEfeito) -> void:
	if aumento_maximo != 0:
		Jogo.alterar_velas_max(aumento_maximo)
	if cura > 0:
		Jogo.curar(cura)
