# Documento de Design — CRYPTBOUND

Legenda de status: **[feito]** implementado e testado · **[planejado]** ainda não existe ·
**[provisório]** existe, mas será substituído/refinado.

Os números abaixo são os valores atuais do código/dados (fonte da verdade: `dados/` e os scripts
citados). Ao balancear, altere os dados e atualize esta tabela.

---

## 1. Controles [feito]

| Ação | Teclado e mouse | Controle |
|---|---|---|
| Mover (8 direções) | W A S D / setas | Analógico esquerdo / direcional |
| Mirar | Mouse | Analógico direito (senão, a direção do movimento) |
| Golpe (combo) | Botão esquerdo / J | X / RT |
| Golpe pesado (segurar) | Botão direito / K | Y / LT |
| Esquiva | Espaço / Shift / L | A / RB |
| Interagir | E / F | B |
| Pausa | Esc / P | Start |
| Tela cheia | F11 | — |

O mapa de entradas é registrado em código (`jogo/autoload/controles.gd`), o que prepara o
remapeamento persistente [planejado]. A mira por mouse só vale enquanto o mouse estiver sendo
usado; quem joga só no teclado (J/K/L) mira para onde anda.

## 2. A Coveira [feito]

- **Vida em velas**: começa com 6 (máximo absoluto 12). Golpes comuns apagam 1 vela.
  Depois de ser atingida, fica 0,9 s intocável (piscando).
- **Movimento**: 92 px/s; aceleração de ~0,1 s até o máximo; parada quase imediata.
- **Buffer de entrada**: comandos ficam guardados por 0,12 s. Golpe ou esquiva apertados
  *durante* um golpe ou uma esquiva saem assim que a janela permitir.
- **Esquiva**: 0,24 s, ~60 px, intocável nos primeiros 0,18 s, atravessa inimigos, deixa
  imagens residuais; recarga de 0,3 s. Cancela a antecipação e a recuperação dos golpes.
- **Lanterna**: luz quente presa à cintura — a Coveira sempre ilumina o próprio entorno.

### Pá de Coveiro (arma inicial) — `dados/armas/pa_de_coveiro.tres`

| Golpe | Dano | Arco | Alcance | Antecip. | Ativo | Recup. | Interrupção | Observação |
|---|---|---|---|---|---|---|---|---|
| Varrida | 10 | 120° | 28 px | 0,05 s | 0,07 s | 0,16 s | leve | avanço curto |
| Contra-varrida | 10 | 120° | 28 px | 0,05 s | 0,07 s | 0,18 s | leve | sentido oposto |
| Pancada | 18 | 70° | 32 px | 0,12 s | 0,08 s | 0,32 s | **forte** | etiqueta `golpe_final`, empurra 260 |
| Cavada (pesado) | 28 | 160° | 34 px | carga 0,45 s | 0,10 s | 0,38 s | **forte** | impacto no chão, empurra 300 |

O combo reinicia se passarem 0,45 s sem golpe. Cada acerto tem *hitstop* (45–120 ms),
tremor de tela proporcional, flash, empurrão, faíscas e estilhaços.

## 3. Postura e interrupção [feito]

Cada golpe tem nível de interrupção: **nenhuma**, **leve** ou **forte**. Durante o preparo e o
ataque, os inimigos só cedem a golpes **fortes** (pancada final do combo, cavada, badalo do Sino
Rachado); golpes leves ainda causam dano, mas empurram só 25%. Fora disso, qualquer golpe
causa um tranco curto. Isso dá função a cada parte do combo: os leves acumulam dano, o final
quebra a postura.

## 4. Inimigos

### Ressequido [feito] — `dados/inimigos/ressequido.tres`
Cadáver seco movido por raízes. Vida 30, 38 px/s.
- **Investida**: a menos de 46 px e com visão, prepara por **0,55 s** (tremor do corpo, olho
  de seiva brilhando, estalo seco). A mira acompanha a Coveira e **trava 0,15 s antes** do bote.
  Avança a 215 px/s por 0,24 s. Depois fica **0,75 s exposto**.
- **Resposta**: esquivar para o lado no fim do preparo e golpear durante a recuperação; ou
  quebrar o preparo com a pancada final/golpe pesado.
- Perto de uma Lamuriante fica **fortalecido** (45% mais rápido em tudo).

### Lamuriante [feito] — `dados/inimigos/lamuriante.tres`
Figura alta de cera e pano velado, com velas acesas derretendo sobre a cabeça. Vida 24.
- Mantém distância (78–150 px), rodeia, foge se a Coveira chega perto.
- **Lamúria**: canta por **0,75 s** (o rosto se abre num vazio roxo, a luz roxa cresce) e lança
  uma onda lenta (82 px/s). Paredes, pilares e objetos bloqueiam a onda; um golpe da Coveira
  a dissipa.
- **Fio de luz**: liga-se a todo Ressequido a até 112 px e o fortalece — o jogador vê
  exatamente quem está sendo fortalecido. **Prioridade**: derrubá-la primeiro.

### Surgimento e restos [feito]
Inimigos se erguem da terra (0,55 s, intocáveis, com poeira e terra). Ao morrer, desabam e
**os restos ficam no chão da sala** (a história da luta continua visível); soltam 2–5 ossos.

### Planejados
- *Emparedado*: cadáver preso a uma laje de cal usada como escudo frontal (pede flanco/esquiva por trás).
- Elites com modificadores; chefe da região (*A Mãe-Cal*, ossário vivo que se reconstrói com os restos da arena).

