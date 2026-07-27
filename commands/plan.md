---
description: Divida o trabalho em pequenas tarefas verificáveis com critérios de aceitação e ordenação de dependências
---

Invoque a habilidade `planning-and-task-breakdown`.

Leia a especificação existente em `/docs/spec.md` (ou equivalente a migrar para esse caminho) e as seções relevantes do código-fonte. Em seguida:

1. Entre no modo de planejamento — somente leitura, sem alterações de código
2. Se `/docs/plan.md` já contiver a seção `## Contexto do código-base` (relatório do `codebase-analyst`, gerado pela fase ANALYZE do `/workflow`), consuma-a como entrada obrigatória da quebra em tasks — não re-investigue o que o relatório já cobre
3. Identifique o grafo de dependências entre os componentes
4. Divida o trabalho verticalmente (um caminho completo por tarefa, não camadas horizontais)
5. Escreva as tarefas com critérios de aceitação, etapas de verificação, status inicial `TODO` e a classificação de domínio (backend, frontend, mista ou geral) com a persona ou execução inline correspondente — este é o contrato consumido pelo `/build` e pela fase BUILD do `/workflow`
6. Adicione pontos de verificação entre as fases
7. Estruture `/docs/tasks.md` para que cada tarefa registre, no mínimo: identificador, status, dependências, critérios de aceitação, verificações, classificação de domínio e próximo checkpoint esperado
8. Inicialize `/docs/handoff.md` com: escopo atual, task ativa `Nenhuma`, riscos conhecidos, pendências abertas e instruções de retomada
9. Inicialize `/docs/lessons.md` com o template de lições aprendidas, mesmo que ainda não haja entradas
10. Apresente o plano para revisão humana

Salve o plano em `/docs/plan.md`, a lista de tarefas em `/docs/tasks.md`, o estado operacional inicial em `/docs/handoff.md` e o registro de lições em `/docs/lessons.md`.