---
description: Implemente a próxima tarefa incrementalmente — compile, teste, verifique e confirme
---

Invoque a skill `incremental-implementation` juntamente com a skill `test-driven-development`.

Selecione a próxima tarefa pendente no plano. Para cada tarefa:

1. Leia os critérios de aceitação da tarefa
2. Carregue o contexto relevante (código existente, padrões, tipos)
3. Escreva um teste que falhe para o comportamento esperado (VERMELHO)
4. Implemente o código mínimo necessário para passar no teste (VERDE)
5. Execute o conjunto completo de testes para verificar regressões
6. Execute a compilação para verificar a compilação
7. Confirme com uma mensagem descritiva
8. Marque a tarefa como concluída e passe para a próxima

Se alguma etapa falhar, siga a skill `debugging-and-error-recovery`.