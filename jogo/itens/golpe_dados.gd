@tool
class_name GolpeDados
extends Resource
## Um golpe de arma: tempos de antecipação/ativo/recuperação, área em arco e efeitos.
## Os tempos estão em segundos. O arco é centrado na direção da mira.

@export var nome: String = ""
@export var dano: float = 10.0
@export_range(10.0, 360.0) var arco_graus: float = 110.0
@export var alcance: float = 26.0
## Distância mínima do centro em que o arco começa (golpes "de ponta").
@export var alcance_minimo: float = 0.0
@export var antecipacao: float = 0.06
@export var ativo: float = 0.08
@export var recuperacao: float = 0.18
## A partir de que fração da recuperação o próximo golpe/esquiva pode cancelar.
@export_range(0.0, 1.0) var janela_cancelamento: float = 0.35
## Avanço da Coveira durante o golpe (px/s no início do ativo).
@export var avanco: float = 90.0
@export var empurrao: float = 120.0
@export var hitstop: float = 0.05
@export var tremor: float = 0.15
@export var interrupcao: DanoInfo.Interrupcao = DanoInfo.Interrupcao.LEVE
## Sentido do giro visual da arma: 1 = horário, -1 = anti-horário, 0 = estocada.
@export var sentido_giro: int = 1
@export var tags: Array[StringName] = []
@export var som: StringName = &"pa_varrida"
