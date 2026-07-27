---
description: Simplifique o código para maior clareza e facilidade de manutenção — reduza a complexidade sem alterar o comportamento.
---

Invoque a habilidade `code-simplification`.

Simplifique o código alterado recentemente (ou o escopo especificado) preservando o comportamento exato:

1. Leia o arquivo CLAUDE.md e estude as convenções do projeto.
2. Identifique o código alvo — alterações recentes, a menos que um escopo mais amplo seja especificado.
3. Compreenda a finalidade do código, seus chamadores, casos extremos e a cobertura de testes antes de modificá-lo.
4. Procure oportunidades de simplificação:
    - Aninhamento profundo → cláusulas de guarda ou funções auxiliares extraídas
    - Funções longas → dividir por responsabilidade
    - Instruções ternárias aninhadas → if/else ou switch
    - Nomes genéricos → nomes descritivos
    - Lógica duplicada → funções compartilhadas
    - Código morto → remover após confirmação
5. Aplique cada simplificação incrementalmente — execute os testes após cada alteração.
6. Verifique se todos os testes são aprovados, se a compilação é bem-sucedida e se o diff está correto.

Se os testes falharem após uma simplificação, reverta a alteração e reconsidere. Use o `code-review-and-quality` para revisar o resultado.