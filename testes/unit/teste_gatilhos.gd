extends CasoTeste


func _item_com(efeito: EfeitoDados) -> ItemDados:
	var item := ItemDados.new()
	item.id = &"teste"
	item.nome = "Teste"
	item.efeitos = [efeito]
	return item


func _golpe(tags: Array[StringName], profundidade: int = 0) -> DanoInfo:
	var info := DanoInfo.new()
	info.valor = 10.0
	info.tags = tags
	info.profundidade = profundidade
	return info


func teste_efeito_respeita_tags_exigidas() -> void:
	var alvo := AlvoFalso.new()
	add_child(alvo)
	var efeito := EfeitoAplicarEstado.new()
	efeito.gatilho = &"ao_acertar"
	efeito.requer_tags = [&"golpe_final"]
	efeito.estado = &"sangria"
	var itens: Array[ItemDados] = [_item_com(efeito)]
	var g := Gatilhos.new()
	g.disparar(&"ao_acertar", ContextoEfeito.new(null, alvo, _golpe([&"leve"])), itens)
	afirmar(not alvo.estados.tem(&"sangria"), "golpe sem a etiqueta não aplica sangria")
	g.disparar(&"ao_acertar", ContextoEfeito.new(null, alvo, _golpe([&"leve", &"golpe_final"])), itens)
	afirmar(alvo.estados.tem(&"sangria"), "golpe final aplica sangria")
	alvo.queue_free()


func teste_limite_de_encadeamento() -> void:
	var alvo := AlvoFalso.new()
	add_child(alvo)
	var efeito := EfeitoAplicarEstado.new()
	efeito.gatilho = &"ao_acertar"
	efeito.estado = &"sangria"
	var itens: Array[ItemDados] = [_item_com(efeito)]
	var g := Gatilhos.new()
	var n := g.disparar(&"ao_acertar", ContextoEfeito.new(null, alvo, _golpe([], DanoInfo.MAX_PROFUNDIDADE)), itens)
	afirmar_igual(n, 0, "golpe no limite de profundidade não dispara efeitos")
	n = g.disparar(&"ao_acertar", ContextoEfeito.new(null, alvo, _golpe([], 1)), itens)
	afirmar_igual(n, 1, "golpe derivado abaixo do limite dispara")
	alvo.queue_free()


func teste_recarga_interna() -> void:
	var efeito := EfeitoDados.new()
	efeito.gatilho = &"ao_esquivar"
	efeito.recarga = 1.0
	var itens: Array[ItemDados] = [_item_com(efeito)]
	var g := Gatilhos.new()
	afirmar_igual(g.disparar(&"ao_esquivar", ContextoEfeito.new(), itens), 1, "primeiro disparo")
	afirmar_igual(g.disparar(&"ao_esquivar", ContextoEfeito.new(), itens), 0, "bloqueado pela recarga")
	g.avancar(1.01)
	afirmar_igual(g.disparar(&"ao_esquivar", ContextoEfeito.new(), itens), 1, "recarga terminou")


func teste_derivar_incrementa_profundidade() -> void:
	var info := _golpe([&"leve"])
	var d := info.derivar(5.0, [&"efeito"])
	afirmar_igual(d.profundidade, 1, "profundidade derivada")
	afirmar_igual(d.interrupcao, DanoInfo.Interrupcao.NENHUMA, "derivado não interrompe")
	afirmar(d.pode_encadear(), "profundidade 1 ainda encadeia")
	afirmar(not d.derivar(1.0).pode_encadear(), "profundidade 2 não encadeia")
