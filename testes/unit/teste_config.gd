extends CasoTeste
## Configurações: ida e volta pelo arquivo, valores inválidos viram padrão, e as opções
## realmente mudam o jogo. Roda sobre user://testes/config.cfg (nunca o arquivo real).

var _copia: Dictionary


func antes_de_cada() -> void:
	_copia = Config._valores.duplicate(true)


func depois_de_cada() -> void:
	Config._valores = _copia
	Config.salvar()
	Config.aplicar_tudo()
	Config.aviso_pendente = ""


func teste_ida_e_volta_pelo_arquivo() -> void:
	afirmar(Config.caminho.begins_with("user://testes/"), "arquivo isolado dos testes")
	Config.definir(&"audio", &"musica", 0.25)
	Config.definir(&"jogo", &"numeros_dano", false)
	Config._valores = Config.PADROES.duplicate(true)
	Config.carregar()
	afirmar_proximo(float(Config.obter(&"audio", &"musica")), 0.25, 0.0001, "volume da música relido")
	afirmar_igual(Config.obter(&"jogo", &"numeros_dano"), false, "números de dano relidos")
	afirmar_proximo(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Musica"))), 0.25, 0.01, "volume aplicado ao barramento")


func teste_valores_invalidos_viram_padrao_com_aviso() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value(&"audio", &"geral", "alto")
	arquivo.set_value(&"audio", &"efeitos", 7.5)
	arquivo.set_value(&"jogo", &"tremor", 0)
	arquivo.save(Config.caminho)
	Config.aviso_pendente = ""
	Config.carregar()
	afirmar_proximo(float(Config.obter(&"audio", &"geral")), 0.8, 0.0001, "texto no lugar de número volta ao padrão")
	afirmar_proximo(float(Config.obter(&"audio", &"efeitos")), 1.0, 0.0001, "volume acima de 1 é limitado")
	afirmar_proximo(float(Config.obter(&"jogo", &"tremor")), 0.0, 0.0001, "inteiro aceito como número (tremor desligado)")
	afirmar(Config.aviso_pendente != "", "o jogador é avisado de que algo foi restaurado")


func teste_arquivo_ilegivel_recomeca_dos_padroes() -> void:
	esperar_erro("ConfigFile parse error")
	var f := FileAccess.open(Config.caminho, FileAccess.WRITE)
	f.store_string("[audio\ngeral = = =\n")
	f.close()
	Config.aviso_pendente = ""
	Config.carregar()
	afirmar_proximo(float(Config.obter(&"audio", &"geral")), 0.8, 0.0001, "padrão restaurado")
	afirmar(Config.aviso_pendente != "", "aviso de configuração restaurada")


func teste_opcao_de_tremor_e_de_numeros_muda_o_jogo() -> void:
	Efeitos.limpar_registro()
	Config.definir(&"jogo", &"tremor", 0.0)
	Efeitos.tremer(0.5, Vector2.RIGHT)
	afirmar_proximo(Efeitos.trauma, 0.0, 0.0001, "tremor desligado não treme")
	afirmar_proximo(Efeitos.chute.length(), 0.0, 0.0001, "nem recua a câmera")
	var m := MundoTeste.criar(self)
	Config.definir(&"jogo", &"numeros_dano", true)
	Efeitos.numero(Vector2(100, 100), 3.0)
	afirmar_igual(m.numeros._lista.size(), 1, "números de dano ligados aparecem")
	Config.definir(&"jogo", &"numeros_dano", false)
	Efeitos.numero(Vector2(200, 100), 3.0)
	afirmar_igual(m.numeros._lista.size(), 1, "desligados, não aparecem")
	m.queue_free()
	Efeitos.limpar_registro()


func teste_painel_acompanha_mudanca_feita_fora_dele() -> void:
	var painel := PainelConfig.new()
	add_child(painel)
	Config.definir(&"jogo", &"numeros_dano", true)
	var botao := _botao_com_texto(painel, Textos.t("config.numeros_dano"))
	afirmar(botao != null, "o painel tem a opção de números de dano")
	if botao:
		afirmar(botao.text.ends_with(Textos.t("config.ligado")), "mostra ligado")
		# Como o F11 faz com a tela cheia: muda a opção sem passar pelo painel.
		Config.definir(&"jogo", &"numeros_dano", false)
		afirmar(botao.text.ends_with(Textos.t("config.desligado")), "o texto acompanha a mudança")
	painel.queue_free()


func _botao_com_texto(raiz: Node, comeco: String) -> Button:
	for no in raiz.find_children("*", "Button", true, false):
		if (no as Button).text.begins_with(comeco):
			return no as Button
	return null
