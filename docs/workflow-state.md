# Estado Persistido do Workflow

Este repositório usa `/docs` como área única de estado para manter implementações retomáveis entre sessões.

## Arquivos obrigatórios

| Arquivo | Responsabilidade |
|---|---|
| `/docs/spec.md` | Define objetivo, escopo, limites e critérios de aceitação da feature |
| `/docs/plan.md` | Organiza fases, dependências, checkpoints e ordem de execução |
| `/docs/tasks.md` | Lista tarefas pequenas e verificáveis com status persistido |
| `/docs/handoff.md` | Registra o estado operacional mais recente para retomada |
| `/docs/lessons.md` | Registra lições aprendidas validadas e a promoção explícita de regras globais |

## Contrato de `/docs/tasks.md`

Cada tarefa deve conter, no mínimo:

- identificador estável
- título curto
- status `TODO`, `IN_PROGRESS`, `BLOCKED` ou `DONE`
- dependências
- critérios de aceitação
- verificações obrigatórias
- checkpoint seguinte ou próximo passo esperado

## Contrato de `/docs/plan.md` (marker de aprovação)

Quando o plano é gerado pelo `/workflow` (ou pelo `/plan` dentro dele), a primeira linha após o título carrega o marker de aprovação:

```markdown
> Status: DRAFT
```

ou, após o gate humano:

```markdown
> Status: APPROVED (AAAA-MM-DD)
```

- `DRAFT` — o plano existe mas não foi aprovado; o `/workflow` reapresenta e pede aprovação antes de qualquer código.
- `APPROVED` — o gate foi cumprido; a fase BUILD pode executar. A transição `DRAFT → APPROVED` é o equivalente persistente do arquivo de plano corrente de sistemas de pipeline por arquivo — sobrevive a queda de sessão.

O plano gerado pelo `/workflow` também contém as seções `## Roteamento` (decisão de especialista confirmada pelo usuário) e `## Contexto do código-base` (relatório do `codebase-analyst`).

## Arquivamento (`/docs/archive/`)

Ao encerrar um pipeline `/workflow`, `spec.md`, `plan.md` e `tasks.md` são movidos para `/docs/archive/AAAA-MM-DD-<slug-da-feature>/`. Sem o arquivamento, a spec antiga faria a próxima execução pular a fase DEFINE. `handoff.md` é resetado; `lessons.md` nunca é arquivado — é acumulativo.

## Contrato de `/docs/handoff.md`

O handoff deve ser curto e operacional. Atualize sempre que uma task mudar de estado ou um incremento verificável terminar.

Estrutura mínima recomendada:

```markdown
# Handoff

## Escopo atual
- Feature ou correção em andamento

## Fase do workflow
- BUILD (ou DEFINE, ROUTE, ANALYZE, PLAN, GATE, REVIEW ciclo 1/3, REVIEW_DONE, DOCUMENT — apenas quando dirigido pelo /workflow)

## Task ativa
- ID: T-03
- Status: IN_PROGRESS
- Execução: delegada a `serverless-backend` (ou inline)

## Último incremento verificado
- Testes executados
- Build executada
- Commit ou save point correspondente

## Arquivos tocados
- caminho/arquivo.ext

## Blockers
- Nenhum

## Próximo passo
- Ação exata que a próxima sessão deve executar
```

## Contrato de `/docs/lessons.md`

Toda lição começa em `/docs/lessons.md`, mesmo quando depois for promovida para uma skill, comando ou instrução.

Cada lição deve conter, no mínimo:

- `lesson ID` estável
- data
- origem `manual`, `review`, `debug` ou `resume`
- categoria `LOCAL_PATTERN`, `PROCESS_GAP`, `SKILL_GAP`, `PROJECT_CONVENTION` ou `FALSE_POSITIVE_REVIEW`
- severidade
- contexto e erro observado
- causa raiz ou racional do ajuste
- decisão correta e prevenção futura
- escopo `local` ou `global`
- destino de promoção `skill`, `command`, `instruction`, `adr` ou `none`
- status `OPEN`, `APPLIED_LOCALLY`, `PROMOTED` ou `REJECTED`

Quando a lição for global e o gatilho for explícito, a promoção deve acontecer no mesmo fluxo com referência ao `lesson ID`.

## Regra de retomada

Ao iniciar uma nova sessão:

1. Leia os cinco arquivos em `/docs`
2. Compare o estado persistido com `git status` e com os commits recentes
3. Recomece da task `IN_PROGRESS` ou da próxima `TODO`, nunca de memória
4. Destaque primeiro lições `OPEN` e lições `PROMOTED` recentemente que sejam relevantes para a task ativa
5. Se houver inconsistência, trate a divergência antes de escrever código novo

Esse protocolo não elimina toda perda possível, mas limita a ambiguidade e torna a retomada explícita e auditável.