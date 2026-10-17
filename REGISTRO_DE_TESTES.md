# Registro de Testes — CRYPTBOUND

Registro do que foi **de fato executado** e do resultado obtido. O que não foi testado
está listado no fim, com o motivo. Ambiente de desenvolvimento: Ubuntu 24.04 em contêiner
(4 vCPUs, sem GPU, sem placa de som), Godot 4.7.2-stable, renderização por software
(Mesa llvmpipe) quando há janela.

---

## 1. Testes automatizados

```bash
ferramentas/testar.sh            # importa, roda tudo headless com --fixed-fps 60
ferramentas/testar.sh salvamento # só testes cujo arquivo ou nome contém o filtro
```

O executor (`testes/executar_testes.gd`) captura **todo erro do motor** por um `Logger`
(`OS.add_logger`): um erro inesperado reprova o teste mesmo que as afirmações passem; erros
provocados de propósito são declarados com `esperar_erro()`. Script com erro de compilação
também reprova. Com `--fixed-fps 60` a simulação é determinística.

**Último resultado (17/10/2026): `RESULTADO: 68 testes, 0 falhas (1.4s)`.**

| Arquivo | Testes | O que garante |
|---|---|---|
| `unit/teste_estados.gd` | 5 | Sangria causa dano por distância (não parada), acumula até 3, estados expiram, fábrica conhece todos |
| `unit/teste_gatilhos.gd` | 4 | Etiquetas exigidas, limite de encadeamento (2), recarga interna, profundidade em golpes derivados |
| `unit/teste_caixa_golpe.gd` | 3 | Um acerto por ativação; desativar+ativar no mesmo quadro funciona; alvo fora do alcance |
| `unit/teste_salvamento.gd` | 7 | Caminho isolado nos testes, ida e volta, corrompido → backup, `.tmp` mais novo vence, sem backup recomeça, tipos inválidos rejeitam o arquivo, versão antiga ganha campos novos |
| `unit/teste_config.gd` | 5 | Configurações: ida e volta, valores inválidos viram padrão com aviso, arquivo ilegível, opções de tremor e números de dano mudam o jogo, painel acompanha mudança feita fora dele (F11) |
| `unit/teste_efeitos.gd` | 3 | Hitstop pedido na física dura o tempo certo; tremor e recuo sobrevivem ao quadro do impacto; hitstop dentro da câmera lenta volta para a câmera lenta |
| `unit/teste_dados.gd` | 3 | Arma, todas as relíquias e todos os inimigos carregam com classe certa e textos pt-BR preenchidos |
| `unit/teste_salas.gd` | 5 | As 9 salas são válidas e montam com colisão e chão completos, portas, caminho até a saída; validador rejeita salas quebradas; faces 3/4 das paredes; caminho e visão para quem encosta em objetos baixos |
| `unit/teste_textos.gd` | 4 | Toda chave usada existe; toda chave definida é usada (nada de mensagem morta); nada de "TODO", texto provisório ou inglês acidental em textos e dados; campos formatados |
| `simulacao/teste_jogador.gd` | 8 | 8 direções sem passar da velocidade, aceleração curta, colisão com parede, esquiva intocável e útil, golpe na cauda da esquiva restaura colisão, combo mata Ressequido, buffer de ataque durante a esquiva |
| `simulacao/teste_inimigos.gd` | 10 | Ressequido telegrafa, investe e acerta; aviso ≥ 0,5 s (também fortalecido); só golpe forte interrompe; Lamuriante fortalece e lança Lamúria; Lamuriante sem linha de tiro contorna o obstáculo e lança; morte solta ossos e deixa restos; Lamúria some com a sala purificada; restos apagam as luzes e não atravessam paredes |
| `simulacao/teste_reliquias.gd` | 5 | Vela Perene; Presa aplica Sangria só no golpe final; Sino empurra e atordoa ao esquivar; combinação Sino + Sangria; o nome do estado aplicado sobe sobre o alvo (uma vez) |
| `simulacao/teste_fluxo.gd` | 6 | Sala tranca, ergue ondas e libera; ninguém sai do mapa pela passagem de entrada; relicário sem relíquias novas oferece oferendas e explica; relicário com relíquias avisa que só uma pode ser levada; saída aberta leva adiante; morte mostra a causa, registra no progresso e encerra a câmera lenta |

