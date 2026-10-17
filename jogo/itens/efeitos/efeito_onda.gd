@tool
class_name EfeitoOnda
extends EfeitoDados
## Onda de choque centrada na Coveira: empurra, atordoa e/ou fere inimigos no raio.

@export var raio: float = 48.0
@export var dano: float = 0.0
@export var empurrao: float = 220.0
@export var atordoamento: float = 0.6
## Identificador visual/sonoro da onda (ex.: &"badalo").
@export var estilo: StringName = &"badalo"


func executar(ctx: ContextoEfeito) -> void:
	if ctx.jogador == null or not is_instance_valid(ctx.jogador) or not ctx.jogador.is_inside_tree():
		return
	var centro := ctx.jogador.global_position
	Efeitos.onda(centro, raio, estilo)
	Audio.tocar(&"sino_badalo", centro, 0.05)
	for inimigo in ctx.jogador.get_tree().get_nodes_in_group(&"inimigos"):
		var alvo := inimigo as Node2D
		if alvo == null or not alvo.has_method(&"receber_dano"):
			continue
		var delta := alvo.global_position - centro
		if delta.length() > raio:
			continue
		var info := DanoInfo.new()
		info.valor = dano
		info.atacante = ctx.jogador
		info.direcao = delta.normalized() if delta.length() > 0.1 else Vector2.RIGHT
		info.empurrao = empurrao
		info.interrupcao = DanoInfo.Interrupcao.FORTE
		info.tags = [&"onda", &"efeito"]
		info.profundidade = 1 if ctx.info == null else ctx.info.profundidade + 1
		if alvo.receber_dano(info) and atordoamento > 0.0:
			var estados: Estados = alvo.get_node_or_null(^"Estados")
			if estados:
				estados.aplicar(EstadoAtordoado.new(atordoamento, ctx.jogador))
