---
description: Realize uma revisão de código em cinco eixos — correção, legibilidade, arquitetura, segurança e desempenho
---

Invoque a habilidade `code-review-and-quality`.

Revise as alterações atuais (commits recentes ou em fase de preparação) em todos os cinco eixos:

1. **Correção** — Está de acordo com a especificação? Os casos extremos foram tratados? Os testes são adequados?
2. **Legibilidade** — Nomes claros? Lógica direta? Bem organizado?
3. **Arquitetura** — Segue padrões existentes? Limites bem definidos? Nível de abstração adequado?
4. **Segurança** — Entrada validada? Segredos seguros? Autenticação verificada? (Use a habilidade `security-and-hardening`)
5. **Desempenho** — Sem consultas N+1? Sem operações ilimitadas? (Use a habilidade `performance-optimization`)

Classifique as descobertas como Críticas, Importantes ou Sugestões.

Gere uma análise estruturada com referências específicas de arquivo:linha e recomendações de correção.

Se um achado revelar um padrão recorrente, um desvio de convenção do projeto ou um gap claro de skill/processo:

1. Resuma o padrão com evidência concreta
2. Pergunte se o usuário quer registrar isso via `/learn`
3. Ao sugerir `/learn`, entregue o contexto mínimo já estruturado:
	- arquivo ou área afetada
	- o que foi feito de forma errada
	- como deveria ser
	- qual padrão, convenção ou regra foi violado
4. Sempre que possível, proponha a frase inicial que o usuário pode reaproveitar diretamente, por exemplo:

```text
/learn no review identificamos que o arquivo X foi alterado de forma errada; deveria seguir Y em vez de Z porque o projeto usa o padrão W
```

ou:

```text
/learn o review encontrou duplicação da regra A nos arquivos X e Y; o correto era centralizar isso em Z
```

5. Não atualize `/docs/lessons.md`, skills ou comandos silenciosamente fora de `/learn` ou sem confirmação humana explícita