Os testes de simulação montam uma sala real (`MundoTeste`) com a Coveira controlada por uma
fonte de entrada de teste, ou seja, passam pelo mesmo código do jogo.

## 2. Revisões adversariais (revisores independentes + verificação cética)

### 1ª revisão — fundação (16–17/10/2026)
Quatro dimensões: GDScript/API do Godot 4.7.2, salvamento e testes, pipelines Python, desenho
do M1. **23 achados confirmados, todos corrigidos** (commits `a45c2c3` e `554f934`). Os mais
graves: o executor de testes dava falso positivo (erros de execução não reprovavam, script
inválido era ignorado); janelas de perda de dados no salvamento; hitstop medido em relógio
real; caixa de golpe "morta" ao desativar e ativar no mesmo quadro; dano aplicado durante o
flush da física; dois donos da escala de tempo; defeitos nos geradores de arte e áudio.

### 2ª revisão — M1 jogável (17/10/2026)
Quatro dimensões: Coveira e combate, inimigos, mundo e salas, interface. Todos os achados
foram corrigidos, **cada um com teste que falha no código anterior e passa no novo**:

| Gravidade | Achado | Correção |
|---|---|---|
| Alta | Hitstop, tremor e recuo de câmera eram cancelados no quadro do impacto (o motor lê `Engine.time_scale` no início do quadro; o tempo era medido com a escala nova) | `Efeitos` é o único que grava a escala, só no próprio `_process` |
| Média | Golpe na cauda vulnerável da esquiva deixava a Coveira atravessando inimigos | `_sair_da_esquiva()` também ao ser atingida |
| Média | Inimigos paravam e o Ressequido não atacava quando a Coveira encostava em caixões/crânios | Caminho usa a célula andável vizinha; visão ignora as células das pontas |
| Média | Fortalecimento da Lamuriante encurtava o aviso da investida para 0,38 s | O preparo não acelera mais (aviso ≥ 0,5 s) |
| Baixa | Cadáver atravessava paredes com o empurrão do golpe final | Cadáver continua colidindo com o cenário |
| Baixa | Lamúria em voo tirava vela depois de a sala ser purificada | Desfaz-se em `sala_limpa` |
| Baixa | Luzes de aviso continuavam acesas nos restos | Luzes se apagam na morte |
| Baixa | Dica do golpe pesado descrevia o golpe errado | Texto corrigido |
| Alta | Dava para sair do mapa pela passagem de entrada; se o combate começasse com a Coveira lá fora, a descida travava (no código antigo o teste a encontrou 100 px fora do mapa, com a sala trancada) | Limite físico permanente além de toda passagem; o combate só começa com a Coveira numa célula andável da sala |
| Baixa | Relicário vazio a partir da profundidade 4 (só há 3 relíquias) | Altares vazios guardam oferendas (ossos; um toco de vela se nenhum tiver relíquia) e uma mensagem explica |

**Como a revisão terminou:** os revisores de Coveira, inimigos e mundo concluíram. O
verificador da Coveira confirmou que as três correções estavam no código. Os verificadores de
inimigos e mundo e o **revisor de interface não rodaram**: a sessão bateu no limite de uso.
No lugar deles: cada achado ganhou um teste de regressão (prova mais forte que um parecer), e a
interface foi revisada por mim, sem revisor independente. Essa revisão própria achou e corrigiu:

| Achado | Correção |
|---|---|
| Quatro textos definidos e nunca exibidos: a instrução do relicário ("Escolha uma relíquia. As outras voltarão ao pó."), o título dos créditos e os nomes dos estados | A instrução aparece ao entrar num relicário com mais de uma relíquia; o nome do estado (Sangria, Atordoado) sobe sobre o alvo quando é aplicado, deixando a combinação legível; créditos com título. Novo teste reprova chave definida e nunca usada |
| Com o painel de configurações aberto, o F11 mudava a tela cheia mas o texto da opção ficava velho | O painel escuta `Config.mudou` |
| Com o título novo, o painel de créditos passava da borda da tela e escondia o botão Voltar (visto na captura) | Texto mais enxuto e o painel nunca ultrapassa a tela |

