# Plano de Desenvolvimento — CRYPTBOUND

Status: ✅ concluído e verificado · 🔄 em andamento · ⏳ planejado.

## M0 — Fundação ✅
Engine (Godot 4.7.2), projeto 640×360, autoloads, núcleo de combate, salvamento robusto,
executor de testes, pipelines de arte/áudio/fontes, presets de exportação.

## M1 — "Primeira Cova" (primeiro marco jogável) ✅
Critérios (todos verificados — ver `REGISTRO_DE_TESTES.md`):
- Coveira com 8 direções, esquiva intocável, combo de 3 golpes, golpe pesado carregado. ✅
- Dois inimigos com decisões distintas (Ressequido, Lamuriante). ✅
- Colisão, dano, feedback de impacto (hitstop, tremor, flash, partículas, sons), morte. ✅
- Salas coerentes (9 salas das Catacumbas de Cal), iluminação, objetos. ✅
- Recompensas: 3 relíquias com combinação, ossos, tocos de vela. ✅
- Transições entre salas e profundidades repetíveis. ✅
- Interface em pt-BR: título, HUD, pausa, configurações, tela de morte. ✅
- Testes automatizados (61) + simulação + vídeo com robô + exportação Windows/Linux rodando
  fora do editor. ✅

## M2 — Combinações e identidade ⏳ (próximo)
Ordem de prioridade (o que mais aumenta diversão e rejogabilidade por esforço):
1. **Playtest humano** do M1 num PC Windows e ajuste fino dos números de combate.
2. **Restos e Sepultar** + **Semeador** (pilar 2) — testes de simulação incluídos.
3. **Estados** Seiva/Brasa/Esporos e **tabela de reações** em dados.
4. **8–10 relíquias novas** usando os gatilhos existentes (+ `ao_eliminar`, `ao_limpar_sala`).
5. **Duas armas** (Turíbulo, Martelo de Lápide) com combos próprios.
6. **Emparedado** (escudo frontal) e elites.
7. **Cavar** terra fofa com segredos.
8. Gerador de andar em **grafo** (salas com várias saídas, sala secreta) + **minimapa**.
9. **Remapeamento de controles** e salvar/continuar descida.

Critério de conclusão: pelo menos 5 combinações de relíquias testadas por simulação; restos
sepultáveis com efeito visível; andar gerado por grafo com semente reproduzível; nenhum
softlock em 50 descidas do robô.

## M3 — Região completa ⏳
Chefe *A Mãe-Cal*, Promessas, Contador de Ossos (loja), ~15 salas, música adaptativa por
camadas, eventos de sala, polimento de áudio.

## M4 — Santuário e progressão ⏳
O Último Pavio (hub), Fiadeira de Pavios (desbloqueios que ampliam possibilidades),
segunda região (*Jardim dos Ossos*), história por inscrições.

## M5+ — Produto ⏳
Novas regiões e chefes, modos (Vigília, desafios, modificadores), acessibilidade, arte
definitiva, instalador (NSIS), identidade final (ícone, logo).

## Dependências e riscos

| Risco | Mitigação |
|---|---|
| Arte gerada por código limita o teto visual | Linguagem visual documentada; substituição sem mudar código (mesmos JSON). |
| Sensação de controle não pode ser "sentida" por quem programa sem jogar | Números de referência, vídeos quadro a quadro, testes de simulação; **playtest humano é prioridade do M2**. |
| Sem Windows real no ambiente | Wine 11.18 como aproximação; pedir teste em PC real a cada build. |
| Contêiner efêmero | Commit + push a cada etapa; `ESTADO_DO_PROJETO.md` explica como retomar. |
| Escopo | Um marco por vez, critérios observáveis, nada especulativo. |
