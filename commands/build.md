---
description: Implemente a próxima tarefa incrementalmente — compile, teste, verifique e confirme
---

Invoque a skill `incremental-implementation` juntamente com a skill `test-driven-development`.

Se a tarefa estiver claramente no contexto de projetos Go com AWS e Terraform, invoque também a skill `go-aws-serverless-development` como perfil complementar de execução.

Antes de implementar, leia `/docs/plan.md`, `/docs/tasks.md`, `/docs/handoff.md` e verifique o estado atual do Git.

Selecione a task `IN_PROGRESS` existente ou a próxima task `TODO`. Para cada task:

1. Se a task ainda estiver em `TODO`, marque-a como `IN_PROGRESS` em `/docs/tasks.md`
2. Atualize `/docs/handoff.md` com objetivo atual, critérios de aceitação ativos, arquivos esperados e próximo passo planejado
3. Carregue o contexto relevante (código existente, padrões, tipos)
4. Escreva um teste que falhe para o comportamento esperado (VERMELHO)
5. Implemente o código mínimo necessário para passar no teste (VERDE)
6. Execute o conjunto completo de testes para verificar regressões
7. Execute a compilação para verificar a compilação
8. Atualize `/docs/handoff.md` com arquivos tocados, verificações executadas, blockers e o próximo passo exato
9. Crie um save point verificado por incremento, preferencialmente via commit pequeno e descritivo
10. Quando a task terminar, marque-a como `DONE` em `/docs/tasks.md`; se houver bloqueio, marque `BLOCKED` com a causa e pare antes de seguir para a próxima

Se alguma etapa falhar, siga a skill `debugging-and-error-recovery`.