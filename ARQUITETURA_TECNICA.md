# Arquitetura Técnica — CRYPTBOUND

## Engine e configuração

- **Godot 4.7.2-stable**, GDScript com tipagem estática.
- Renderizador **Compatibility (OpenGL 3)**: maior alcance em PCs Windows modestos; roda no
  Mesa por software (testes em contêiner). Exportação Windows inclui ANGLE (reserva D3D11).
- Resolução-base **640×360**, `stretch = viewport`, escala **inteira**, filtro *nearest*,
  `snap_2d_transforms/vertices_to_pixel`. Janela inicial 1280×720.
- Física a **60 Hz** com **interpolação de física** ligada (a `Camera2D` precisa do modo de
  física; teleportes chamam `reset_physics_interpolation()`).
- `config/use_custom_user_dir`: dados do jogador em `%APPDATA%\CRYPTBOUND` (Windows) e
  `~/.local/share/CRYPTBOUND` (Linux).

Por que Godot e não outra engine: 2D maduro, exportação Windows a partir do Linux sem Wine
(desde a 4.5 o ícone e os metadados do `.exe` são gravados nativamente), modo headless para
testes e Movie Maker para vídeos determinísticos. C# exigiria .NET e complicaria a exportação.

## Estrutura de pastas

```
project.godot, export_presets.cfg, icon.png, *.md
jogo/
  autoload/   controles, config, eventos, audio, efeitos, salvamento, jogo
  nucleo/     DanoInfo, CaixaGolpe, CaixaDano, Estado(s), estados concretos, FabricaEstados,
              BibliotecaSprites, Ambiente
  itens/      ItemDados, EfeitoDados (+ efeitos/), GolpeDados, ArmaDados, Gatilhos, ContextoEfeito
  entidades/  jogador/ (Jogador, ArmaPortada, RastroGolpe, FonteEntrada, EntradaHumana, RoboDemo)
              inimigos/ (Inimigo, Ressequido, Lamuriante, ProjetilLamuria, InimigoDados, Fábrica)
  mundo/      DefinicaoSala, ConstrutorSala, Sala, Porta, Altar, Escada, Coletavel, Interagivel,
              TilesetCatacumbas, LuzTremulante, Descida (+ descida.tscn)
  interface/  Hud, VelasHud, MenuPausa, PainelConfig, TelaMorte, tela de título, Tema, BotaoMenu,
              CameraJogo, Fontes
  efeitos/    SistemaParticulas, ManchasChao, NumerosDano, AnelOnda, shaders/entidade.gdshader
  textos/     Textos (todos os textos de interface em pt-BR)
dados/        armas/, itens/, inimigos/ (.tres) e salas/catacumbas/ (.txt)
arte/         PNG + JSON gerados       audio/  sfx/ (WAV) e musica/ (OGG) gerados
fontes/       fontes bitmap BMFont geradas + OFL.txt
ferramentas/  arte/ e audio/ (geradores Python), testar.sh, exportar.sh  (pasta com .gdignore)
testes/       executor, CasoTeste, unit/, simulacao/, captura/ (telas), desempenho/ (estresse)
```

## Autoloads (ordem importa)

| Autoload | Papel |
|---|---|
| `Controles` | Registra o mapa de ações em código; detecta teclado/mouse × controle; nome da tecla para dicas. |
| `Config` | Opções em `config.cfg`; valida tipos e faixas; aplica volume/tela/vsync. |
| `Eventos` | Barramento de sinais (HUD, áudio, estatísticas e itens não se conhecem). |
| `Audio` | Cria barramentos (Música, Efeitos com reverb, limitador no Master); variações de SFX; música em 2 camadas sincronizadas (exploração + combate) com transição de volume. |
| `Efeitos` | Dono único de `Engine.time_scale`, gravado só no próprio `_process` (o motor lê a escala no início do quadro, então o `delta` seguinte foi escalado exatamente pelo valor gravado): hitstop e câmera lenta pedidos valem a partir do quadro seguinte, contados em tempo não escalado e determinísticos com `--fixed-fps`; tremor por trauma, partículas, manchas, números, anéis. |
| `Salvamento` | Progresso JSON versionado; escrita atômica (ver abaixo). |
| `Jogo` | Estado da descida (velas, ossos, relíquias, profundidade, semente, estatísticas) e troca de cenas. |

