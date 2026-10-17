# Estado do Projeto — CRYPTBOUND

**Atualizado em:** 17/10/2026 · **Versão:** 0.1.0 · **Marco atual:** M1 "Primeira Cova" concluído.
**Repositório:** <https://github.com/Voddkin/cryptbound> (branch `main`).

Este documento diz **o que existe de verdade**, o que é provisório, o que falta e como
retomar o trabalho do zero numa sessão nova. Tudo marcado como "verificado" foi
executado e conferido; o que não pôde ser verificado está dito explicitamente.

---

## 1. Resumo

Uma descida jogável e repetível pelas **Catacumbas de Cal**: a Coveira entra, enfrenta
ondas de Ressequidos e Lamuriantes em salas que se trancam, escolhe uma relíquia entre três,
encara a arena, desce a escada e recomeça uma profundidade mais funda e mais difícil, até
morrer. A tela de morte diz o que a derrubou e como responder. Há menu principal, pausa,
configurações, salvamento do progresso e executáveis para Windows (64 bits) e Linux.

Arte e áudio são **provisórios**, gerados por código (scripts em `ferramentas/`).

## 2. O que funciona (verificado)

| Área | Situação | Como foi verificado |
|---|---|---|
| Coveira: movimento em 8 direções, esquiva intocável, combo de 3, golpe pesado carregado, buffer de entrada | ✅ | Testes de simulação + vídeo com o robô |
| Feedback: hitstop, tremor, recuo de câmera, flash, partículas, números de dano, sons | ✅ | Testes (`teste_efeitos`) + vídeo. O hitstop e o tremor **não funcionavam** até a 2ª revisão (ver §5) |
| Ressequido (investida telegrafada, postura) e Lamuriante (Lamúria, fortalece aliados) | ✅ | Testes de simulação + vídeo |
| 3 relíquias com combinação real (Presa + Sino) | ✅ | Testes de simulação |
| 9 salas em ASCII, portas que trancam, ondas, reforços por profundidade | ✅ | Testes de validação/montagem de todas as salas + vídeo |
| Sequência entrada → combate → relicário → combate → arena → descida → profundidade +1 | ✅ | Vídeo do robô até a profundidade 2 |
| Interface em pt-BR: título, HUD, painel de relíquia, pausa, configurações, tela de morte | ✅ | Capturas de tela revisadas + lint de textos |
| Configurações (volumes geral/música/efeitos, tremor de tela, tela cheia, V-Sync, números de dano) salvas em `config.cfg` | ✅ | 4 testes (`teste_config`): ida e volta, valores inválidos, arquivo ilegível, efeito no jogo |
| Salvamento robusto (temporário + validação + backup, recuperação de arquivo corrompido) | ✅ | 7 testes de salvamento |
| Controles: teclado + mouse e controle (analógicos, gatilhos) | ⚠️ | Teclado/mouse por simulação; **controle físico nunca foi testado** |
| Executável Windows x86_64 (PCK embutido, ícone, metadados) | ✅ | `pefile` + execução no **Wine 11.18** com renderização (não é Windows real) |
| Executável Linux x86_64 | ✅ | Execução fora do editor sob Xvfb |
| Desempenho | ✅ | Cena de estresse com 30 inimigos (ver `REGISTRO_DE_TESTES.md`) |

**Testes automatizados:** 61, todos passando (`ferramentas/testar.sh`).

## 3. O que é provisório

- **Toda a arte** (sprites, tiles, ícones, luzes, logo): pixel art gerada por scripts Python
  com paleta fixa. Coerente e legível, mas não é arte final de artista.
- **Todo o áudio** (42 efeitos, 3 músicas em duas camadas): sintetizado em numpy.
  **Nunca foi ouvido por um humano**; só foi analisado numericamente (picos, emendas de loop,
  espectro). Pode soar estranho.
- **Números de combate** (velocidades, tempos de aviso, dano, escalada por profundidade):
  escolhidos por referência e ajustados por simulação e vídeo. **Ninguém jogou ainda.**
- **Estrutura da descida:** sequência fixa de 6 salas com sorteio das salas de combate.
  O gerador em grafo é do M2.
- **Ícone e logo:** provisórios.

## 4. O que ainda não existe

Restos/Sepultar, Cavar, Promessas, estados além de Sangria/Atordoado, tabela de reações,
segunda arma, terceiro inimigo, elites, chefe, minimapa, santuário (hub), meta-progressão,
salvar e continuar uma descida, remapeamento de controles, outras regiões. Tudo isso está
planejado em `PLANO_DE_DESENVOLVIMENTO.md` e detalhado em `DOCUMENTO_DE_DESIGN.md`.

## 5. Problemas conhecidos e limitações