Confirmação do hitstop em jogo real (robô de demonstração, 1500 quadros a 60 fps fixos):
o código anterior congelou **0 quadros em 15 acertos**; o corrigido congela ~4 quadros por
acerto (24 quadros em 6 acertos, incluindo golpes sofridos pela Coveira, que congelam mais).

Fora da revisão, na mesma rodada: o jogo vazava a reprodução da música ao fechar
(`resources still in use at exit`). Agora sair (botão ou janela) registra a descida,
silencia o áudio e fecha 0,1 s depois, sem vazamento (verificado com `--verbose`).

## 3. Teste de fumaça: o robô joga descidas inteiras

`testes/fumaca/robo_fumaca.tscn` (fora da suíte): o robô de demonstração joga descidas com
várias sementes, sem renderização e em quadros fixos, e o roteiro aponta onde ele **travou**
(60 s de jogo sem progresso), morreu ou chegou à profundidade-alvo. Uma rodada de 40 descidas
leva menos de um minuto.

```bash
godot --headless --fixed-fps 60 --path . res://testes/fumaca/robo_fumaca.tscn -- --demo \
  --sementes=1,2,3 --prof=4
```

Como surgiu: o `.exe` rodando no Wine mostrou a mesma cena congelada aos 20, 45 e 75 s — o
robô encostado num bloco de parede e uma Lamuriante parada do outro lado, numa sala trancada.
A investigação achou quatro defeitos:

| Defeito | Onde | Correção |
|---|---|---|
| Lamuriante sem linha de tiro ficava indecisa para sempre entre fugir (< 78 px) e se aproximar pelo A*, sem nunca lançar | Jogo (IA) | Sem linha de tiro, ela contorna o obstáculo; só foge se tiver linha de tiro (teste novo) |
| O caminho do A* começa no centro da célula atual: inimigos voltavam até ele a cada recálculo (tranco a cada 0,35 s) e o robô ia e voltava dentro da mesma célula para sempre | Jogo e robô | O primeiro ponto do caminho é descartado |
| O áudio usava o relógio de parede para não repetir sons e consumia o gerador aleatório global: a mesma semente produzia descidas diferentes | Jogo | Áudio com gerador próprio e relógio de tempo de jogo; a descida semeia o gerador global (`-- --semente=N` reproduz uma descida) |
| O robô parava no meio da passagem de saída, antes do gatilho | Robô | Mira além da borda externa (o limite da passagem o segura dentro do gatilho) |

**Resultado (17/10/2026), 40 sementes:** nenhuma descida travou; profundidade final 1 em 14,
2 em 20 e 3 em 6; mortes por sala: arena 22, caixões 7, estreita 6, pilares 5. Duas rodadas
seguidas deram saídas **idênticas** (determinismo confirmado). O robô é burro de propósito
(não esquiva da Lamúria nem se afasta), então as mortes **não medem a dificuldade para uma
pessoa**; só mostram que a arena é o pico de pressão da profundidade.

## 4. Verificação visual

| O quê | Como | Resultado |
|---|---|---|
| Arte provisória (tiles, Coveira, inimigos, objetos, HUD) | Folhas renderizadas ampliadas e inspecionadas | Problemas encontrados e corrigidos: Ressequido com silhueta de elefante, chamas em cruz, "rosto de robô" no altar, piso ruidoso, topo das paredes escuro demais |
| 10 telas (título, créditos, antecâmara com dicas, painel de relíquia, pausa, configurações, combate com nomes de estados, relicário vazio, Coveira tombando, tela de morte) | `testes/captura/capturar_telas.tscn` sob Xvfb | 5 problemas corrigidos (painel sobre as dicas, configurações sobre relíquias, estatísticas da morte, menu do título, créditos passando da tela) |
| Ciclo completo jogado pelo robô | Movie Maker (`--write-movie`) sob Xvfb, 30 fps fixos, quadros extraídos com ffmpeg | Entrada → combate → relicário (pega relíquia) → combate → arena (2 ondas) → descida → profundidade 2. Vídeo gravado **antes** da correção do hitstop |

