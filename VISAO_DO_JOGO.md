# CRYPTBOUND — Visão do Jogo

> *A terra parou de aceitar os mortos.*

## Em uma frase

Um jogo de ação e exploração de masmorras em pixel art, visto de cima, em que uma coveira
desce por catacumbas vivas para descobrir por que os mortos voltaram — combatendo com
precisão, combinando relíquias estranhas e aprendendo com cada morte.

## Premissa

Na necrópole de **Candeia**, cidade erguida sobre o próprio ossuário, os enterrados voltam.
São os **Ressequidos**: cadáveres secos movidos por filamentos de raiz. A última **Coveira**
desce sob o cemitério e encontra a **Raiz-que-Bebe**, uma entidade colossal que atravessa as
catacumbas. Onde ela aceita os mortos, nascem jardins bioluminescentes de beleza estranha;
onde os rejeita, há carne, sangue e podridão.

O mundo é **inteiramente original**: nenhuma criatura, pessoa, ordem ou lugar vem de folclore,
mitologia ou religião reais. A cultura material é inventada (catacumbas caiadas, azulejos
vidrados com iconografia própria, cera, velas, sinos, raízes, seiva luminosa). Os nomes são
palavras em português, mas os seres e a cultura pertencem ao jogo.

## Estrutura

**Roguelite com santuário persistente** (decisão do usuário).

- Cada **descida** atravessa profundidades; cada profundidade é uma sequência de salas
  feitas à mão e montadas pela semente da descida.
- Morrer encerra a descida. O que fica é **conhecimento e possibilidade**: relíquias vistas,
  atalhos, personagens do santuário, história revelada — não um acúmulo de números.
- O **santuário** (o Último Pavio, casa-lanterna na superfície) é o ponto de retorno entre
  descidas (planejado para o Marco 4).

## Pilares

1. **Combate de leitura e resposta.** Todo ataque inimigo é anunciado (pose, som, luz).
   O jogador que observa sempre tem uma resposta: esquivar, interromper, reposicionar.
2. **Restos e sepultura.** Os mortos são recurso tático: corpos ficam na sala, podem ser
   sepultados, explodidos, plantados ou reerguidos por inimigos (sistema assinatura, Marco 2).
3. **Combinações por gatilhos e estados.** Relíquias mudam *como* se joga, não só *quanto*
   de dano se causa. Uma empurra, a outra faz sangrar quem se move — juntas, o empurrão vira
   dano. Combinações têm regras claras e limites (profundidade de encadeamento, recargas).
4. **Contraste.** Calmaria e contemplação (antecâmaras à luz de velas, jardins luminosos)
   contra horror e espetáculo (ondas que se erguem da terra, o Ventre). O especial só
   impressiona porque nem tudo é especial.
5. **A morte ensina.** A tela de morte diz o que derrubou a Coveira, com qual ataque, e
   como responder da próxima vez.

## Tom

Fantasia sombria, melancólica e às vezes grotesca — nunca infantil ou "fofinha". Beleza
estranha ao lado do horror. Humor seco e raro nas inscrições dos objetos. Violência e
sangue aparecem quando fazem sentido (Sangria, restos, o Ventre), não como enfeite constante.

## Princípios de design

- **O básico tem que ser bom sozinho.** Mover, golpear e esquivar precisam ser prazerosos
  antes de qualquer relíquia rara.
- **Dificuldade por exigência, não por inflação.** Inimigos pedem decisões diferentes
  (o Ressequido pune quem fica parado na frente; a Lamuriante fortalece aliados e exige
  prioridade). A profundidade adiciona inimigos e vida aos poucos, mas o desafio principal
  é de leitura e posicionamento.
- **Justiça visível.** Nenhum dano sem aviso. Telegrafias têm duração mínima (o preparo do
  Ressequido dura 0,55 s; a mira trava 0,15 s antes do bote, então esquivar tarde funciona).
- **Itens com identidade.** Cada relíquia tem um efeito que muda decisões e uma inscrição
  que conta um pedaço do mundo.
- **Conteúdo como dado.** Armas, relíquias, inimigos e salas vivem em arquivos de dados;
  criar conteúdo novo não exige mexer no núcleo.
- **Dez sistemas excelentes valem mais que cem superficiais.**

## O que torna o jogo próprio

- A protagonista é uma **coveira** com a ferramenta do ofício: a pá é arma, e cavar e
  sepultar viram mecânicas (planejadas).
- **Velas como vida**: cada golpe recebido apaga uma vela no HUD — legível e temático.
- **Portas de raízes**: a própria Raiz tranca as salas durante o combate e recua quando a
  sala é purificada.
- **Fio de luz**: a Lamuriante mostra literalmente quem está ligado a ela.
- Uma **identidade visual** de catacumbas caiadas com friso de azulejos, velas e seiva
  turquesa, rara no gênero.

## Idioma

Todo o jogo é em **português do Brasil**: menus, itens, inimigos, dicas, mensagens, créditos.
Não há opção de inglês nesta fase. Identificadores técnicos no código podem usar termos
técnicos, mas tudo que o jogador vê está em pt-BR.