`Ambiente` (classe estática) detecta modo de teste (`executar_testes.tscn`) e demonstração
(`-- --demo`); nesses modos os dados graváveis vão para `user://testes/` e `user://demo/`.

## Combate

- **DanoInfo**: valor, atacante, direção, empurrão, nível de interrupção, hitstop, tremor,
  etiquetas (`leve`, `golpe_final`, `pesado`, `estado`, `onda`…), velas (dano na Coveira),
  textos para a tela de morte e **profundidade de encadeamento** (máx. 2).
- **CaixaGolpe / CaixaDano** (Area2D): o golpe acerta cada alvo uma vez por ativação.
  Ligar/desligar o monitoramento é sempre adiado (FIFO) e o dano é aplicado com `call_deferred`
  fora do *flush* de consultas da física — o alvo pode mudar a própria física ao morrer.
- Camadas: 1 mundo, 2 jogador (corpo e CaixaDano), 3 inimigos (corpo e CaixaDano),
  7 interagíveis. A esquiva tira a camada 3 da máscara da Coveira (atravessa inimigos).
- **Estados**: contêiner por entidade que mede a distância percorrida a cada quadro (base da
  Sangria) e soma realce de cor ao shader.
- **Gatilhos**: despacham eventos da Coveira para os efeitos das relíquias, com etiquetas,
  chance, recarga interna e limite de encadeamento.

## Coveira (Jogador)

Máquina de estados por enum (`Situacao`: LIVRE, ATACANDO, CARREGANDO, ESQUIVANDO, ATINGIDO,
MORTO, PARADO). Fases de golpe: antecipação → ativo → recuperação, com janela de cancelamento
por golpe. A entrada vem de uma `FonteEntrada` injetável — `EntradaHumana` (teclado/mouse/
controle), fonte de teste ou `RoboDemo` — o que permite simulação determinística e vídeos.

## Inimigos

`Inimigo` (base): surgimento, flash/realce via shader, empurrão separado da velocidade da IA,
postura (`pode_ser_interrompido`), morte com restos, ossos, barra de vida, navegação
(linha reta com visão; senão A* da sala, recalculado a cada 0,35 s) e separação entre inimigos.
Subclasses implementam `_configurar` e `_pensar` com FSM por enum.

## Salas

- **Formato** (`dados/salas/<regiao>/<nome>.txt`): cabeçalho `chave: valor` + `---` + grade.
  Legenda em `jogo/mundo/definicao_sala.gd`. Parede norte com 3 linhas (topo + face de 2 tiles).
- **Validação** (`DefinicaoSala`): retangular, bordas fechadas exceto passagens, passagens
  declaradas existem, tudo que importa é alcançável (inundação a partir da chegada).
- **Montagem** (`ConstrutorSala`, determinística pela semente): camadas `Chao` (z −20),
  `Manchas` (−19), `Sombra` (−18, oclusão ambiente com máscara de 8 vizinhos), `Decalques` (−17)
  e `Mundo` (y-sort) com `Paredes` (TileMapLayer y-sorted: topo com máscara de 8 vizinhos →
  256 variações; faces cima/baixo/única com pontas), objetos, portas, altares e entidades.
- **TileSet em código** (`TilesetCatacumbas`): camada de física → `add_source` →
  `create_tile` → polígonos de colisão (ordem obrigatória na 4.7).
- **Sala** (runtime): espera a Coveira entrar, tranca as portas, ergue ondas, libera,
  oferece `caminho()` (AStarGrid2D) e `visao_livre()` (amostragem em grade).
