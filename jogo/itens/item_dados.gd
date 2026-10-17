@tool
class_name ItemDados
extends Resource
## Definição de uma relíquia (ou outro item). Os efeitos são recursos separados,
## disparados por gatilhos (ao acertar, ao esquivar...). Ver DOCUMENTO_DE_DESIGN.md.

enum Raridade { COMUM, INCOMUM, RARA, LENDARIA }

@export var id: StringName = &""
@export var nome: String = ""
## Descrição mecânica, clara e objetiva.
@export_multiline var descricao: String = ""
## Inscrição/pequena história do objeto.
@export_multiline var inscricao: String = ""
@export var raridade: Raridade = Raridade.COMUM
@export var icone: Texture2D
@export var efeitos: Array[EfeitoDados] = []
@export var tags: Array[StringName] = []


func cor_raridade() -> Color:
	match raridade:
		Raridade.INCOMUM: return Color("8fbf6a")
		Raridade.RARA: return Color("7fa8e8")
		Raridade.LENDARIA: return Color("f6c35a")
	return Color("d8cfb8")
