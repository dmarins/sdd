---
name: pr-review-comments
description: Processa comentários de revisão de PR criticamente e com segurança. Use quando o usuário pedir para analisar, responder ou tratar comentários abertos em um pull request.
---

# Revisão de Comentários de PR

## Visão Geral

Itere sobre os comentários de revisão abertos de um pull request de forma crítica e segura. Um comentário de revisor é um sinal, não uma ordem — aceite apenas quando há melhoria real de correção, clareza, segurança, desempenho ou manutenibilidade. Para cada thread: entenda o que está sendo criticado, decida a ação com justificativa técnica, obtenha aprovação explícita antes de editar, aplique e verifique, e depois responda no thread com linguagem factual e sem fluff. Nunca faça push, nunca poste respostas e nunca comita sem confirmação explícita do usuário em cada gate.

## Quando Usar

- Quando o usuário pedir para revisar ou tratar comentários do PR ("Revise os comentários do meu PR")
- Quando o usuário pedir para responder threads pendentes ("Responda os comentários pendentes do PR 456")
- Quando o usuário quiser processar o que um bot de revisão apontou ("Analisa o que o ultrareview apontou")
- Quando houver comentários abertos e o usuário quiser tratar antes de fazer merge ("Tem comentários no PR, pode tratar?")
- Ao receber qualquer variação de "skill pr review comments" seguido ou não de um número de PR

## Princípios Orientadores

- **Criticidade acima de compliance.** Só aja se a sugestão melhora genuinamente o código. Se não tem substância ou está errada, responda com justificativa técnica respeitosa e deixe o código como está.
- **Uma resposta por thread.** Se o thread tem cinco comentários, consolide a essência e escreva uma resposta que endereça a discussão inteira — não responda cada comentário individualmente.
- **Fidelidade de idioma.** Espelhe o idioma do comentário mais recente e substantivo do thread (português, inglês, espanhol etc.). Termos técnicos permanecem na forma original.
- **Frescor primeiro.** Processe os comentários mais recentes e não respondidos primeiro. Threads antigos e já respondidos só são revisitados se um novo comentário foi adicionado a eles.
- **Não cause dano.** Antes de comitar qualquer mudança aceita, releia o código editado em contexto e rode os checks rápidos disponíveis (build/lint/testes rápidos) para descartar regressões introduzidas pelo fix.
- **Sem ações silenciosas.** A skill nunca faz push, nunca posta respostas e nunca comita sem confirmação explícita do usuário em cada gate.
- **Bots são tratados como humanos.** `ultrareview`, `coderabbit`, `sonarcloud` e similares são processados da mesma forma — análise por mérito, consolidados, avaliados criticamente.
- **Narre o raciocínio.** Para cada thread, o usuário deve ouvir três coisas explicitamente, nessa ordem: **(1)** o que você entendeu que o revisor está criticando — reescrito com suas próprias palavras, não cópia do comentário; **(2)** qual solução está sendo considerada e *por que essa* em vez de alternativas; **(3)** depois de aplicar, o que foi mudado e como foi verificado que não quebrou nada. Esse protocolo captura leituras erradas do comentário antes do código mover e dá ao usuário chance real de intervir.
- **Dry-runs ficam secos.** Em modo de análise/planejamento, nunca descreva trabalho como já feito. Fraseie ações no futuro ou condicional ("vai adicionar `FOR UPDATE`", "extrairia `Validate`"), e a resposta rascunho deve manter o mesmo registro — não pré-anuncie um commit ou push que ainda não aconteceu.
- **Referência cruzada em threads resolvidos.** Antes de classificar um novo comentário, varra os threads já resolvidos do mesmo PR. Revisores frequentemente levantam variações da mesma preocupação em pontos diferentes — um thread anterior resolvido pode já conter a decisão definitiva (aceita, recusada com justificativa, ou "não alcançável na prática"). Quando esse match existir, cite a URL ou database ID do comentário do thread resolvido na resposta em vez de rederiviar o argumento do zero.

## Regras de Execução

1. **Verificar pré-requisitos.**
   - `gh --version` deve ter sucesso. Se não, informe o usuário para instalar o GitHub CLI e pare.
   - `gh auth status` deve mostrar uma conta autenticada. Se não, peça ao usuário para rodar `gh auth login` e pare.
   - O diretório atual deve estar dentro de um repositório git com remote GitHub.