## 5. Áudio

42 efeitos e 3 músicas (camadas de exploração e combate) gerados por síntese. Verificado
**numericamente**: picos abaixo de 0 dBFS, emenda do loop sem descontinuidade (frequências
quantizadas a ciclos inteiros), agudos filtrados após análise espectral. **Nenhum som foi
ouvido por um humano.**

## 6. Exportação e execução fora do editor

| Verificação | Resultado |
|---|---|
| `ferramentas/exportar.sh` (Windows Desktop + Linux) | ✅ `build/windows/CRYPTBOUND.exe` (~113 MB, PCK embutido) e `build/linux/cryptbound.x86_64` |
| Cabeçalho PE (`pefile`) | ✅ PE32+ x86-64, 6 ícones embutidos, ProductName CRYPTBOUND, FileVersion 0.1.0.0, CompanyName Voddkin |
| Linux exportado sob Xvfb (`-- --demo`) | ✅ abre, renderiza (OpenGL 4.5 Mesa) e joga; capturas conferidas |
| Windows no **Wine 9.0** (Ubuntu 24.04) | ❌ cai na inicialização: falha de página dentro do `kernelbase` do Wine (`VirtualProtect` com ponteiro nulo no código de inicialização do MinGW) |
| Windows no **Wine 11.18** WoW64 (Kron4ek) | ✅ sem renderização termina com sucesso; com renderização abre o OpenGL 4.5 (Mesa) e roda a demonstração; capturas conferidas. Avisos de WASAPI (sem placa de som) esperados |

## 7. Desempenho

`testes/desempenho/estresse.tscn`: descida real com o robô, 30 inimigos erguidos de uma
vez (Ressequidos e Lamuriantes) e rajadas de partículas a cada 20 quadros; 900 quadros
medidos após 120 de aquecimento, sem limite de FPS.

| Cenário | Tempo médio de quadro | p95 | Pior | Física por passo |
|---|---|---|---|---|
| Sem renderização, linha de base (0 inimigos extras) | 6,9 ms | 7,7 ms | 11,6 ms | 2,0 ms |
| Sem renderização, 30 inimigos | 6,9 ms | 11,0 ms | 14,3 ms | 6,0 ms |
| llvmpipe (CPU), linha de base | 17,4 ms (58 FPS) | 22,0 ms | 46,0 ms | 1,7 ms |
| llvmpipe (CPU), 30 inimigos | 25,7 ms (39 FPS) | 35,0 ms | 46,2 ms | 3,8 ms |

Leitura: a lógica do jogo com 30 inimigos cabe com folga em 16,6 ms; o custo dominante aqui é
a renderização **por software**, que numa GPU real é muito menor. São números pessimistas
de uma CPU de servidor, **não** de um PC de jogador. Os quadros mais lentos (~46 ms) aparecem
também na linha de base e coincidem com picos da renderização por software. As salas de
combate têm de 5 a 9 inimigos somando as ondas (mais até 3 reforços nas profundidades altas).

## 8. O que NÃO foi testado

- **Windows real** (só Wine 11.18).
- **Playtest humano**: sensação de controle, dificuldade e clareza nunca foram avaliadas por
  uma pessoa jogando.
- **Controle físico (gamepad)**: o mapeamento existe, mas nunca foi usado com um controle.
- **Áudio audível** (sem placa de som; só análise numérica).
- **GPU real** e monitores de alta taxa de atualização.
- **Resoluções e escalas** além de 1280×720 (a escala inteira foi conferida só em teoria e
  no código do Godot).
- **Descidas longas** (profundidades altas) além da profundidade 2 no vídeo e da escalada
  calculada em teste.
