extends CasoTeste
## Todo arquivo de dados carrega, tem a classe certa e textos preenchidos em pt-BR.


func _listar(pasta: String, extensao: String) -> Array[String]:
	var saida: Array[String] = []
	var dir := DirAccess.open(pasta)
	if dir == null:
		return saida
	for arquivo in dir.get_files():
		if arquivo.ends_with(extensao):
			saida.append(pasta.path_join(arquivo))
	for sub in dir.get_directories():
		saida.append_array(_listar(pasta.path_join(sub), extensao))
	return saida


func teste_arma_inicial() -> void:
	var arma := load("res://dados/armas/pa_de_coveiro.tres") as ArmaDados
	afirmar(arma != null, "Pá de Coveiro carrega como ArmaDados")
	if arma == null:
		return
	afirmar_igual(arma.combo.size(), 3, "combo de três golpes")
	afirmar(arma.pesado != null, "tem golpe pesado")
	afirmar(arma.sprite != null, "tem sprite")
	afirmar(arma.combo[2].tags.has(&"golpe_final"), "terceiro golpe é o golpe final")
	afirmar_igual(arma.combo[2].interrupcao, DanoInfo.Interrupcao.FORTE, "golpe final interrompe forte")
	for golpe in arma.combo + [arma.pesado]:
		afirmar(golpe.nome != "" and golpe.dano > 0.0 and golpe.ativo > 0.0, "golpe %s tem nome, dano e janela ativa" % golpe.nome)
		afirmar(Audio.existe(golpe.som), "som do golpe %s existe" % golpe.nome)


func teste_todos_os_itens() -> void:
	var arquivos := _listar("res://dados/itens", ".tres")
	afirmar(arquivos.size() >= 3, "pelo menos três relíquias")
	var ids: Array[StringName] = []
	for caminho in arquivos:
		var item := load(caminho) as ItemDados
		afirmar(item != null, "%s carrega como ItemDados" % caminho)
		if item == null:
			continue
		afirmar(item.id != &"" and not ids.has(item.id), "%s tem id único" % caminho)
		ids.append(item.id)
		afirmar(item.nome.strip_edges() != "", "%s tem nome" % caminho)
		afirmar(item.descricao.length() >= 15, "%s tem descrição mecânica" % caminho)
		afirmar(item.inscricao.strip_edges() != "", "%s tem inscrição" % caminho)
		afirmar(item.icone != null, "%s tem ícone" % caminho)
		afirmar(not item.efeitos.is_empty(), "%s tem efeitos" % caminho)
		for efeito in item.efeitos:
			afirmar(efeito != null and efeito.gatilho in [&"ao_adquirir", &"ao_acertar", &"ao_esquivar", &"ao_sofrer_dano", &"ao_eliminar", &"ao_limpar_sala"], "%s: gatilho conhecido" % caminho)
			if efeito is EfeitoAplicarEstado:
				afirmar(FabricaEstados.CONHECIDOS.has((efeito as EfeitoAplicarEstado).estado), "%s: estado conhecido" % caminho)


func teste_todos_os_inimigos() -> void:
	var arquivos := _listar("res://dados/inimigos", ".tres")
	afirmar(arquivos.size() >= 2, "pelo menos dois inimigos")
	for caminho in arquivos:
		var dados := load(caminho) as InimigoDados
		afirmar(dados != null, "%s carrega como InimigoDados" % caminho)
		if dados == null:
			continue
		afirmar(dados.nome != "" and dados.ataque != "" and dados.dica.length() > 20, "%s tem nome, ataque e dica" % caminho)
		afirmar(dados.vida > 0.0 and dados.velocidade > 0.0, "%s tem vida e velocidade" % caminho)
		afirmar(dados.ossos_min <= dados.ossos_max, "%s: faixa de ossos válida" % caminho)
		afirmar(Audio.existe(dados.som_acerto) and Audio.existe(dados.som_morte), "%s: sons existem" % caminho)
