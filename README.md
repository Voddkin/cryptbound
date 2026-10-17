# CRYPTBOUND

> *A terra parou de aceitar os mortos.*

Jogo de ação e exploração de masmorras em pixel art, com visão de cima, feito em
**Godot 4.7.2** para **Windows** (e Linux). Totalmente em português do Brasil.

Uma coveira desce pelas Catacumbas de Cal, onde os mortos voltam movidos por uma raiz
colossal. Combate rápido e telegrafado, relíquias que se combinam, salas que se trancam com
raízes até serem purificadas e uma morte que ensina o que deu errado.

## Estado

**Primeiro marco jogável concluído** (veja `ESTADO_DO_PROJETO.md`): a Coveira (combo, golpe
pesado, esquiva), dois inimigos, três relíquias com combinação, nove salas, profundidades
infinitas com escalada, interface completa em pt-BR, salvamento robusto, 67 testes
automatizados e builds para Windows e Linux verificados fora do editor.
Arte e áudio são **provisórios** (gerados por código).

## Como jogar

| Ação | Teclado e mouse | Controle |
|---|---|---|
| Mover | W A S D | Analógico esquerdo |
| Mirar | Mouse | Analógico direito |
| Golpe (combo de 3) | Botão esquerdo | X / RT |
| Golpe pesado (segure) | Botão direito | Y / LT |
| Esquiva | Espaço | A / RB |
| Interagir | E | B |
| Pausa | Esc | Start |

## Desenvolvimento

Requisitos: Godot 4.7.2 (editor) e os templates de exportação 4.7.2; Python 3 com Pillow e
numpy para regenerar arte/áudio; `fonttools` e `pefile` para as ferramentas.

```bash
godot --path .                                  # abre o jogo
godot --path . res://jogo/mundo/descida.tscn -- --demo   # robô jogando sozinho
ferramentas/testar.sh                           # todos os testes (headless)
ferramentas/exportar.sh                         # build Windows + Linux em build/
python3 ferramentas/arte/gerar_arte.py          # regenera a arte provisória
python3 ferramentas/audio/gerar_sfx.py          # regenera os efeitos sonoros
python3 ferramentas/audio/gerar_musica.py       # regenera a música
```

## Documentação

| Documento | Conteúdo |
|---|---|
| `VISAO_DO_JOGO.md` | Identidade, premissa, pilares e princípios |
| `DOCUMENTO_DE_DESIGN.md` | Mecânicas, números, inimigos, relíquias, estrutura |
| `PLANO_DE_DESENVOLVIMENTO.md` | Marcos, prioridades e riscos |
| `ESTADO_DO_PROJETO.md` | O que funciona, o que falta, como retomar |
| `ARQUITETURA_TECNICA.md` | Engine, estrutura, sistemas e decisões técnicas |
| `DIRECAO_ARTISTICA.md` | Paleta, escala, animação, iluminação e regras visuais |
| `REGISTRO_DE_TESTES.md` | Testes realizados e resultados |
| `REGRAS_DO_AGENTE.md` | Regras de desenvolvimento (idioma, mundo original, qualidade) |
| `BANCO_DE_IDEIAS.md` | Ideias futuras com prioridade |

## Créditos

- Fontes **Jacquard 12**, **Jersey 10** e **Micro 5** — The Soft Type Project Authors,
  SIL Open Font License 1.1 (`fontes/OFL.txt`).
- Motor **Godot Engine** (licença MIT).
- Desenvolvido com o auxílio do Claude (Anthropic).
