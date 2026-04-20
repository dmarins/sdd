---
description: Retome uma implementação interrompida reconciliando o estado persistido em `/docs` com o worktree atual
---

Invoque as skills `context-engineering`, `incremental-implementation` e `git-workflow-and-versioning`.

Ao retomar uma sessão:

1. Leia `/docs/spec.md`, `/docs/plan.md`, `/docs/tasks.md` e `/docs/handoff.md`
2. Inspecione `git status`, os últimos commits e qualquer mudança não commitada
3. Reconcilie o estado persistido com o worktree:
   - Se houver task `IN_PROGRESS` e mudanças locais coerentes, continue dela
   - Se a última task estiver `DONE` e o worktree estiver limpo, selecione a próxima `TODO`
   - Se houver divergência entre `/docs` e o Git, resuma a divergência e peça decisão humana antes de continuar
4. Atualize `/docs/handoff.md` com o contexto reidratado: task ativa, arquivos já tocados, verificações já concluídas, blockers e próximo passo
5. Se `/docs/handoff.md` estiver ausente ou desatualizado, reconstrua um estado mínimo confiável antes de voltar a implementar
6. Retome a execução a partir do menor incremento verificável, em vez de assumir que o trabalho parcial estava concluído

Se a retomada for bem-sucedida, continue a implementação via `/build`.