# Regras do Agente

Regras para quem desenvolver o CRYPTBOUND (pessoa ou agente de IA). Elas têm prioridade
sobre conveniência.

## 1. Idioma

- Todo texto visível ao jogador é em **português do Brasil** natural: menus, itens, inimigos,
  dicas, mensagens, créditos, textos em imagens. Sem traduções literais, sem mistura de idiomas.
- Textos de interface ficam em `jogo/textos/textos.gd` (`Textos.t("chave")`); nomes e
  descrições de conteúdo ficam nos recursos em `dados/`.
- O teste `testes/unit/teste_textos.gd` verifica chaves inexistentes, texto provisório
  ("TODO", "placeholder", "lorem"…) e inglês acidental. Ele precisa continuar passando.
- Documentação do projeto: pt-BR. Identificadores no código: pt-BR por padrão; termos técnicos
  da engine permanecem como são.

## 2. Mundo original

- **Nenhum** personagem, criatura, entidade, ordem ou lugar de folclore, mitologia ou
  religião reais (decisão do usuário). Tudo é inventado para o jogo.
- Evitar símbolos religiosos reais na arte (ex.: chamas desenhadas em gota, nunca em cruz).
- O fato de o jogo ser em pt-BR é só sobre idioma; o mundo não precisa ter temática brasileira.

## 3. Autonomia e limites

- Decisões pequenas e reversíveis dentro da visão: tomar e seguir, registrando nos documentos.
- Pedir aprovação antes de: mudanças fundamentais de direção (estrutura, nome, engine),
  gastos externos, ações destrutivas (apagar histórico, `push --force`, remover conteúdo do
  usuário) ou publicação para terceiros.
- Recursos de terceiros só com licença compatível (ex.: fontes OFL), com crédito no jogo e
  licença incluída em `fontes/`.

## 4. Fluxo de trabalho

1. Ler `ESTADO_DO_PROJETO.md` e `PLANO_DE_DESENVOLVIMENTO.md` antes de começar.
2. Investigar antes de improvisar: consultar a documentação/código do Godot 4.7.2
   (`raw.githubusercontent.com/godotengine/godot/4.7.2-stable/...`) quando houver dúvida de API.
3. Implementar com testes: lógica nova ganha teste unitário ou de simulação em `testes/`.
4. Verificar de verdade: `ferramentas/testar.sh` (todos os testes), execução visual com o robô
   (`-- --demo`) e, ao fim de um marco, exportação (`ferramentas/exportar.sh`).
5. Revisar: para mudanças grandes, rodar uma revisão adversarial (revisores independentes +
   verificador cético) e corrigir o que for confirmado.
6. Registrar: atualizar `ESTADO_DO_PROJETO.md` e `REGISTRO_DE_TESTES.md`; commit em pt-BR e
   push para `origin/main` ao fim de cada etapa significativa.

## 5. Qualidade

- O básico (movimento, golpe, esquiva, resposta dos inimigos) tem prioridade sobre conteúdo novo.
- Todo ataque inimigo precisa de telegrafia legível e justa.
- Conteúdo como dado: adicionar arma, relíquia, inimigo ou sala não deve exigir reescrever o núcleo.
- Nada de sistema genérico gigante antes de existir necessidade concreta.
- Arte e áudio provisórios devem ser coerentes entre si e marcados como provisórios.

## 6. Honestidade

- Nunca registrar como implementado o que é plano, nem como aprovado um teste que não rodou.
- Relatar falhas, limitações e o que é provisório. Distinguir fato verificado de hipótese.
- Se o ambiente impedir uma verificação, dizer qual e por quê.