- **Descida**: monta a sequência da profundidade, troca de sala com cortina, reposiciona a
  Coveira (reparent para o `Mundo` da sala nova), câmera com limites centralizando salas
  pequenas, HUD, pausa, morte e passagem de profundidade.

## Dados de conteúdo

| Tipo | Classe | Onde |
|---|---|---|
| Arma | `ArmaDados` + `GolpeDados` | `dados/armas/*.tres` |
| Relíquia | `ItemDados` + `EfeitoDados` (subclasses) | `dados/itens/*.tres` (descobertas por `ResourceLoader.list_directory`) |
| Inimigo | `InimigoDados` (+ script de comportamento) | `dados/inimigos/*.tres` |
| Sala | `DefinicaoSala` | `dados/salas/catacumbas/*.txt` |

Adicionar uma relíquia com efeitos existentes = um `.tres` novo, sem código.

## Arte, áudio e fontes (pipelines determinísticos)

- `python3 ferramentas/arte/gerar_arte.py`: tiles, personagens (grades de texto + partes
  procedurais), objetos, itens, interface, luzes, vinheta, ícone e fontes.
  Sprites saem como folha PNG + JSON (`quadro`, `colunas`, `origem` nos pés, animações com fps
  e loop, pontos nomeados). `BibliotecaSprites` monta `SpriteFrames` com cache.
- `python3 ferramentas/audio/gerar_sfx.py` e `gerar_musica.py`: sintetizador em numpy
  (osciladores, ruído, filtros por FFT, sinos inarmônicos, reverb por convolução — circular nas
  músicas para o loop emendar sem estalo; frequências contínuas quantizadas a ciclos inteiros).
- Fontes: TTF OFL convertidas em BMFont na grade exata (renderização 8× + amostragem do centro,
  sem efeito de *hinting*); `FontFile.fixed_size_scale_mode = INTEGER_ONLY`.

## Salvamento

`progresso.json` com versão e validação de tipos. Gravação: escreve `.tmp`, **relê e valida**;
o principal válido vira `.bak` por **renomeação**; o `.tmp` vira o principal. Leitura:
principal → `.tmp` (mais novo) → `.bak`; arquivo danificado é preservado como `.corrompido` e o
jogador vê um aviso em pt-BR no título.

## Testes

- Executor próprio: `ferramentas/testar.sh` → `godot --headless --fixed-fps 60 --path .
  res://testes/executar_testes.tscn`. Falha se: afirmação falhar, o motor registrar erro de
  script durante o teste (capturado por um `Logger`), não houver afirmação, estourar o tempo,
  ou o script de teste for inválido. Vigia global encerra o processo se algo travar.
- `MundoTeste` monta uma sala real com a Coveira controlada pelo teste.

## Exportação

`ferramentas/exportar.sh` → `build/windows/CRYPTBOUND.exe` (x86_64, PCK embutido, ícone e
versão gravados) e `build/linux/cryptbound.x86_64`; confere o PE com `pefile`. Os filtros
incluem `*.json` e `*.txt` (metadados de sprites e salas) e excluem `testes/`, `ferramentas/`.

## Armadilhas aprendidas

- Um `enum Estado` dentro de uma classe conflita com a classe global `Estado` → enums renomeados
  para `Situacao`.
- Ternário com `[]` gera `Array` sem tipo; atribuir a `Array[T]` falha em tempo de execução.
- `Camera2D` com interpolação de física: definir `process_callback = PHYSICS` no `_init`.
- `area_entered` roda durante o *flush* da física: aplicar dano adiado.
- Wine 9.0 (Ubuntu 24.04) derruba o `.exe` do Godot 4.7 no código de inicialização do MinGW
  (`VirtualProtect` com ponteiro nulo); o Wine 11.18 roda normalmente. O Windows real não
  tem esse problema.
