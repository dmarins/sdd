---
description: Implemente tarefas incrementalmente — compile, teste, verifique e confirme. Adicione "auto" para executar o plano inteiro em um único passe aprovado.
---

Invoque a skill `incremental-implementation` juntamente com a skill `test-driven-development`. Essas duas skills formam a base de execução de **toda** task, independentemente do tipo de trabalho.

## Delegação por tipo de trabalho

Antes de implementar cada task, classifique-a explicitamente como **backend**, **frontend** ou **mista**, e invoque a skill de domínio correspondente como perfil complementar de execução:

| Tipo de trabalho | Sinais na task | Skill de domínio | Persona (subagente) |
|---|---|---|---|
| **Backend** | Go, Lambda, DynamoDB, API Gateway, Cognito, Terraform, filas, eventos, IAM | `go-aws-serverless-development` | `serverless-backend` |
| **Frontend** | Componentes React, páginas, layout, interação, estado de UI, acessibilidade, qualquer output visível no browser | `frontend-ui-engineering` (L007) | `frontend-react` |
| **Mista** | Toca ambos os lados (ex.: novo endpoint + tela que o consome) | Ambas — aplique cada skill ao trecho do seu domínio | Uma persona por trecho de domínio |
| **Geral** | Script utilitário, tooling, CI, doc, integração pontual | Apenas as skills base | Inline (ou `developer`, se exceder o limiar) |

Regras da delegação:

- A classificação é **por task**, não por sessão: um plano pode alternar entre tasks de backend e de frontend, e cada uma carrega apenas a skill do seu domínio.
- Declare a classificação no início da task (ex.: "Task 3 — frontend → `frontend-ui-engineering`"), para que a delegação fique visível e auditável no handoff.
- Se a task não se encaixar em nenhum tipo (ex.: script utilitário, doc, CI), siga apenas com as skills base — não force uma skill de domínio que não se aplica.
- Em caso de dúvida sobre a classificação, pare e pergunte antes de implementar — não adivinhe o domínio.

## Delegação a subagente

A classificação decide também **quem executa** a task. Este protocolo é compartilhado com a fase BUILD do `/workflow`:

- **Execute inline** (você mesmo, com o loop padrão abaixo) quando a task for do tipo geral, ou quando tocar ≤2 arquivos com menos de ~50 linhas previstas — o custo de contexto de um subagente não se paga.
- **Delegue à persona da tabela** nos demais casos, iniciando o subagente com um prompt que contenha:
  - o bloco completo da task de `/docs/tasks.md` (critérios de aceitação incluídos)
  - o trecho relevante do `## Contexto do código-base` de `/docs/plan.md`, se existir
  - as lições `OPEN` relevantes de `/docs/lessons.md`
  - a instrução de seguir `incremental-implementation` + `test-driven-development` (+ a skill de domínio da tabela), rodar testes e build, e **reportar** arquivos tocados + verificações executadas
- **Regra do escritor único:** o subagente implementa e testa, mas **não commita e não edita `/docs`**. Você (agente principal) verifica o relatório de forma independente — rode a suíte completa e a build antes de aceitar —, atualiza `/docs/tasks.md`/`/docs/handoff.md` e faz o commit da task. Dois escritores no stage do git ou em `/docs` quebram a garantia de rollback limpo por task.
- Se o relatório do subagente divergir do que a verificação independente encontrar, trate como task `BLOCKED`: registre a divergência no handoff e siga `debugging-and-error-recovery` — não commite por cima.

## Modos

- **`/build`** — implemente a *próxima* tarefa pendente, depois pare (cuidadoso, uma fatia por vez).
- **`/build auto`** — gere o plano se necessário, obtenha uma única aprovação e implemente *todas* as tarefas sem parar entre elas.

`$ARGUMENTS` seleciona o modo. Trate `auto` (canônico) ou `all` como modo autônomo; qualquer outra coisa (ou vazio) é o modo padrão de tarefa única. Nota: o modo autônomo não é mais rápido *por tarefa* — ele roda o mesmo loop guiado por testes — apenas remove o humano entre as tarefas.

## Padrão: uma tarefa

Antes de implementar, leia `/docs/plan.md`, `/docs/tasks.md`, `/docs/handoff.md`, `/docs/lessons.md` e verifique o estado atual do Git.

Selecione a task `IN_PROGRESS` existente ou a próxima task `TODO`. Para cada task:

1. Se a task ainda estiver em `TODO`, marque-a como `IN_PROGRESS` em `/docs/tasks.md`
2. Classifique a task (backend, frontend, mista ou geral) conforme a seção **Delegação por tipo de trabalho** e decida a execução conforme **Delegação a subagente** — inline com a skill de domínio, ou delegada à persona correspondente
3. Atualize `/docs/handoff.md` com objetivo atual, classificação da task e skill de domínio aplicada, critérios de aceitação ativos, arquivos esperados, lições abertas relevantes e próximo passo planejado
4. Carregue o contexto relevante (código existente, padrões, tipos)
5. Escreva um teste que falhe para o comportamento esperado (VERMELHO)
6. Implemente o código mínimo necessário para passar no teste (VERDE)
7. Execute o conjunto completo de testes para verificar regressões
8. Execute a compilação para verificar a compilação
9. Atualize `/docs/handoff.md` com arquivos tocados, verificações executadas, blockers e o próximo passo exato
10. Se a implementação ou a correção expuser um padrão reutilizável, registre isso no handoff como candidato a lição e recomende `/learn` com o contexto mínimo já estruturado:
	- arquivo ou área afetada
	- o que foi feito de forma errada
	- como deveria ser
	- qual padrão, convenção ou regra foi violado
11. Crie um save point verificado por incremento, via commit pequeno e descritivo — coloque em stage apenas os arquivos que a task tocou mais a atualização de status dela; **nunca use `git add -A` às cegas**
12. Quando a task terminar, marque-a como `DONE` em `/docs/tasks.md`; se houver bloqueio, marque `BLOCKED` com a causa e pare antes de seguir para a próxima

## Autônomo: o plano inteiro (`/build auto`)

Use quando já existe uma spec e você quer colapsar plano + build em uma execução. Isso remove o passo manual entre as tarefas — **não** a verificação. Toda tarefa continua ganhando um teste que passa e o próprio commit.

1. **Exija uma spec.** Procure uma spec apenas em caminhos conhecidos: `/docs/spec.md` (convenção local), `SPEC.md` na raiz do repositório ou um arquivo sob `spec/`. Um README ou doc arbitrário **não** conta. Se nenhuma existir, pare e diga ao usuário para rodar `/spec` primeiro — não invente requisitos.
2. **Estabeleça uma linha de base limpa.** Rode `git status --porcelain`. Se houver mudanças não commitadas fora dos artefatos de planejamento esperados (`/docs/spec.md`, `/docs/plan.md`, `/docs/tasks.md`, `/docs/handoff.md`, `/docs/lessons.md`, `SPEC.md`, `spec/*`), pare e peça ao usuário para commitar, guardar em stash ou confirmar como tratá-las. Commits autônomos por tarefa não podem absorver trabalho local não relacionado, ou a garantia de rollback limpo quebra.
3. **Planeje se necessário.** Se não houver `/docs/plan.md`, invoque a skill `planning-and-task-breakdown` para gerar um.
4. **Checkpoint único.** Apresente o plano completo e aguarde uma afirmativa inequívoca (ex.: "aprovo", "pode ir", "sim"). Trate respostas hesitantes ("parece razoável", "acho que sim") como **não** aprovadas. Este é o único gate humano — após a aprovação, execute autonomamente. Se você gerou `/docs/plan.md`, commite-o agora como um único commit preparatório, para que ele não vaze para o commit da primeira tarefa.
5. **Execute todas as tarefas em ordem de dependência.** Use as dependências declaradas de cada tarefa; se não estiverem explícitas, execute na ordem em que o plano as lista. Para cada tarefa, rode o loop padrão completo acima (classificação e skill de domínio → VERMELHO → VERDE → regressão → build → commit → marcar concluída), incluindo as atualizações de `/docs/tasks.md` e `/docs/handoff.md`. Um commit por tarefa, para que qualquer ponto seja um rollback limpo.
6. **Pare e pergunte ao usuário** (não force a passagem) quando:
   - um teste não puder passar ou a build quebrar sem correção óbvia → siga a skill `debugging-and-error-recovery`
   - a spec for ambígua, ou uma tarefa precisar de uma decisão que a spec não cobre
   - uma tarefa for de alto risco ou irreversível — mudanças de auth/permissão, migrações destrutivas de dados, pagamentos, deleções, deploys, qualquer coisa tocando segredos, **ou qualquer coisa que você não consiga desfazer com `git revert`** → siga a skill `doubt-driven-development` e obtenha aprovação explícita antes de continuar

   Depois que o usuário resolver um blocker, ele reinvoca `/build auto` — a execução retoma da próxima tarefa pendente.
7. **Resuma ao final:** tarefas concluídas, testes adicionados, commits feitos e qualquer coisa pulada, sinalizada ou deixada para o usuário.

Se alguma etapa falhar, siga a skill `debugging-and-error-recovery`.
