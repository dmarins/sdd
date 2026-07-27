---
name: interview-me
description: Extrai o que o usuário realmente quer em vez do que ele acha que deveria querer. Faz isso por meio de uma entrevista de uma pergunta por vez até alcançar ~95% de confiança sobre a intenção subjacente. Use quando o pedido estiver subespecificado ("construa X" sem "para quem" ou "por que agora"), quando o usuário invocar explicitamente ("me entreviste", "me sabatine", "temos certeza?", "teste meu raciocínio") ou quando você se pegar preenchendo requisitos ambíguos em silêncio antes de existir qualquer plano, spec ou código.
---

# Interview Me

## Visão Geral

O que as pessoas pedem e o que elas realmente querem são coisas diferentes. Elas pedem "um dashboard" porque é isso que se pede, não porque um dashboard resolve o problema delas. Dizem "deixe mais rápido" sem um número a atingir.

O momento mais barato para encontrar esse vão é antes de existir qualquer plano, spec ou código. Depois que você começou a construir, os custos de troca são reais, e o usuário racionalizará a coisa errada até virar uma coisa "boa o suficiente". O desencaixe fica travado.

Esta skill fecha o vão antes que ele custe algo. As outras skills da fase de Definição assumem que você já sabe aproximadamente o que quer: `idea-refine` gera variações a partir de uma ideia, `spec-driven-development` escreve os requisitos, `doubt-driven-development` testa um plano depois de rascunhado. Interview-me é a parte anterior a todas elas, em que você pergunta uma coisa por vez, com o seu melhor palpite anexado, até conseguir prever o que o usuário vai dizer antes de ele dizer.

## Quando Usar

Aplique esta skill quando:

- O pedido não tem pelo menos um destes: **quem** é o usuário, **por que** ele quer, como é o **sucesso**, qual é a **restrição** vinculante
- O pedido é convencional em vez de específico ("construa X", "deixe mais rápido") e você não consegue desempacotar a convenção sem chutar
- Você está tentado a começar com premissas que não expôs
- O usuário não disse qual valor está otimizando quando dois razoáveis estão em tensão (simplicidade vs. flexibilidade, custo vs. velocidade)
- O usuário invoca explicitamente: "me entreviste", "me sabatine", "antes de começar, temos certeza?", "teste meu raciocínio"

**Quando NÃO usar:**

- O pedido é inequívoco e autocontido ("renomeie esta variável", "corrija este typo")
- O usuário pediu explicitamente velocidade acima de verificação
- Pedidos puramente informativos ("como X funciona?", "o que este código faz?")
- Operações mecânicas (renames, formatação, mover arquivos)
- Você já tem ≥95% de confiança; releia a condição de parada abaixo antes de assumir que não tem

## Restrições de Carregamento

Esta skill precisa de um usuário vivo e responsivo. **Não invoque em contextos não interativos** como pipelines de CI, execuções agendadas, `/loop` ou autonomous-loop. Se você estiver em um deles e o pedido estiver subespecificado, sinalize isso como blocker para o usuário em vez de chutar.

## O Processo

### Passo 1: Hipotetize, com um número de confiança

Antes de perguntar qualquer coisa, escreva a sua melhor leitura atual do que o usuário quer em **uma frase**, mais um número honesto de confiança (0–100%):

```
HIPÓTESE: Você quer um jeito de responder "como estamos indo?" na daily, e "dashboard" foi a convenção que veio à mente.
CONFIANÇA: ~30% — faltando: para quem é, o que "métricas" significa no contexto e como é o sucesso
```

O número força honestidade. Se você escreveu um número alto mas não consegue de fato prever as reações do usuário às próximas três perguntas que faria, o número está errado. Comece no nível de confiança que você consegue defender.

Quando a confiança estiver abaixo de ~70%, acrescente uma razão breve na mesma linha — o que ainda está sem resolução ou faltando. Isso diz ao usuário exatamente o que a entrevista precisa expor, e impede o número de ser um sinal vago.

