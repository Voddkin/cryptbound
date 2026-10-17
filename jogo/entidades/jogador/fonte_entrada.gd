class_name FonteEntrada
extends RefCounted
## Intenções de controle da Coveira num quadro de física. A Coveira só lê estes campos:
## quem os preenche pode ser o jogador (teclado/controle), um teste ou o robô de demonstração.

## Direção de movimento (comprimento 0..1).
var mover := Vector2.ZERO
## Direção de mira (normalizada) ou ZERO para "usar a direção do corpo".
var mirar := Vector2.ZERO
## Pressões neste quadro (borda de subida).
var atacar := false
var esquivar := false
var interagir := false
## Botão do golpe pesado mantido pressionado.
var pesado := false


## Atualiza os campos para o quadro atual. `jogador` permite mirar relativo à posição.
func atualizar(_jogador: Node2D, _delta: float) -> void:
	pass


func limpar_pressoes() -> void:
	atacar = false
	esquivar = false
	interagir = false
