---
description: Registre uma lição aprendida a partir de erro validado ou achado de review e promova a regra quando ela for global
---

Invoque as skills `documentation-and-adrs` e `context-engineering`.

Use este comando quando:

- você identificar manualmente uma decisão errada do agente
- o `/review` encontrar um antipadrão recorrente ou um desvio da convenção do projeto
- um bug corrigido revelar um gap de processo ou de skill
- uma retomada mostrar que o mesmo erro já apareceu antes

Forma de uso recomendada:

```text
/learn o arquivo X foi alterado fora do padrão do projeto; deveria seguir o padrão Y usado em Z
```

ou:

```text
/learn no review identificamos que a task foi concluída com acoplamento indevido entre handler e repositório; o correto era manter a regra no service
```

Quanto mais concreta for a descrição inicial, melhor a qualidade da lição registrada e da eventual promoção para skill, comando, instrução ou ADR.

Ao executar `/learn`:

1. Leia `/docs/lessons.md`, `/docs/handoff.md`, os achados relevantes de review ou debug e o estado atual do Git
2. Capture o erro com evidência suficiente antes de generalizar a regra
3. Gere o próximo `lesson ID` disponível e classifique a lição com `origin`, `category`, `severity`, `scope`, `target` e `status`
4. Registre a lição em `/docs/lessons.md`, atualizando o índice e criando a entrada detalhada
5. Se a lição for apenas local, mantenha-a em `/docs/lessons.md` como `APPLIED_LOCALLY` ou `OPEN`
6. Se a lição for global, atualize imediatamente o artefato correto no mesmo fluxo:
   - `skill` -> atualizar a skill relevante com referência ao `lesson ID`
   - `command` -> atualizar o comando relevante com referência ao `lesson ID`
   - `instruction` -> atualizar a instrução relevante com referência ao `lesson ID`
   - `adr` -> criar ou atualizar o ADR correspondente quando a decisão for arquitetural
7. Após a promoção, marque a lição como `PROMOTED` e registre o arquivo-alvo atualizado
8. Nunca promova uma lição silenciosamente fora de `/learn` ou sem confirmação humana explícita

Se a classificação ainda estiver ambígua, faça perguntas curtas antes de registrar ou promover a lição.