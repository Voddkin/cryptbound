@tool
class_name InimigoDados
extends Resource
## Números e textos de um tipo de inimigo. O comportamento fica no script da entidade.

@export var id: StringName = &""
@export var nome: String = ""
## Nome do ataque principal (aparece na tela de morte: "Abatida por: <nome> — <ataque>").
@export var ataque: String = ""
## Dica exibida quando este inimigo derruba a Coveira.
@export_multiline var dica: String = ""
@export var vida: float = 30.0
@export var velocidade: float = 40.0
@export var velas_de_dano: int = 1
@export var ossos_min: int = 1
@export var ossos_max: int = 3
## Material dos estilhaços ao ser atingido: &"osso", &"cera", &"carne".
@export var material: StringName = &"osso"
@export var som_acerto: StringName = &"acerto_osso"
@export var som_morte: StringName = &"ressequido_morte"
