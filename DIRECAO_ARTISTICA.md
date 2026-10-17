# Direção Artística — CRYPTBOUND

> Toda a arte atual é **provisória**, gerada por código em `ferramentas/arte/` e revisada
> visualmente. Ela estabelece a linguagem (paleta, escala, leitura, iluminação) que a arte
> definitiva deve seguir. Substituir por arte feita à mão é um objetivo do projeto.

## Identidade

Fantasia sombria original: catacumbas **caiadas** com friso de **azulejos** vidrados, velas
e cera, sinos, raízes que atravessam a alvenaria e uma **seiva turquesa** que brilha onde a
Raiz-que-Bebe está viva. Beleza estranha e horror convivem. Nada fofo, nada infantil.

## Resolução e escala

- Tela-base **640×360**, escala inteira (×2 720p, ×3 1080p, ×4 1440p, ×6 4K).
- Tiles **16×16**; vista **3/4**: paredes têm topo (pedra escura) e face frontal de até 2 tiles.
- Personagens em quadros de **24×24** (Coveira, Ressequido) e **24×32** (Lamuriante), com a
  origem nos pés. Itens 16×16; ícones de HUD 8–9 px.

## Paleta-mestra

Definida em `ferramentas/arte/paleta.py` (cada cor tem um caractere usado nas grades).
Regra de *hue shifting*: sombras puxam para roxo/azul, luzes para amarelo — tudo parece
iluminado por velas num lugar frio.

| Família | Uso | Tons (escuro → claro) |
|---|---|---|
| Escuros | contorno, vazio | `#0b0910` `#17121c` `#241c2b` `#352a3c` |
| Pedra fria | piso, sombras de roupa | `#463b4c` `#5a4f5e` `#716671` `#8c8189` |
| Cal e osso | paredes, ossadas, crânios | `#a89a8c` `#c4b6a0` `#ddd0b6` `#f2e8d0` |
| Azulejo | friso, urnas, altar | `#1c2442` `#2c3d6e` `#4766a8` `#8fb0e0` |
| Fogo | velas, destaque de interface | `#5a1e10` `#9c3a14` `#e07a1f` `#f7bb47` `#fff0b0` |
| Sangue | Sangria, dano | `#2e0b12` `#5c1520` `#962530` `#c94a42` |
| Pele | Coveira | `#6e4335` `#a8705a` `#d9a283` |
| Cera fria | Lamuriante, velas | `#a39a7c` `#cbbf98` `#efe5c4` |
| Musgo | sobretudo da Coveira, musgo | `#1d2619` `#2f3f26` `#4d6633` `#86a050` |
| Raiz e madeira | raízes, caixões, chapéu | `#2a1b16` `#46302a` `#6e4c3c` `#9a7358` |
| Carne seca | Ressequido | `#4a3d36` `#6b5a4c` `#8a7762` |
| Lamúria | magia roxa | `#2d1840` `#5a2f80` `#9a5cd0` `#d8b0ff` |
| Seiva | Raiz-que-Bebe, olhos | `#15333a` `#24706e` `#4fc4b0` `#b8f5e6` |

## Leitura e silhuetas

- Contorno de **1 px** (`#0b0910`) em personagens e objetos; o cenário não tem contorno.
- **Coveira**: chapéu de aba larga, cachecol ferrugem, sobretudo **verde-musgo** (complementar
  ao piso roxo-acinzentado), lanterna acesa na cintura. Lê em qualquer direção.
- **Ressequido**: corpo curvado e esquelético, **crânio de osso** com olho turquesa e uma raiz
  arrastando no chão (está preso à terra).
- **Lamuriante**: alta, velada, coroa de velas em gota; o rosto é um vazio com dois pontos roxos.
- Inimigos sempre têm uma cor-sinal distinta do cenário (turquesa, roxo) para leitura em combate.
- Chamas sempre **em gota**, nunca em forma de cruz.

## Iluminação

- `CanvasModulate` por sala (ambiente frio, ~0,30–0,42) + `PointLight2D` quentes em velas e
  candelabros (tremulação por ruído), lanterna da Coveira, brilho roxo da Lamúria e turquesa
  dos olhos/seiva. Texturas de luz em **faixas pontilhadas** (Bayer 4×4), coerentes com o pixel.
- Vinheta pontilhada sobre a tela.

## Animação

- Coveira: parada (respiração), corrida de 6 quadros (pernas procedurais), esquiva, dano, morte
  (ajoelha, tomba, chapéu rola). Squash & stretch no código (esquiva, golpe).
- A arma é um sprite separado que gira 360° para a mira; o golpe desenha um **rastro em crescente**
  na baixa resolução (sai pixelado naturalmente).
- Inimigos: andar, preparo (tremor), ataque, recuperação, dano e morte (desabam em ossos/derretem
  em cera); surgem da terra crescendo a partir dos pés.
- Fluidez vem de antecipação, impacto (hitstop, flash, tremor) e recuperação — não de mais quadros.

## Efeitos

Partículas de pixel com altura simulada: faíscas, estilhaços de osso/cera que quicam, poeira,
fumaça; sangue que cai **deixa manchas permanentes no chão da sala**. Números de dano com
contorno (desligáveis). Anéis de onda (badalo dourado, impacto do golpe pesado).

## Interface e tipografia

- **Jacquard 12** (blackletter pixel, 21 px e múltiplos): títulos, nomes de itens, mensagens.
- **Jersey 10** (19 px): textos de interface e descrições.
- **Micro 5** (11 px): números, HUD miúdo, inscrições.
- Fontes convertidas para bitmap na grade exata (sempre nítidas). Licença OFL em `fontes/OFL.txt`.
- Painel 9-fatias escuro com cantos de osso; foco de menu marcado por uma chama; destaque em âmbar.

## Regras de consistência

1. Só cores da paleta-mestra (novas cores entram primeiro na paleta).
2. Origem dos sprites nos pés; a base é calculada pela última linha opaca.
3. Nada de rotação de sprites de personagem fora da morte; giros só na arma e em efeitos.
4. Densidade de detalhe: piso calmo, paredes com detalhe, personagens com o máximo de contraste.
5. Cada região nova define sua sub-paleta e seu sinal de cor antes de qualquer sprite.

## Plano de substituição

1. Usar a arte atual como guia de escala, paleta e leitura.
2. Encomendar ou produzir à mão (Aseprite) as folhas mantendo **os mesmos JSON** (nomes de
   animação, tamanho de quadro, origem, pontos) — o jogo não precisa mudar.
3. Prioridade: Coveira → inimigos → tiles das Catacumbas → interface → objetos.
