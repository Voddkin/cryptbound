class_name Estado
extends RefCounted
## Estado alterado aplicado a uma entidade (Sangria, Atordoado...).
## Subclasses sobrescrevem os ganchos. O contêiner `Estados` chama os ganchos.

var id: StringName = &""
var hospedeiro: Node2D
var duracao: float = 1.0
var restante: float = 1.0
var acumulos: int = 1
var max_acumulos: int = 1
## Quem aplicou (para creditar dano e mortes).
var origem: Node2D


func ao_aplicar() -> void:
	pass


## Chamado quando o mesmo estado é aplicado de novo: renova a duração e acumula.
func reaplicar(novo: Estado) -> void:
	restante = maxf(restante, novo.duracao)
	acumulos = mini(acumulos + novo.acumulos, max_acumulos)


func ao_processar(_delta: float) -> void:
	pass


## Chamado com a distância (em pixels) que o hospedeiro percorreu neste quadro.
func ao_mover(_distancia: float) -> void:
	pass


func ao_remover() -> void:
	pass


## Cor de realce desenhada no hospedeiro enquanto o estado está ativo (alfa 0 = nenhuma).
func cor_realce() -> Color:
	return Color(0, 0, 0, 0)


## Verdadeiro se o hospedeiro não pode agir (atordoamento, congelamento...).
func impede_acao() -> bool:
	return false