2. **Identificar o PR.**
   - Se o usuário passou um número de PR, use-o.
   - Caso contrário, rode `gh pr view --json number,headRefName,baseRefName,url,title,state` para a branch atual. Se nenhum PR estiver associado, pare e informe o usuário.
   - Confirme o PR alvo com o usuário antes de buscar qualquer coisa: mostre `#<número> — <título>` e a URL. Aguarde confirmação se o match for ambíguo.

3. **Buscar threads de revisão não resolvidos (fonte da verdade).**

   Use GraphQL — os endpoints REST não expõem o estado de resolução do thread. Consulte os `reviewThreads` do PR com seus comentários, flag de resolução e relações de resposta:

   ```bash
   gh api graphql -f query='
     query($owner:String!,$repo:String!,$num:Int!){
       repository(owner:$owner,name:$repo){
         pullRequest(number:$num){
           reviewThreads(first:100){
             nodes{
               id
               isResolved
               isOutdated
               path
               line
               comments(first:50){
                 nodes{
                   id
                   databaseId
                   author{login}
                   body
                   createdAt
                   url
                 }
               }
             }
           }
         }
       }
     }' -f owner=<owner> -f repo=<repo> -F num=<number>
   ```

   Busque também comentários gerais do PR (não vinculados a linha) com `gh api repos/<owner>/<repo>/issues/<num>/comments` — esses são comentários de nível de issue, precisam ser tratados mas não podem ser "resolvidos" como threads de revisão.

4. **Filtrar e agrupar.**
   - Mantenha apenas threads onde `isResolved == false` para **processamento** — esses são a fila.
   - Mantenha os threads `isResolved == true` em memória como **contexto** (não descarte). Serão consultados na etapa 6b quando o mesmo tópico ressurgir.
   - Descarte threads cujo **último comentário** foi autoriado pelo usuário atual (`gh api user --jq .login`) — já foram respondidos do nosso lado; a bola está no campo do revisor.
   - Para cada thread restante, extraia a ideia central de todos os comentários combinados: o que está sendo pedido, por quê, e quaisquer contra-argumentos já feitos.
   - Ordene por recência do último comentário, mais recente primeiro.
   - Threads desatualizados (`isOutdated == true`) vão para o final — sinalize-os mas ainda os apresente, porque a preocupação do revisor pode ainda se aplicar ao código atual.

5. **Apresentar a fila ao usuário.**

   Mostre um resumo compacto antes de mergulhar:

   ```
   Encontrei N threads não resolvidos no PR #<num>:

     1. <arquivo>:<linha> — <autor> (<idade>) — <essência em uma linha>
     2. <arquivo>:<linha> — <autor> (<idade>) — <essência em uma linha>
     ...

     • Comentários gerais do PR (sem arquivo/linha): <contagem>
   ```

   Pergunte quais processar primeiro, ou confirme "todos, em ordem".