### Passo 2: Pergunte uma coisa por vez, cada uma com um palpite anexado

Formato:

```
P: <uma pergunta focada>
PALPITE: <sua hipótese para a resposta, com o raciocínio que a produziu>
```

Espere o usuário reagir antes de fazer a próxima pergunta.

**Por que uma por vez, e não um lote:**

- O usuário não consegue reagir às suas hipóteses se você as enterrar em uma lista
- Lotes incentivam leitura dinâmica e respostas superficiais
- A terceira pergunta muitas vezes depende da resposta à primeira; perguntar tudo de uma vez trava o enquadramento errado
- A energia do usuário para pensar com cuidado é finita; gaste-a uma pergunta por vez

**Por que anexar um palpite:**

- O usuário reage mais rápido a um palpite errado do que gera uma resposta do zero
- Compromete você com uma hipótese sobre a qual pode estar visivelmente errado, o que mantém a honestidade
- Expõe as *suas* premissas, que é o que a entrevista existe para revelar

O risco aqui é um usuário educado concordar com o seu palpite por gentileza. Mitigue mostrando-se visivelmente disposto a errar e, ocasionalmente, palpitando numa direção em que você espera que o usuário discorde.

### Passo 3: Escute o "quer vs. deveria querer"

As respostas mais perigosas são aquelas em que o usuário diz o que uma resposta ponderada *parece ser* em vez do que ele realmente quer. Fique atento a:

- Respostas que imitam discurso de boas práticas ("quero que seja escalável", "arquitetura limpa") sem especificidades
- Respostas que se apoiam na convenção ("do jeito que a maioria dos apps faz", "a abordagem padrão")
- Frases como "eu provavelmente deveria…", "acho que é para eu…", "boa prática de engenharia diz…"
- Buzzwords como objetivo — quando "moderno", "escalável", "robusto" são a resposta em vez de um resultado específico

Quando ouvir isso, a pergunta a fazer é:

> *"Se você não precisasse justificar isso para ninguém, o que você realmente ia querer?"*

Essa única pergunta muitas vezes rende mais do que as cinco anteriores.

### Passo 4: Reafirme a intenção nas palavras do próprio usuário

Quando a sua confiança estiver alta, escreva de volta o que agora você acha que o usuário quer. Mantenha enxuto (5–8 linhas), use a linguagem dele quando possível e estruture para que ele confirme ou corrija linha a linha:

```
Eis o que agora eu acho que você quer:

- Resultado:      <uma linha>
- Usuário:        <uma linha — quem se beneficia>
- Por que agora:  <uma linha — o que mudou>
- Sucesso:        <uma linha — como saberemos que funcionou>
- Restrição:      <uma linha — o limite vinculante>
- Fora de escopo: <uma linha — o que explicitamente não vamos fazer>

Sim / não / refinar?
```

Incluir "Fora de escopo" é inegociável. Metade do desalinhamento é desacordo silencioso sobre o que *não* está sendo construído.

### Passo 5: Confirme — um sim explícito, não "o que você achar melhor"

O gate é um "sim" explícito. Os seguintes **não** são sim:

- "O que você achar melhor." → O usuário está delegando, o que significa que ele também não tem 95% de confiança. Pergunte de novo com duas opções concretas enquadradas como escolha.
- "Parece bom." → Ambíguo. Pergunte: "Refinaria alguma coisa?" Silêncio não é confirmação.
- "Claro, vamos." → Muitas vezes uma saída educada, não um endosso. Mesmo follow-up.
- Silêncio seguido de "ok, pode começar." → O usuário desistiu da entrevista, não convergiu. Pare e pergunte se você deixou algo passar.

Se ele corrigir você, incorpore a correção e reafirme. Repita até obter um sim explícito.

### A Parada dos 95% de Confiança

Você terminou quando consegue responder sim a isto:

