extends Node
## Barramento global de sinais. Sistemas desacoplados (HUD, áudio, efeitos, itens,
## estatísticas) escutam aqui em vez de conhecerem uns aos outros.

# Jogador
signal jogador_atingido(info: DanoInfo)
signal jogador_morreu(info: DanoInfo)
signal jogador_esquivou(jogador: Node2D)
signal velas_mudaram(atual: int, maximo: int)

# Combate
signal golpe_acertou(info: DanoInfo, alvo: Node2D)
signal inimigo_morreu(inimigo: Node2D, info: DanoInfo)
signal estado_aplicado(alvo: Node2D, estado_id: StringName)

# Salas e descida
signal sala_entrou(sala: Node)
signal combate_iniciou(sala: Node)
signal onda_iniciou(sala: Node, onda: int)
signal sala_limpa(sala: Node)
signal profundidade_mudou(profundidade: int)

# Itens e recursos
signal item_adquirido(item: ItemDados)
signal ossos_mudaram(total: int)

# Interface
signal mensagem(texto: String, duracao: float)
signal dica_interacao(texto: String)
