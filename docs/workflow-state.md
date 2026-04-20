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

## Contrato de `/docs/handoff.md`

O handoff deve ser curto e operacional. Atualize sempre que uma task mudar de estado ou um incremento verificável terminar.

Estrutura mínima recomendada:

```markdown
# Handoff

## Escopo atual
- Feature ou correção em andamento

## Task ativa
- ID: T-03
- Status: IN_PROGRESS

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