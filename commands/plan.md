--- 
descrição: Divida o trabalho em pequenas tarefas verificáveis ​​com critérios de aceitação e ordenação de dependências
---

Invoque a habilidade `planning-and-task-breakdown`.

Leia a especificação existente em `/docs/spec.md` (ou equivalente a migrar para esse caminho) e as seções relevantes do código-fonte. Em seguida:

1. Entre no modo de planejamento — somente leitura, sem alterações de código
2. Identifique o grafo de dependências entre os componentes
3. Divida o trabalho verticalmente (um caminho completo por tarefa, não camadas horizontais)
4. Escreva as tarefas com critérios de aceitação, etapas de verificação e status inicial `TODO`
5. Adicione pontos de verificação entre as fases
6. Estruture `/docs/tasks.md` para que cada tarefa registre, no mínimo: identificador, status, dependências, critérios de aceitação, verificações e próximo checkpoint esperado
7. Inicialize `/docs/handoff.md` com: escopo atual, task ativa `Nenhuma`, riscos conhecidos, pendências abertas e instruções de retomada
8. Inicialize `/docs/lessons.md` com o template de lições aprendidas, mesmo que ainda não haja entradas
9. Apresente o plano para revisão humana

Salve o plano em `/docs/plan.md`, a lista de tarefas em `/docs/tasks.md`, o estado operacional inicial em `/docs/handoff.md` e o registro de lições em `/docs/lessons.md`.