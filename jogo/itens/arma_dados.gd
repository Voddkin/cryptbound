@tool
class_name ArmaDados
extends Resource
## Arma principal: combo de golpes leves + golpe pesado carregado.

@export var id: StringName = &""
@export var nome: String = ""
@export_multiline var descricao: String = ""
@export var sprite: Texture2D
## Ponto de empunhadura dentro do sprite (pixels a partir do canto superior esquerdo).
@export var empunhadura: Vector2 = Vector2(3, 4)
@export var combo: Array[GolpeDados] = []
@export var pesado: GolpeDados
## Tempo segurando o botão para carregar totalmente o golpe pesado.
@export var carga_pesado: float = 0.45
## Tempo após o último golpe em que o combo ainda continua.
@export var tempo_combo: float = 0.45