- **Sem teste em Windows real.** O `.exe` roda no Wine 11.18 (WoW64) com OpenGL do Mesa.
  No Wine 9.0 (o do Ubuntu 24.04) o `.exe` **cai na inicialização** dentro do `kernelbase`
  do próprio Wine (`VirtualProtect` com ponteiro nulo no código de inicialização do MinGW),
  o que indica limitação daquele Wine, não do jogo — mas só um Windows real confirma.
- **Sem playtest humano.** A sensação de controle foi avaliada por simulação e vídeo.
- **Controle físico (gamepad) não testado.**
- **Áudio não ouvido** (ver §3). No contêiner não há placa de som; o Godot usa o driver mudo.
- **Desempenho medido só com renderização por software** (llvmpipe). Com 30 inimigos a
  lógica custa ~6 ms por passo de física numa CPU de servidor; numa GPU real a renderização
  deve ser muito mais barata que os ~17 ms do llvmpipe. Não há medição em GPU real.
- A 2ª revisão adversarial encontrou que **hitstop, tremor e recuo de câmera eram
  cancelados no próprio quadro do impacto** desde o início (o motor lê `Engine.time_scale`
  no começo do quadro). Corrigido e coberto por teste; os vídeos antigos não mostram esses
  efeitos com fidelidade.

## 6. Como rodar, testar e exportar

```bash
godot --path .                                           # abre o jogo (tela de título)
godot --path . res://jogo/mundo/descida.tscn -- --demo   # robô joga sozinho
ferramentas/testar.sh                                    # 61 testes (headless, 60 quadros fixos)
ferramentas/testar.sh teste_jogador                      # só os testes cujo nome contém o filtro
ferramentas/exportar.sh                                  # build/windows/CRYPTBOUND.exe e build/linux/
ferramentas/empacotar.sh                                 # entregas/CRYPTBOUND-windows-x64-<versão>.zip
ferramentas/gravar_video.sh 60                           # entregas/cryptbound-demo.mp4 (robô, 60 s, com som)
```

O `.zip` leva o `.exe`, um `LEIA-ME.txt` em pt-BR (controles, aviso do SmartScreen, onde
ficam os dados) e as licenças exigidas (Godot MIT + terceiros, fontes OFL).

Capturas e vídeo (precisa de renderização; no servidor, use Xvfb):

```bash
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --fixed-fps 60 res://testes/captura/capturar_telas.tscn -- /caminho/da/pasta
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --fixed-fps 60 --write-movie demo.avi res://jogo/mundo/descida.tscn -- --demo
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  res://testes/desempenho/estresse.tscn -- --demo          # mede o tempo de quadro
```

Modos `--demo` e de teste gravam em `user://demo/` e `user://testes/`, nunca no progresso
real do jogador (`%APPDATA%\CRYPTBOUND` no Windows, `~/.local/share/CRYPTBOUND` no Linux).

## 7. Como retomar numa sessão nova

1. **Clonar:** `git clone https://github.com/Voddkin/cryptbound.git && cd cryptbound`.
2. **Godot 4.7.2-stable** (editor Linux e templates de exportação):
   - `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`
     → extrair e criar o link `godot` no `PATH`.
   - `https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz`
     (1,28 GB) → extrair `templates/` para `~/.local/share/godot/export_templates/4.7.2.stable/`.
3. **Python** (só para regenerar arte/áudio e checar o `.exe`): `pip install pillow numpy fonttools pefile`
   (ffmpeg e ImageMagick vêm do sistema).
4. **Primeira importação:** `godot --headless --path . --import` (cria `.godot/`).
5. **Conferir:** `ferramentas/testar.sh` deve terminar com `RESULTADO: 61 testes, 0 falhas`.
6. **Testar o `.exe` sem Windows (opcional):**
   - `https://github.com/Kron4ek/Wine-Builds/releases/download/11.18/wine-11.18-amd64-wow64.tar.xz`
     (a variante WoW64 dispensa bibliotecas de 32 bits).
   - `apt install libegl1 libegl-mesa0 xvfb`.
   - `WINEDLLOVERRIDES="mscoree,mshtml=" WINEPREFIX=<pasta> wine64 wineboot -i` (sem os
     overrides o `wineboot` trava esperando instalar Mono/Gecko).
   - `xvfb-run -a wine build/windows/CRYPTBOUND.exe --rendering-driver opengl3 -- --demo`.
   - Erros de ALSA/WASAPI (sem placa de som) são esperados e inofensivos.
7. **Ler antes de mexer:** `REGRAS_DO_AGENTE.md` (idioma, mundo original, qualidade),
   `ARQUITETURA_TECNICA.md` (onde fica cada coisa) e a seção M2 do plano.

## 8. Próxima tarefa

**M2, item 1: playtest humano** do build Windows num PC real (pedir ao dono do projeto)
e ajuste dos números de combate a partir do que for relatado. Em paralelo, começar
**Restos e Sepultar** (pilar 2), que é o sistema assinatura que mais muda o jogo.
