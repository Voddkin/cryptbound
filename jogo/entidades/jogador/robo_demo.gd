class_name RoboDemo
extends FonteEntrada
## Robô que joga sozinho (modo --demo): usado para capturas, vídeos e testes de fumaça.
## Não é "inteligente": persegue o inimigo mais próximo, golpeia em combo, esquiva quando um
## Ressequido prepara a investida, pega a primeira relíquia, segue para a saída e desce.

var _t := 0.0
var _proxima_acao := 0.0
var _segura_pesado := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 1234


func atualizar(jogador: Node2D, delta: float) -> void:
	_t += delta
	mover = Vector2.ZERO
	mirar = Vector2.ZERO
	pesado = false
	if _segura_pesado > 0.0:
		_segura_pesado -= delta
		pesado = _segura_pesado > 0.0
	var arvore := jogador.get_tree()
	var alvo := _inimigo_mais_proximo(jogador, arvore)
	if alvo:
		var para := alvo.global_position - jogador.global_position
		var dist := para.length()
		mirar = para.normalized()
		# Ameaça: Ressequido preparando ou investindo perto → esquiva lateral.
		if alvo is Ressequido and (alvo as Ressequido).acao in [Ressequido.Acao.PREPARAR, Ressequido.Acao.INVESTIR] and dist < 52.0:
			if (alvo as Ressequido).acao == Ressequido.Acao.INVESTIR or _rng.randf() < 0.08:
				mover = para.normalized().orthogonal() * (1.0 if _rng.randf() < 0.5 else -1.0)
				esquivar = true
				return
		if dist > 26.0:
			mover = para.normalized()
		elif dist < 14.0:
			mover = -para.normalized() * 0.5
		if dist < 34.0 and _t >= _proxima_acao:
			if _rng.randf() < 0.12:
				_segura_pesado = 0.6
				_proxima_acao = _t + 0.9
			else:
				atacar = true
				_proxima_acao = _t + 0.16
		return
	# Sem inimigos: relíquia, escada ou saída.
	var destino := _destino_sem_combate(jogador, arvore)
	if destino != Vector2.INF:
		var para := destino - jogador.global_position
		if para.length() > 6.0:
			mover = para.normalized()
		else:
			interagir = true


func _inimigo_mais_proximo(jogador: Node2D, arvore: SceneTree) -> Node2D:
	var melhor: Node2D = null
	var menor := INF
	for n in arvore.get_nodes_in_group(&"inimigos"):
		var inimigo := n as Inimigo
		if inimigo == null or not inimigo.esta_vivo() or inimigo.fase == Inimigo.Fase.SURGINDO:
			continue
		var d := jogador.global_position.distance_to(inimigo.global_position)
		if d < menor:
			menor = d
			melhor = inimigo
	return melhor


func _destino_sem_combate(jogador: Node2D, arvore: SceneTree) -> Vector2:
	var sala := jogador.get_parent().get_parent() as Sala
	if sala == null:
		return Vector2.INF
	if sala.estado == Sala.Situacao.AGUARDANDO_ENTRADA:
		return sala.retangulo().get_center()
	if sala.estado != Sala.Situacao.LIMPA:
		return Vector2.INF
	for altar in sala.altares:
		if altar.item != null:
			return altar.global_position + Vector2(0, 10)
	for c in arvore.get_nodes_in_group(&"coletaveis"):
		var col := c as Coletavel
		if col and col.tipo == Coletavel.Tipo.OSSO and col.global_position.distance_to(jogador.global_position) < 90.0:
			return col.global_position
	if sala.escada:
		return sala.escada.global_position + Vector2(16, 16)
	if sala.definicao.saida != "":
		var porta: Porta = sala.portas.get(sala.definicao.saida)
		if porta:
			var r := porta.retangulo()
			# Caminha até a passagem pelo A* da sala
			var caminho := sala.caminho(jogador.global_position, r.get_center())
			if caminho.size() > 1:
				return caminho[1]
			return r.get_center() + Vector2(porta.direcao) * 8.0
	return Vector2.INF
