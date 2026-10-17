class_name DanoInfo
extends RefCounted
## Descreve um golpe: quanto dano, de onde veio, como empurra e o que dispara.
## É criado pelo atacante, entregue ao alvo e repassado aos gatilhos de itens.

## Níveis de interrupção: quanto o golpe consegue quebrar a postura do alvo.
enum Interrupcao { NENHUMA, LEVE, FORTE }

var valor: float = 0.0
var atacante: Node2D = null
## Nome do inimigo/fonte e do ataque (para a tela de morte e mensagens).
var fonte_nome: String = ""
var ataque_nome: String = ""
## Dica exibida na tela de morte quando este golpe mata a Coveira.
var dica: String = ""
var direcao: Vector2 = Vector2.ZERO
var empurrao: float = 0.0
var interrupcao: Interrupcao = Interrupcao.LEVE
var hitstop: float = 0.0
var tremor: float = 0.0
## Etiquetas livres usadas por itens: &"golpe_final", &"pesado", &"estado", &"onda"...
var tags: Array[StringName] = []
## Profundidade de encadeamento: golpes criados por efeitos de itens têm profundidade > 0.
## Efeitos não disparam a partir de golpes com profundidade >= MAX_PROFUNDIDADE.
var profundidade: int = 0
## Dano em velas causado à Coveira (inimigos usam 1 ou 2).
var velas: int = 1

const MAX_PROFUNDIDADE := 2


func tem_tag(tag: StringName) -> bool:
	return tags.has(tag)


func pode_encadear() -> bool:
	return profundidade < MAX_PROFUNDIDADE


## Cria um golpe derivado deste (para efeitos de itens), herdando atacante e profundidade.
func derivar(novo_valor: float, novas_tags: Array[StringName] = []) -> DanoInfo:
	var d := DanoInfo.new()
	d.valor = novo_valor
	d.atacante = atacante
	d.fonte_nome = fonte_nome
	d.ataque_nome = ataque_nome
	d.direcao = direcao
	d.interrupcao = Interrupcao.NENHUMA
	d.tags = novas_tags
	d.profundidade = profundidade + 1
	return d