## 5. Estados alterados [feito: Sangria, Atordoado]

- **Sangria**: o alvo perde `3 × acúmulos` de vida **a cada 20 px que se move** (até 3 acúmulos,
  4 s). Ficar parado não sangra; **ser empurrado sangra**. Dano de estado não dispara efeitos
  de relíquias (evita ciclos).
- **Atordoado**: o alvo não age pela duração.
- Ao ser aplicado, o **nome do estado sobe sobre o alvo** na cor do estado: a combinação que
  acabou de acontecer fica legível no meio da luta.
- [planejado] Seiva, Brasa, Esporos, Eco, Pavor e **reações** entre eles (ex.: Seiva + Brasa =
  explosão resinosa), com tabela de reações em dados.

## 6. Relíquias e combinações [feito: 3 relíquias + sistema]

Sistema: cada relíquia tem efeitos com **gatilho** (`ao_adquirir`, `ao_acertar`, `ao_esquivar`,
`ao_sofrer_dano`, `ao_eliminar`, `ao_limpar_sala`), condições por **etiquetas** do golpe
(`requer_tags`/`proibe_tags`), chance e **recarga interna**. Golpes criados por efeitos herdam
**profundidade de encadeamento**; a partir de 2 níveis, nada mais dispara (sem loops infinitos).

| Relíquia | Raridade | Efeito |
|---|---|---|
| Presa de Cão-de-Cova | incomum | O golpe final do combo aplica Sangria. |
| Sino Rachado | rara | Ao esquivar, badalo que empurra (240) e atordoa (0,7 s) quem está a até 52 px; recarga 1,2 s. |
| Vela Perene | comum | +1 vela máxima, já acesa. |

**Combinação de exemplo (testada)**: Presa + Sino → o combo faz o alvo sangrar; a esquiva
seguinte o empurra para longe, e o empurrão *é* deslocamento: ele sangra sem precisar andar.

Relicário: uma sala por profundidade oferece até 3 relíquias que a Coveira ainda não tem;
escolher uma desfaz as outras em pó (uma mensagem avisa ao entrar). Quando não há relíquias
novas, os altares vazios guardam **oferendas**: três ossos cada e, se nenhum altar tiver
relíquia, um toco de vela, com a mensagem "Os altares estão vazios. Restam oferendas."
[planejado] Promessas como alternativa quando houver mais conteúdo.

## 7. Mundo e estrutura de uma descida [feito]

- **Profundidade**: sequência fixa de tipos com salas sorteadas pela semente:
  chegada → combate → relicário → combate → arena → poço de descida.
  Chegada: *Antecâmara das Velas* (1ª profundidade, com dicas de controle) ou *Patamar Úmido*.
  Combates sorteados entre *Galeria dos Pilares*, *Cripta dos Caixões* e *Passagem das Raízes*.
  Arena: *Ossuário Central* (duas ondas). Descida: *Poço da Descida* (escada).
- **Salas de combate**: ao entrar, as **raízes fecham as passagens**; as ondas se erguem; ao
  purificar, as raízes recuam. Chance de toco de vela (cura 1) ao purificar (maior se ferida).
- **Escalada por profundidade**: vida dos inimigos × (1 + 0,22 × (profundidade − 1)) e +1
  Ressequido extra na primeira onda por profundidade (até +3).
- **Ossos**: moeda coletada (atraída pela Coveira). [planejado] Contador de Ossos (loja) no M3.

### Regiões planejadas
Catacumbas de Cal (atual) → Jardim dos Ossos → Cisterna Afogada → Fundição dos Sinos →
O Ventre → Coração da Raiz.

## 8. Sistemas assinatura [planejado]

- **Restos e Sepultar**: sepultar um corpo (ação curta e arriscada) impede que inimigos como o
  *Semeador* o reergam e dá recurso; relíquias explodem, plantam ou levantam restos.
- **Cavar**: terra fofa com sinais visuais (flores, terra revolvida) esconde segredos.
- **Promessas**: pactos em altares — poder agora, condição a cumprir ou praga depois.
- **Esquiva perfeita**: esquivar no último instante de um ataque dá uma recompensa curta.

## 9. Interface [feito]

- HUD: velas animadas (a que apaga solta fumaça), ossos, profundidade e região, relíquias,
  dica de interação com a tecla do dispositivo atual, painel do item em foco (nome na cor da
  raridade, descrição, inscrição), mensagens e nome da sala.
- Pausa: continuar, recomeçar, configurações, menu principal, sair + lista das relíquias com
  descrições.
- Configurações: volumes (geral/música/efeitos), tremor de tela, tela cheia, sincronia vertical,
  números de dano — aplicadas e salvas na hora.
- **Tela de morte**: "Abatida por: <inimigo> — <ataque>", dica de resposta, estatísticas.
- Título: cripta viva ao fundo, logo, iniciar, configurações, créditos, sair, recorde e avisos
  de recuperação de arquivo.

## 10. Progressão e salvamento [feito: progresso básico]

Progresso entre descidas (descidas, mortes, maior profundidade, abates, salas, tempo,
relíquias vistas) em JSON com escrita atômica, backup e recuperação. [planejado] Santuário,
desbloqueios permanentes que ampliam possibilidades, salvar/continuar uma descida.

## 11. Modos [planejado]

Vigília (ondas progressivas), desafios com restrições, modificadores de descida, câmaras de
enigmas, encontros secretos — só depois de a aventura principal estar sólida.
