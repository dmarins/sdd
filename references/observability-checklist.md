# Checklist de Observabilidade

Referência rápida para instrumentar código de produção. Use em conjunto com a skill `observability-and-instrumentation`.

## Sumário

- [Perguntas do Plantão (Comece Aqui)](#perguntas-do-plantão-comece-aqui)
- [Logging Estruturado](#logging-estruturado)
- [Métricas](#métricas)
- [Tracing Distribuído](#tracing-distribuído)
- [Alertas](#alertas)
- [Dashboards](#dashboards)
- [Verifique a Telemetria](#verifique-a-telemetria)
- [Gate Pré-Lançamento](#gate-pré-lançamento)

## Perguntas do Plantão (Comece Aqui)

Telemetria sem uma pergunta é ruído. Antes de instrumentar qualquer coisa:

- [ ] 2–4 perguntas que um engenheiro de plantão fará sobre esta funcionalidade estão escritas
- [ ] Todo sinal abaixo mapeia para uma dessas perguntas
- [ ] Cada pergunta está casada com o tipo certo de sinal: métricas dizem **que** algo está errado, traces dizem **onde**, logs dizem **por quê**

## Logging Estruturado

- [ ] Logs são estruturados (JSON) com nomes de evento estáveis — não strings livres (em Go, `log/slog` com handler JSON)
- [ ] Toda linha de log carrega um correlation/request ID, gerado ou aceito na borda do sistema (em Lambdas, o request ID do API Gateway)
- [ ] O correlation ID é propagado em toda chamada de saída e fronteira assíncrona (headers HTTP, metadados de mensagem SQS)
- [ ] Níveis de log consistentes: `error` = invariante quebrada, alguém pode agir; `warn` = degradado mas tratado; `info` = evento de negócio significativo; `debug` = desligado em produção
- [ ] Nenhum segredo, token, senha ou PII sem redação em qualquer linha de log (regra rígida de `security-and-hardening`)
- [ ] Campos em allowlist — sem corpos inteiros de requisição/resposta, sem headers de autenticação
- [ ] Chamadas a serviços externos logadas apenas com metadados: endpoint, status, latência, contagem de tentativas, identificadores sanitizados
- [ ] Saída real de log conferida por amostragem: campos estruturados, sem serializações quebradas

## Métricas

- [ ] **RED** instrumentado para todo endpoint e toda dependência externa: Rate, Errors, Duration
- [ ] **USE** instrumentado para todo recurso (filas, pools, hosts): Utilization, Saturation, Errors
- [ ] Latência é um histograma; p50/p95/p99 consultáveis — nunca uma média
- [ ] Todas as dimensões vêm de conjuntos pequenos e fixos (template da rota, classe de status, nome do provider)
- [ ] Sem valores ilimitados como dimensão: sem user IDs, tenant IDs, e-mails, URLs cruas, request IDs ou texto de mensagem de erro
- [ ] Códigos de status agrupados por classe (`5xx`, não `503`)
- [ ] Profundidade de fila e duração de processamento acompanhadas para todo worker/fila

## Tracing Distribuído

- [ ] OpenTelemetry (ou equivalente, como ADOT/X-Ray na AWS) inicializado na partida do serviço, antes das demais dependências
- [ ] Auto-instrumentação habilitada para HTTP, gRPC e clientes de banco (incluindo o AWS SDK via `otelaws`)
- [ ] Contexto de trace propagado em toda chamada de saída (W3C `traceparent`/`tracestate`) e extraído de toda requisição de entrada
- [ ] O contexto sobrevive a fronteiras assíncronas — mensagens de fila carregam metadados de trace
- [ ] Spans manuais apenas em torno de unidades internas de trabalho significativas, com os atributos pelos quais o plantão vai filtrar
- [ ] Nenhum segredo ou PII como atributo de span
- [ ] Amostragem head-based em taxa baixa por padrão; 100% dos erros mantidos se tail sampling estiver disponível

## Alertas

- [ ] Todo alerta é baseado em sintoma (taxa de erro, latência p99, idade da fila) — causas (CPU, disco, restarts) vão para dashboards, não para o pager
- [ ] Todo alerta é acionável; alertas do tipo "ignora, se resolve sozinho" são deletados
- [ ] Todo alerta aponta para um runbook — mínimo de três linhas: o que significa, primeira query a rodar, caminho de escalação
- [ ] Limiares e durações justificados por um SLO ou por dados históricos, não por chutes
- [ ] Apenas duas severidades: **page** (impacto no usuário, aja agora) e **ticket** (degradação, aja esta semana)
- [ ] Cada alerta novo foi disparado uma vez em teste: chegou ao canal certo e o link do runbook funciona
- [ ] Nenhum alerta que dispara diariamente e é reconhecido sem ação

## Dashboards

- [ ] Existe dashboard de saúde do serviço: taxa de erro, latência p99, tráfego, saturação
- [ ] Painel de saúde das dependências mostra taxa de erro e latência por serviço
- [ ] O dashboard responde às perguntas do plantão do topo desta checklist — não "tudo, menos a resposta"
- [ ] O intervalo de tempo padrão é sensato (1h–6h, não 30d)

## Verifique a Telemetria

Instrumentação é código; pode estar errada:

- [ ] Forcei um erro em staging → encontrei-o nos logs pelo correlation ID
- [ ] Enviei tráfego de teste → séries de métricas aparecem com as dimensões esperadas e valores sensatos
- [ ] Segui uma requisição de ponta a ponta na UI de tracing → sem spans quebrados
- [ ] Uma falha induzida foi diagnosticada apenas via telemetria, sem ler o código-fonte

## Gate Pré-Lançamento

Antes de uma funcionalidade subir para produção, tudo isto é verdade:

- [ ] Logs estruturados fluindo para o agregador de logs (CloudWatch Logs ou equivalente)
- [ ] Métricas RED visíveis em dashboards para todo endpoint e dependência novos
- [ ] Pelo menos um alerta baseado em sintoma configurado, com runbook, disparado em teste
- [ ] Uma requisição pode ser rastreada por todos os serviços que toca
- [ ] O plantão sabe onde os runbooks estão

Para a sequência de monitoramento no dia do lançamento e os gatilhos de rollback, veja a skill `shipping-and-launch`.