> *Consigo prever a reação do usuário às próximas três perguntas que eu faria?*

Se sim, vocês têm entendimento compartilhado. Pare de entrevistar e produza a reafirmação. Se não, você não terminou; faça a próxima pergunta.

Este é um teste verificável, não uma sensação. Ele também tem um piso: se você já rodou várias rodadas e ainda não consegue prever, isso é informação sobre o pedido, não motivo para continuar moendo. Pare e diga ao usuário: "Fiz X perguntas e ainda não consigo prever suas reações. Algo fundamental está faltando. Quer dar um passo atrás?"

## Saída

A saída desta skill é uma **declaração de intenção confirmada**: a reafirmação do Passo 4, com um sim explícito do Passo 5. Esse é o entregável. Specs, planos e listas de tarefas ficam a jusante; eles consomem a intenção que esta skill produz.

Se o usuário quiser que a intenção persista (um projeto multi-sessão, um handoff para outro colaborador), ofereça salvá-la em `docs/intent/[tópico].md`. Só salve se ele confirmar.

## Exemplo

Um antes-e-depois curto.

**Sem `interview-me`:**

```
Usuário: construa um dashboard para as nossas métricas
Agente:  <começa a propor bibliotecas de gráfico e layouts>
```

O agente assumiu: para quem é, quais métricas, o que "para o nosso time" significa, como é o sucesso. Nada disso foi dito. Cada premissa é um lugar onde o usuário pode depois dizer "não era isso que eu quis dizer".

**Com `interview-me`:**

```
Usuário: construa um dashboard para as nossas métricas

Agente:
HIPÓTESE: Você quer um jeito de responder "como estamos indo?" na daily, e "dashboard" veio à mente por ser a resposta convencional.
CONFIANÇA: ~30% — faltando: para quem é, quais são as "métricas" e como é o sucesso

P:       Quando você diz "como estamos indo?", quem está perguntando — você sozinho, o time de engenharia na daily, ou acima na cadeia (ex.: seu gestor, um exec, um board)?
PALPITE: o time de engenharia na daily, porque "nós" costuma delimitar assim e a daily é onde essa pergunta aparece. Se for para execs, as métricas e o enquadramento mudam muito.

Usuário: Na verdade é para mim. Eu vivo perdendo o controle de quais experimentos estão rodando e como está o sinal inicial deles.

Agente:
Leitura atualizada: não é um dashboard de time. É um rastreador pessoal de experimentos. Confiança: ~60% — ainda faltando: o que "sinal inicial" significa e como é o pronto.

P:       O vão é você não saber quais experimentos existem, ou não conseguir ver os resultados deles em um só lugar?
PALPITE: o segundo. Você tem uma lista de experimentos em algum lugar, mas os resultados vivem em cinco ferramentas diferentes, e reconciliá-los na mão é o que te cansou.

Usuário: O primeiro, na verdade. Eu literalmente não tenho uma lista. Estão espalhados em vários docs.

Agente: <continua>
```

Duas perguntas depois, o agente descobriu que o pedido real não é "um dashboard". É "uma lista". Artefato diferente, escopo diferente, trabalho diferente. O dashboard teria sido errado.

## Interação com Outras Skills

