# Critérios de Refinamento e Avaliação

Use esta rubrica durante a Fase 2, Avaliar e Convergir, para tensionar as direções da ideia. Nem todo critério se aplica a toda ideia, entao use critério para decidir quais dimensoes importam mais em cada contexto.

## Dimensoes Centrais de Avaliação

### 1. Valor para o Usuário

A dimensão mais importante. Se o valor não estiver claro, o resto perde importancia.

**Analgesico vs. Vitamina:**
- **Analgesico:** resolve um problema agudo e frequente. Usuários vao procurar isso ativamente, trocar da solucao atual e pagar se a proposta for boa.
- **Vitamina:** e algo bom de ter. Melhora marginalmente alguma coisa, mas raramente muda comportamento.

**Perguntas a fazer:**
- Você consegue nomear 3 pessoas especificas que tem esse problema agora?
- O que elas fazem hoje no lugar disso?
- Elas trocariam da abordagem atual? O que faria essa troca acontecer?
- Com que frequencia enfrentam esse problema?
- Isso e um problema de pull ou de push?

**Sinais de alerta:**
- "Todo mundo poderia usar isso"; se você não consegue nomear um usuário especifico, o valor não esta claro
- "E como X, so que melhor"; melhorias marginais raramente impulsionam adocao
- O problema e real, mas raro; alta intensidade com baixa frequencia raramente justifica produto

### 2. Viabilidade

Você consegue construir isso de verdade? Não apenas tecnicamente, mas na pratica.

**Viabilidade tecnica:**
- A tecnologia central existe e funciona de forma confiavel?
- Qual e o problema tecnico mais dificil?
- Existem dependencias de terceiros, APIs ou fontes de dados fora do seu controle?
- Qual e a stack minima necessária?

**Viabilidade de recursos:**
- Qual o time ou esforco minimo para construir um MVP?
- Exige expertise especializada que você não tem?
- Existem requisitos regulatorios, legais ou de compliance?

**Tempo ate valor:**
- Com que rapidez você consegue colocar algo na frente de usuários?
- Existe uma versao que entregue valor em dias ou semanas, e não meses?
- Qual e o caminho crítico?

**Sinais de alerta:**
- "So precisamos resolver [problema de pesquisa muito dificil] primeiro"
- Varias dependencias precisam funcionar ao mesmo tempo
- O MVP ainda exige meses de trabalho

### 3. Diferenciacao

O que torna isso genuinamente diferente? Não melhor, mas diferente.

**Perguntas a fazer:**
- Se um usuário descrevesse isso a um amigo, o que diria?
- Qual e a unica coisa que isso faz e mais ninguem faz?
- Essa diferenciacao e duravel?
- A diferenca e algo de que usuários realmente se importam?

**Tipos de diferenciacao, da mais forte para a mais fraca:**
1. **Nova capacidade:** faz algo antes impossivel
2. **Melhoria de 10x:** melhora tanto uma dimensão que muda comportamento
3. **Novo público:** leva uma capacidade existente a quem estava excluido
4. **Novo contexto:** funciona onde solucoes atuais falham
5. **Melhor UX:** mesma capacidade, experiencia muito mais simples
6. **Mais barato:** mesma coisa por menor custo

**Sinais de alerta:**
- A diferenciacao e totalmente tecnica e não percebida pelo usuário
- "Somos mais rapidos/baratos/bonitos" sem motivo estrutural real
- A feature diferenciadora não e a que mais importa para o usuário

## Auditoria de Pressupostos

Para cada direção de ideia, liste explicitamente pressupostos em tres categorias:

### Precisa Ser Verdade (Dealbreakers)
Pressupostos que, se estiverem errados, matam a ideia inteira. Precisam ser validados antes de construir.

Exemplo: "Usuários vao compartilhar seus dados conosco". Se isso não acontecer, o produto inteiro falha.

### Deveria Ser Verdade (Importante)
Pressupostos que afetam muito o sucesso, mas não matam completamente a ideia. Se estiverem errados, ainda da para ajustar a abordagem.

Exemplo: "Usuários preferem self-service a falar com uma pessoa". Se isso for falso, o go-to-market muda, mas o produto central ainda pode funcionar.

### Pode Ser Verdade (Bom se For)
Pressupostos sobre funcionalidades secundarias ou otimizacoes. Não os valide antes de provar o nucleo.

Exemplo: "Usuários vao querer compartilhar os resultados com colegas". Isso e crescimento, não proposta central de valor.

## Framework de Decisao

Ao escolher entre direções, use esta matriz:

|                    | Alta Viabilidade | Baixa Viabilidade |
|--------------------|------------------|-------------------|
| **Alto Valor**     | Faca isso primeiro | Vale o risco |
| **Baixo Valor**    | So se for trivial | Não faca |

Depois use diferenciacao como critério de desempate entre opcoes no mesmo quadrante.

## Principios para Escopo de MVP

Ao definir o escopo do MVP para a direção escolhida:

1. **Um trabalho, bem feito.** O MVP deve acertar exatamente um trabalho do usuário.
2. **Primeiro o pressuposto mais arriscado.** O objetivo principal do MVP e testar o que tem mais chance de estar errado.
3. **Limite por tempo, não por lista de features.** "O que conseguimos construir e testar em [período]?" e melhor do que "De que funcionalidades precisamos?"
4. **A lista de 'O que não vamos fazer' e obrigatoria.** Nomeie explicitamente o que foi cortado e por que.
5. **Se não der um pouco de vergonha, você demorou demais.** A primeira versao deve parecer incompleta para quem a construiu.
