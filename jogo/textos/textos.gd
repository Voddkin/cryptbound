class_name Textos
extends RefCounted
## Todos os textos de interface exibidos ao jogador, em português brasileiro.
## Nomes e descrições de itens, armas e inimigos ficam nos próprios recursos em `dados/`.
## Use `Textos.t("chave")` ou `Textos.t("chave", {"n": 3})` para textos com campos {n}.

const TEXTOS: Dictionary[String, String] = {
	# Título e menus
	"titulo.subtitulo": "A terra parou de aceitar os mortos.",
	"titulo.iniciar": "Iniciar descida",
	"titulo.configuracoes": "Configurações",
	"titulo.creditos": "Créditos",
	"titulo.sair": "Sair",
	"titulo.versao": "Versão {v} — protótipo em desenvolvimento",
	"titulo.recorde": "Maior profundidade alcançada: {n}",

	"pausa.titulo": "Pausa",
	"pausa.continuar": "Continuar",
	"pausa.recomecar": "Recomeçar descida",
	"pausa.configuracoes": "Configurações",
	"pausa.menu": "Voltar ao menu principal",
	"pausa.sair": "Sair do jogo",
	"pausa.reliquias": "Relíquias carregadas",
	"pausa.sem_reliquias": "Nenhuma relíquia ainda.",

	"config.titulo": "Configurações",
	"config.volume_geral": "Volume geral",
	"config.volume_musica": "Música",
	"config.volume_efeitos": "Efeitos sonoros",
	"config.tela_cheia": "Tela cheia",
	"config.vsync": "Sincronia vertical",
	"config.tremor": "Tremor de tela",
	"config.numeros_dano": "Números de dano",
	"config.voltar": "Voltar",
	"config.ligado": "Ligado",
	"config.desligado": "Desligado",

	"creditos.titulo": "Créditos",
	"creditos.texto": "CRYPTBOUND\n\nDireção, programação, arte provisória e áudio provisório:\nprojeto desenvolvido com o auxílio do Claude (Anthropic).\n\nMotor: Godot Engine 4.7 (licença MIT).\n\nFontes (SIL Open Font License 1.1):\nJacquard 12, Jersey 10 e Micro 5 — The Soft Type Project Authors.\n\nObrigado por jogar.",
	"creditos.voltar": "Voltar",

	# HUD
	"hud.profundidade": "Profundidade {n}",
	"hud.regiao.catacumbas": "Catacumbas de Cal",
	"hud.interagir": "[{tecla}] {acao}",
	"hud.pegar": "Pegar {nome}",
	"hud.descer": "Descer mais fundo",
	"hud.sala_limpa": "As raízes recuam.",
	"hud.portas_trancadas": "As raízes fecham a passagem!",
	"hud.onda": "Mais deles se erguem…",
	"hud.escolha_reliquia": "Escolha uma relíquia. As outras voltarão ao pó.",
	"hud.nova_profundidade": "Profundidade {n}. O ar fica mais pesado.",
	"hud.vela_acesa": "Uma vela se acende.",
	"hud.vida_cheia": "Suas velas já ardem todas.",

	# Dicas de controle exibidas na primeira sala
	"dica.mover": "Mova-se com {tecla}.",
	"dica.atacar": "{tecla}: golpe com a pá. Golpes seguidos formam um combo de três.",
	"dica.pesado": "Segure {tecla}: pancada carregada que empurra e interrompe.",
	"dica.esquivar": "{tecla}: esquiva. Você fica intocável no início do movimento.",

	# Morte
	"morte.titulo": "Você tombou",
	"morte.abatida_por": "Abatida por: {inimigo} — {ataque}",
	"morte.dica": "Dica: {dica}",
	"morte.estatisticas": "Profundidade {prof}   ·   Salas purificadas {salas}   ·   Inimigos abatidos {abates}   ·   Ossos {ossos}   ·   Tempo {tempo}",
	"morte.de_novo": "Descer de novo",
	"morte.menu": "Menu principal",
	"morte.desconhecido": "algo nas sombras",

	# Estados
	"estado.sangria": "Sangria",
	"estado.atordoado": "Atordoado",

	# Erros apresentáveis
	"erro.salvamento_corrompido": "O arquivo de progresso estava danificado. Uma cópia de segurança foi restaurada.",
	"erro.salvamento_perdido": "O arquivo de progresso estava danificado e não pôde ser recuperado. Um novo progresso foi iniciado.",
	"erro.configuracao": "As configurações estavam inválidas e foram restauradas ao padrão.",

	# Teclas (para dicas)
	"tecla.mover_teclado": "W A S D",
	"tecla.mover_controle": "o analógico esquerdo",
	"tecla.mouse_esquerdo": "Botão esquerdo",
	"tecla.mouse_direito": "Botão direito",
	"tecla.espaco": "Espaço",
}


static func t(chave: String, campos: Dictionary = {}) -> String:
	if not TEXTOS.has(chave):
		push_error("Texto ausente: %s" % chave)
		return chave
	var texto: String = TEXTOS[chave]
	if not campos.is_empty():
		texto = texto.format(campos)
	return texto


static func existe(chave: String) -> bool:
	return TEXTOS.has(chave)