- **`idea-refine`**: a jusante. Se a intenção confirmada for "quero X mas não sei como escopar", passe o bastão para `idea-refine` gerar variações contra a intenção agora explícita.
- **`spec-driven-development`**: a jusante. Se a intenção confirmada for concreta ("quero X para os usuários Y com critérios de sucesso Z"), passe para `spec-driven-development` escrevê-la.
- **`planning-and-task-breakdown`**: dois saltos a jusante desta skill (depois da spec).
- **`doubt-driven-development`**: extremo oposto da linha do tempo. Interview-me é extração de intenção pré-decisão; o guiado por dúvida é revisão de artefato pós-decisão. Ambos capturam divergência, mas em momentos diferentes.
- **`source-driven-development`**: ortogonal. Interview-me esclarece o que o usuário quer; SDD verifica fatos de framework. Não competem.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "O pedido está claro o suficiente" | Se você não consegue escrever o resultado desejado do usuário em uma frase agora, o pedido não está claro. Rode o Passo 1 antes de decidir. |
| "Fazer muitas perguntas desperdiça o tempo dele" | O tempo gasto por 4–6 perguntas certeiras é pequeno. O tempo gasto construindo a coisa errada é enorme, e é o usuário quem paga esse custo. |
| "Eu descubro enquanto construo" | Custos de troca depois que o código existe são 10x os de agora. Descoberta durante a implementação é retrabalho. |
| "Ele disse 'o que você achar melhor', então decido eu" | "O que você achar melhor" é delegação, não decisão. Pergunte de novo com duas opções concretas como escolha. |
| "Devo dar várias opções para ele escolher" | Opções funcionam quando o usuário sabe o que quer e está escolhendo entre trade-offs. Ele ainda não sabe o que quer. Listar opções alarga a busca; perguntar a estreita. |
| "Se eu anexo meu palpite, estou induzindo" | Induzir é o ponto. Reagir é mais rápido do que gerar do zero. O risco é bajulação, não indução; mitigue mostrando-se visivelmente disposto a errar. |
| "Já conversamos o bastante, entendi" | Teste: consegue prever a reação dele às próximas três perguntas? Se não, ainda não entendeu. |
| "O usuário disse sim, terminamos" | Se o sim veio depois de uma reafirmação vaga ou de um "parece bom" aberto, o sim é oco. Reafirme concretamente e reconfirme. |

## Sinais de Alerta

- Três ou mais perguntas em uma única mensagem: isso é lote, não entrevista
- Uma pergunta sem a sua hipótese anexada: isso é enquete, não compromisso
- Aceitar "o que você achar melhor" como resposta final
- Produzir spec, plano ou lista de tarefas antes de o usuário confirmar explicitamente a sua reafirmação
- Perguntas enquadradas como "qual seria a boa prática?" em vez de "o que você realmente quer?"
- O usuário dá uma resposta que sinaliza sofisticação ("escalável", "limpo", "moderno") e você aceita sem sondar se é o que ele realmente quer
- Três ou mais rodadas sem a sua confiança subir visivelmente: você está fazendo as perguntas erradas; recue e reenquadre
- Um número de confiança abaixo de ~70% sem razão anexada: o usuário não pode ajudar a fechar o vão se não sabe o que falta
- Salvar o doc de intenção antes de o usuário confirmar (o próprio doc implica um sim que o usuário não deu)
- Pular a linha "Fora de escopo" na reafirmação (desacordo silencioso sobre não-objetivos é metade do desalinhamento)

## Verificação

Depois de aplicar interview-me:

- [ ] Uma hipótese explícita com número de confiança foi declarada no primeiro turno
- [ ] Todo número de confiança abaixo de ~70% veio acompanhado de uma razão de uma linha (o que ainda está sem resolução ou faltando)
- [ ] As perguntas foram feitas uma por vez, cada uma com o palpite do agente anexado
- [ ] Pelo menos uma sondagem "o que você realmente ia querer se não precisasse justificar?" rodou quando o usuário deu uma resposta de sinalização de sofisticação ou convenção
- [ ] Uma reafirmação concreta (Resultado / Usuário / Por que agora / Sucesso / Restrição / Fora de escopo) foi escrita de volta ao usuário
- [ ] O usuário confirmou a reafirmação com um sim explícito (não "o que você achar melhor", não "parece bom", não silêncio)
- [ ] No ponto de parada, o agente conseguia prever as reações às próximas três perguntas que faria
- [ ] Qualquer handoff para uma skill a jusante (`idea-refine`, `spec-driven-development`) foi enquadrado em termos da intenção confirmada, não do pedido subespecificado original
