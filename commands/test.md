---
description: Execute o fluxo de trabalho TDD — escreva testes que falham, implemente e verifique. Para bugs, use o padrão Prove-It.
---

Invoque a habilidade `test-driven-development`.

Para novos recursos:
1. Escreva testes que descrevam o comportamento esperado (eles devem FALHAR)
2. Implemente o código para que eles passem
3. Refatore mantendo os testes passando

Para correções de bugs (padrão Prove-It):
1. Escreva um teste que reproduza o bug (deve FALHAR)
2. Confirme se o teste falha
3. Implemente a correção
4. Confirme se o teste passa
5. Execute o conjunto completo de testes para regressões
6. Se o bug expuser um gap recorrente de processo, convenção ou skill, recomende registrar a lição via `/learn` após a correção estar verificada, levando ao comando:
	- arquivo ou área afetada
	- o que falhou ou foi decidido de forma errada
	- como deveria ser
	- qual padrão, convenção ou regra foi violado

Para problemas relacionados ao navegador (caso seja alguma aplicação frontend), invoque também `browser-testing-with-devtools` para verificar com o Chrome DevTools MCP.