6. **Para cada thread — execute o loop de análise:**

   a. **Leia o código em contexto.** Abra o arquivo na linha comentada, leia código circundante suficiente para entender a situação como o revisor vê (geralmente 30–60 linhas).

   b. **Classifique o comentário.** Antes de fixar uma classificação, varre os **threads resolvidos retidos na etapa 4** para matches em path/símbolo/tópico. Se um thread resolvido já contém a decisão sobre essa preocupação exata, note sua URL/database ID — torna-se evidência a citar na resposta e frequentemente empurra a classificação para `já-endereçado` ou fortalece a justificativa para `infundado`/`recusar`. Depois escolha uma:
      - `bug` — revisor encontrou um defeito.
      - `melhoria` — sugestão válida de refatoração/clareza/perf/manutenibilidade.
      - `pergunta` — revisor pedindo justificativa, não uma mudança.
      - `nit` — preferência estilística, baixo impacto.
      - `infundado` — especulativo, errado, ou baseado em leitura equivocada.
      - `já-endereçado` — o código já faz o que está sendo pedido, ou um commit anterior resolveu, **ou um thread resolvido neste PR já carrega a decisão**.

   c. **Decida a ação.**
      - `bug` / `melhoria` com mérito → **aceitar**: planeje o fix.
      - `pergunta` → **responder apenas**: sem mudança de código, justificativa técnica.
      - `nit` → **decisão do usuário**: apresente, padrão é aceitar apenas se trivial.
      - `infundado` → **recusar**: redija justificativa técnica respeitosa.
      - `já-endereçado` → **apontar evidência**: SHA do commit, referência de linha.

   d. **Apresente a decisão e aguarde aprovação.** Nunca edite ou responda sem o "vai" explícito do usuário. Use esta estrutura de três partes para cada thread:

      - **Entendimento** — uma ou duas frases reescrevendo o que o revisor está realmente criticando, com suas próprias palavras. Não é cópia do comentário. Se o thread teve múltiplos comentários, esta é a ideia central consolidada.
      - **Proposta** — a ação (aceitar / recusar / responder / pedir-esclarecimento), mais *por que essa* em vez de alternativas plausíveis. Se aceitando: liste os arquivos e o plano de edição concreto. Se recusando: resuma a base técnica da recusa. Se respondendo: esboce o conteúdo da resposta.
      - **Resposta preliminar** — o texto real que será postado no thread, no idioma do thread. Fraseado no futuro/condicional ("vai adicionar", "extrairia") — nunca afirme que o trabalho está feito nesta etapa.

      Depois pergunte ao usuário para aprovar, ajustar ou pular.

   e. **Aplique a mudança de código** (se aceitando, após aprovação):
      - Use ferramentas `Edit` / `Write`.
      - Releia a região editada e varra regressões óbvias: imports quebrados, vars não usadas, tipos incompatíveis, call sites quebrados.
      - Se o repositório tem checks rápidos (formatter, linter, type-checker), rode-os nos arquivos tocados. Evite rodar suites de teste completas a menos que o usuário peça — são lentas e esta é uma skill com gate.
      - Se o check rápido falhar, pare e apresente o erro ao usuário — não tente encobrir.

   e'. **Reporte o que foi implementado.** Logo após a edição ser aplicada (e antes de mover para o próximo thread ou para o commit), informe o usuário:

      - **Implementado** — o resumo exato do diff: qual(is) arquivo(s), quais linhas, o que mudou. Curto e concreto.
      - **Verificado** — quais sanity checks rodaram (releitura, formatter, linter, type-checker) e o que retornaram.
      - **Risco residual** — qualquer preocupação que sobreviveu ao check, ou "nenhum observado".

      Então finalize o texto da resposta — neste ponto o rascunho da etapa (d) é atualizado do futuro ("vai adicionar") para o passado ("adicionou"), para que a resposta postada descreva com precisão a mudança que realmente aterrou.

   f. **Finalize a resposta.**
      - Um parágrafo por thread, independentemente de quantos comentários teve.
      - Idioma deve coincidir com o idioma dominante do thread.
      - Técnico mas conciso. Cite a mudança feita (ou a razão para não mudar) em termos factuais.
      - Sem desculpas, sem fluff, sem agradecer ao revisor pelo comentário. Seja um par, não um subordinado.

7. **Comite o batch.**

   - Inspecione o histórico de commits recente para aprender a convenção do repositório:
     ```bash
     git log -15 --pretty=format:'%s'
     ```
     Detecte prefixos (`feat:`, `fix:`, `refactor:`, `[PISMO-XXXX]`, Conventional Commits etc.) e combine exatamente.
   - Estratégia de commit padrão: **um commit por grupo lógico de comentários aceitos**, não um por thread (a menos que o usuário peça por-thread). Um agrupamento típico é todos os fixes de um único arquivo, ou todos os nits de estilo juntos.
   - Stage apenas os arquivos que foram alterados — `git add <arquivo>...`, nunca `git add .` ou `git add -A`.
   - Confirme a(s) mensagem(ns) de commit proposta(s) com o usuário antes de rodar `git commit`.
   - Siga quaisquer regras git específicas do projeto presentes em `CLAUDE.md`, `.clinerules/` ou diretórios `rules/` (ex: comandos de commit proibidos, anotações obrigatórias como `@genAI/Claude/`). Verifique-os antes de editar arquivos — podem impor requisitos de nível de linha.
   - **Nunca faça push.** O usuário faz push quando estiver pronto.

