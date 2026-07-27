---
description: Execute uma auditoria de web performance via persona web-performance-auditor
---

O `/webperf` mira especificamente aplicações web. Não o use para bibliotecas utilitárias, CLIs ou código apenas de servidor sem saída voltada ao browser.

## Determine o modo

**Modo Deep** — ative quando qualquer um destes estiver disponível:
- Um arquivo de relatório Lighthouse JSON (ex.: `npx lighthouse <url> --output json --output-path ./report.json`, ou `npx -p chrome-devtools-mcp chrome-devtools lighthouse_audit --output-format=json` da CLI do Chrome DevTools MCP)
- Uma resposta JSON do PageSpeed Insights (inclui Lighthouse + CrUX)
- Uma resposta da API CrUX (requer `CRUX_API_KEY` ou `GOOGLE_API_KEY`)
- Um trace de performance do DevTools
- Uma URL ao vivo mais o servidor MCP `chrome-devtools` configurado no harness (o agente pode capturar métricas diretamente via `lighthouse_audit` e as ferramentas `performance_*`)
- A CLI do Chrome DevTools MCP invocada localmente (via `npx -p chrome-devtools-mcp chrome-devtools <tool>` ou após `npm i -g chrome-devtools-mcp`) — o usuário roda comandos como `chrome-devtools lighthouse_audit --output-format=json` e passa a saída JSON ao agente

**Modo Quick** — default quando nada acima está disponível. O agente varre o código-fonte em busca de antipadrões estruturais e rotula todo achado como `impacto potencial`.

## Rode a auditoria

Inicie o subagente `web-performance-auditor`. Passe explicitamente:

- Os arquivos, componentes ou diff sob revisão
- Quaisquer caminhos de artefato (Lighthouse JSON, PSI JSON, resposta CrUX, trace) ou conteúdo JSON colado
- A URL alvo ou o nome da página quando conhecidos
- Uma nota sobre o modo esperado (Quick ou Deep), para que o agente aponte entradas faltantes se a intenção era Deep

O subagente retorna um scorecard (preenchido apenas com valores com fonte), uma lista ranqueada de achados, observações positivas e recomendações proativas.

## Saída

Retorne o relatório completo de auditoria ao usuário. Nenhum passo de síntese ou merge é necessário — este é um comando de persona única.