8. **Poste respostas e resolva threads.**

   Após os commits aterrar localmente, peça ao usuário o sinal verde para postar. Então, para cada thread processado:

   a. **Responda dentro do thread** (GraphQL — posta uma resposta real, não um novo comentário de nível superior):

      ```bash
      gh api graphql -f query='
        mutation($threadId:ID!,$body:String!){
          addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$threadId, body:$body}){
            comment{ id url }
          }
        }' -f threadId=<thread.id> -f body=<texto da resposta>
      ```

      Passe a resposta através de um caminho seguro para heredoc — respostas de revisão rotineiramente contêm backticks, fences de código e aspas.

   b. **Resolva o thread se apropriado.**
      - Resolva quando: a mudança de código está feita **e** commitada, ou o comentário era uma pergunta que agora foi respondida definitivamente.
      - NÃO resolva quando: recusando a sugestão (deixe o revisor resolver ou responder), ou quando o usuário pediu para manter aberto para discussão.

      ```bash
      gh api graphql -f query='
        mutation($threadId:ID!){
          resolveReviewThread(input:{threadId:$threadId}){ thread{ isResolved } }
        }' -f threadId=<thread.id>
      ```

   c. **Comentários gerais do PR** (não vinculados a linha) não podem ser "resolvidos" — responda com:
      ```bash
      gh api repos/<owner>/<repo>/issues/<num>/comments -f body=<resposta>
      ```

9. **Feche o loop.**

   Ao final, informe o usuário:

   - Threads processados, aceitos, recusados, respondidos, ainda abertos.
   - Commit(s) criados e se estão pushed ou não.
   - Lembrete: "O PR ainda está aberto. Novos comentários podem aparecer em novos pontos ou mesmo em pontos que acabamos de responder. Rode `skill pr review comments` novamente mais tarde para pegar o próximo batch."

## Fluxo Interativo — Exemplo Prático

**Usuário:** `skill pr review comments`

**Skill:**

> Verificando gh auth e PR atual...
>
> PR encontrado: **#456 — Add idempotency to advancement creation** (branch `feat/PISMO-12345`).
> Prosseguir neste? [sim/não ou número do PR]

**Usuário:** sim

**Skill:**

> Busquei 7 threads de revisão. 3 estão resolvidos, 1 foi respondido por você por último.
>
> **3 threads não resolvidos aguardando resposta**, mais **1 comentário geral**:
>
> 1. `service.go:142` — @ultrareview (2h atrás) — "panic on nil input is harsh; consider returning a typed error"
> 2. `repository.go:58` — @joana (5h atrás) — thread de 3 comentários, essência: "o lock `FOR UPDATE` alarga o escopo da transação — por que não `SELECT ... FOR NO KEY UPDATE`?"
> 3. `handler.go:210` — @joana (1d atrás) — "nit: renomear `doStuff` para algo descritivo"
> 4. (geral) — @roberto (30min atrás) — "adicionamos métricas para esse novo caminho?"
>
> Processar todos em ordem, ou escolher?

**Usuário:** todos

**Skill (thread 1 — gate na etapa 6d):**

> **#1 — service.go:142 — @ultrareview — classificação: `melhoria`, mérito: sim**
>
> **Entendimento** — o reviewer aponta que o handler faz `panic(fmt.Errorf(...))` quando a entrada é nil, o que derruba o processo inteiro em vez de permitir que a camada de handler traduza para um 4xx. Quer um erro tipado.
>
> **Proposta** — aceitar. Trocar o `panic` por `return nil, errs.ErrInvalidInput` em `service.go:138-145` e ajustar `service_test.go` para asseverar o erro tipado em vez de `recover`. Preferi `errs.ErrInvalidInput` em vez de criar um novo sentinel porque já existe e é o que o handler traduz para 400 no restante do código.
>
> **Resposta preliminar** (em inglês, mesma língua do @ultrareview):
>
> > Good point. Will replace the panic with `errs.ErrInvalidInput` so the handler layer can surface a 400 instead of crashing, and update the tests accordingly.
>
> Aplicar?

**Usuário:** sim

**Skill (thread 1 — após aplicar, etapa 6e'):**

> **Implementado** — `service.go:138-145` agora retorna `nil, errs.ErrInvalidInput`; `service_test.go:72-81` passou a esperar o erro tipado via `errors.Is`.
>
> **Verificado** — releitura do bloco editado ok, `goimports` rodou sem diff, `go vet ./internal/app/domain/advancement/...` limpo.
>
> **Risco residual** — nenhum observado. Callers do `service.Reserve` já propagam o erro para cima; o handler HTTP existente já tem branch para `errs.ErrInvalidInput`.
>
> **Resposta final** (substitui a preliminar):
>
> > Good point. Replaced the panic with `errs.ErrInvalidInput` so the handler layer surfaces a 400 instead of crashing; tests updated to assert the typed error.

...e assim por diante, um thread de cada vez, com gate antes do edit e report depois dele.

## Tratamento de Erros e Casos Especiais

- **PR não encontrado.** Apresente o git remote, a branch e a saída do `gh pr view`. Pergunte ao usuário se quer usar um número de PR manualmente.
- **Múltiplos PRs na mesma branch.** Raro, mas `gh pr view` pode disambiguar. Se não, pergunte.
- **Thread sem linha (desatualizado / resolvido num push).** Sinalize como `isOutdated`. Ainda leia a versão atual do arquivo no path do thread e veja se a preocupação do revisor ainda se aplica ao código atual. Trate normalmente depois disso.
- **Autor do comentário é o usuário atual.** Pule — você não pode revisar seu próprio comentário.
- **Revisor responde durante o workflow.** Se o usuário disser "espera, chegou novo comentário", re-busque a fila em vez de prosseguir com snapshot desatualizado.
- **Código se moveu desde que o comentário foi postado.** Offsets de posição podem estar errados. Busque a função/símbolo que o revisor nomeou em vez de confiar apenas no número de linha.
- **PR dominado por bots.** Se 90% dos comentários são de um bot, ainda processe cada thread individualmente — mas agrupe respostas e commits logicamente para evitar spam de commits.

## Idioma de Saída

Toda comunicação **com o usuário** segue o idioma da conversa atual (padrão: português brasileiro por instrução global). Todas as **respostas postadas no GitHub** seguem o idioma do thread comentado. Todo **código e mensagens de commit** estão em inglês conforme a convenção do repositório.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Aceitei todos os comentários para não gerar atrito" | Compliance não é criticidade. Aceitar sugestão ruim prejudica o código e o revisor não aprende que estava errado. |
| "O bot sinalizou, então deve estar errado" | Bots geram falsos positivos. Classifique por mérito técnico, não por autoridade da fonte. |
| "Já respondi o comentário, então está resolvido" | Responder não é o mesmo que resolver. Resolva o thread apenas quando a decisão (aceita ou recusada com justificativa) for definitiva. |
| "Era só um nit, não precisava pensar" | Nits acumulam débito silencioso. Avalie se vale aceitar antes de mudar — e se aceitar, verifique que não quebrou nada. |
| "Muda rápido pra desbloquear o merge" | Velocidade sem verificação gera regressão. Gate existe por isso. |
| "Postei a resposta, então posso resolver o thread" | Só resolva se a resposta for definitiva. Se o revisor pode ainda querer contra-argumentar, deixe-o resolver. |

## Sinais de Alerta

- Aceitar comentário sem entender o que está sendo pedido
- Postar resposta antes de a mudança de código ser confirmada e verificada
- Comitar múltiplas mudanças não relacionadas num único commit por conveniência
- Fazer push sem autorização explícita do usuário
- Resolver thread de recusa — cabe ao revisor resolver quando recusado
- Tratar bot diferente de humano na análise de mérito
- Responder sem espelhar o idioma do thread
- Ignorar threads desatualizados sem verificar se a preocupação ainda se aplica
- Rodadas de `git add .` — stage apenas arquivos tocados
- Descrever trabalho como feito antes de o gate de aprovação ter sido liberado

## Quando Parar

- Usuário diz para parar.
- Uma mudança de código falha num check rápido e a falha não é obviamente segura de endereçar dentro do escopo do thread atual — escale.
- O revisor posta um novo comentário que invalida o plano em voo — re-busque e reinicie o thread afetado.
- O estado do PR muda (merged, closed) durante o workflow — pare e reporte.

## Verificação

Ao final do processamento de uma rodada de threads:

- [ ] Pré-requisitos verificados (`gh --version`, `gh auth status`, repositório git com remote GitHub)
- [ ] PR identificado e confirmado com o usuário antes de buscar dados
- [ ] Threads não resolvidos buscados via GraphQL; threads resolvidos mantidos como contexto
- [ ] Fila apresentada ao usuário antes de iniciar o loop
- [ ] Para cada thread: entendimento → proposta → resposta preliminar apresentados e aprovação obtida antes de editar
- [ ] Código editado verificado (releitura + checks rápidos disponíveis); falhas reportadas sem encobrir
- [ ] Reporte pós-edição entregue (Implementado / Verificado / Risco residual) antes de mover para o próximo thread
- [ ] Mensagem(ns) de commit propostas e aprovadas antes de executar; apenas arquivos tocados staged
- [ ] Respostas postadas e threads resolvidos (ou mantidos abertos quando recusado) após aprovação explícita
- [ ] Resumo final entregue: threads processados, commits, estado de push, lembrete de re-execução
