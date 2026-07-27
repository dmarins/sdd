---
name: observability-and-instrumentation
description: Instrumenta o código para que o comportamento em produção seja visível e diagnosticável. Use ao adicionar logging, métricas, tracing ou alertas. Use ao entregar qualquer funcionalidade que rode em produção e você precise de evidência de que funciona. Use quando problemas de produção forem reportados mas os dados disponíveis não permitirem dizer o que aconteceu.
---

# Observabilidade e Instrumentação

## Visão Geral

Código que você não consegue observar é código que você não consegue operar. Observabilidade é a capacidade de responder "o que o sistema está fazendo e por quê?" de fora, usando a telemetria que o código emite. Instrumentação não é um adendo pós-lançamento — ela é escrita junto com a funcionalidade, do mesmo jeito que os testes. Se uma funcionalidade sobe sem telemetria, o primeiro bug reportado por usuário vira arqueologia em vez de uma query.

## Quando Usar

- Construção de qualquer funcionalidade que rodará em produção
- Adição de um novo serviço, endpoint, job em background ou integração externa
- Um incidente de produção demorou demais para diagnosticar ("não dava para saber o que aconteceu")
- Configuração ou revisão de regras de alerta
- Revisão de um PR que adiciona I/O, retries, filas ou chamadas entre serviços

**NÃO é para:**
- Diagnosticar uma falha acontecendo agora — use a skill `debugging-and-error-recovery` (observabilidade é o que torna essa skill rápida da próxima vez)
- Perfilar e otimizar lentidão medida — use a skill `performance-optimization`
- Checklists de monitoramento no dia do lançamento e gatilhos de rollback — veja a skill `shipping-and-launch`; esta skill cobre a instrumentação que os alimenta

## O Processo

### 1. Defina "funcionando" antes de instrumentar

Telemetria sem uma pergunta é ruído. Antes de adicionar qualquer instrumentação, escreva 2–4 perguntas que um engenheiro de plantão fará sobre esta funcionalidade:

```
FUNCIONALIDADE: retry de pagamento no checkout
PERGUNTAS DO PLANTÃO:
1. Qual fração dos pagamentos tem sucesso na primeira tentativa vs após retry?
2. Quando um pagamento falha em definitivo, por quê? (erro do provider? timeout? validação?)
3. O provider de pagamento está mais lento que o normal?
-> Todo sinal abaixo deve ajudar a responder uma dessas.
```

Se você não consegue nomear as perguntas, não está pronto para instrumentar — vai logar tudo e aprender nada.

### 2. Escolha o sinal certo para cada pergunta

| Sinal | Responde | Perfil de custo | Exemplo |
|---|---|---|---|
| **Log estruturado** | "O que aconteceu neste caso específico?" | Por evento; cresce com o tráfego | `payment_failed` com código de erro do provider |
| **Métrica** | "Com que frequência / que velocidade, no agregado?" | Fixo por série; barato de consultar | latência p99 das chamadas ao provider |
| **Trace** | "Onde o tempo foi gasto entre serviços?" | Por requisição; geralmente amostrado | Um checkout lento, quebrado por salto |

Regra prática: métricas dizem **que** algo está errado, traces dizem **onde**, logs dizem **por quê**.

### 3. Logging estruturado

Logue eventos, não prosa. Cada linha de log é um objeto JSON com um nome de evento estável e campos legíveis por máquina. Em Go, use `log/slog` com o handler JSON:

```go
// RUIM: interpolação de string — não consultável, inconsistente
log.Printf("Payment %s failed for user %s after %d retries", id, userID, n)

// BOM: nome de evento estável + campos estruturados
slog.Warn("payment failed",
	"event", "payment_failed",
	"paymentId", id,
	"provider", "stripe",
	"errorCode", errCode,
	"attempt", n,
)
```

**Níveis de log — use com consistência:**

| Nível | Significado | Ação do plantão |
|---|---|---|
| `error` | Invariante quebrada; alguém pode precisar agir | Investigar |
| `warn` | Degradado mas tratado (retry teve sucesso, fallback usado) | Observar tendências |
| `info` | Evento de negócio significativo (pedido criado, job concluído) | Nenhuma |
| `debug` | Detalhe de diagnóstico | Desligado em produção por padrão |

**Correlation IDs são obrigatórios.** Gere (ou aceite) um request ID na borda do sistema e anexe-o a toda linha de log, span e chamada de saída. Sem ele, você não consegue reconstruir uma requisição a partir de logs intercalados. Em Lambdas atrás do API Gateway, use o request ID que a plataforma já fornece:

```go
// Handler Lambda: logger filho por invocação, ID propagado adiante
func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	requestID := req.RequestContext.RequestID
	logger := slog.Default().With("requestId", requestID)
	ctx = withLogger(ctx, logger) // disponível para todas as camadas via context
	// ...
}
```

**Nunca logue segredos, tokens, senhas ou PII completa.** Esta é uma regra rígida da skill `security-and-hardening` — pipelines de telemetria são um caminho clássico de vazamento de dados. Use allowlist de campos; não logue corpos de requisição inteiros.

### 4. Métricas

Para serviços orientados a requisição, instrumente **RED** em todo endpoint e toda dependência externa: **R**ate (requisições/seg), **E**rrors (taxa de falha), **D**uration (histograma de latência, não média). Para recursos (filas, pools, hosts), use **USE**: **U**tilization, **S**aturation, **E**rrors.

Como no tracing, o caminho vendor-neutral é a API de métricas do OpenTelemetry (mesmo SDK e contexto do passo 5). Em Lambdas na AWS, o CloudWatch Embedded Metric Format (EMF) é uma escolha comum de backend — métricas saem como logs estruturados, sem chamada de rede extra; as regras de RED/USE e cardinalidade são idênticas em qualquer caso:

```go
// CloudWatch EMF via aws-embedded-metrics ou emissão direta no stdout:
// dimensões de conjunto pequeno e fixo; valores ilimitados ficam fora
metrics.PutMetric("ProviderCallDuration", durationMs, emf.Milliseconds)
metrics.SetDimensions(map[string]string{
	"Service":     "checkout",
	"Provider":    "stripe",
	"StatusClass": "5xx", // '5xx', não '502'
})
```

**Cardinalidade é o modo de falha.** Cada combinação única de dimensões é uma série temporal separada. Dimensões devem vir de conjuntos pequenos e fixos (template da rota, classe de status, nome do provider). Nunca use user IDs, URLs cruas, mensagens de erro ou outros valores ilimitados como dimensão — isso pertence a logs e traces.

```
OK como dimensão:    route="/api/tasks/{id}"   status_class="5xx"   provider="stripe"
NUNCA como dimensão: user_id, email, request_id, URL completa, texto de mensagem de erro
```

Nunca acompanhe médias, sempre percentis: uma média esconde o 1% de usuários com uma experiência péssima. Use histogramas e leia p50/p95/p99.

### 5. Tracing distribuído

Use OpenTelemetry — é o padrão vendor-neutral, e a auto-instrumentação cobre HTTP, gRPC e clientes de banco comuns com quase zero código. Na AWS, o OTel exporta para o X-Ray via ADOT (AWS Distro for OpenTelemetry):

```go
// main.go — configure o tracer antes de tudo
import (
	"go.opentelemetry.io/contrib/instrumentation/github.com/aws/aws-sdk-go-v2/otelaws"
	"go.opentelemetry.io/otel"
)

// Instrumenta todas as chamadas do AWS SDK (DynamoDB, SQS, etc.)
cfg, _ := config.LoadDefaultConfig(ctx)
otelaws.AppendMiddlewares(&cfg.APIOptions)
```

Adicione spans manuais apenas em torno de unidades internas de trabalho significativas (ex.: `applyDiscounts`, `chargeProvider`) e anexe os atributos pelos quais o plantão vai filtrar. Propague o contexto por toda fronteira assíncrona — headers HTTP, metadados de mensagem SQS — ou o trace morre no vão. Amostre head-based em taxa baixa por padrão; mantenha 100% dos erros se o backend suportar tail sampling.

### 6. Alertas

Alerte sobre **sintomas que os usuários sentem**, não sobre causas:

```
SINTOMA (merece acionar o plantão):   CAUSA (dashboard, não aciona):
taxa de erro > 1% por 5 min           CPU a 85%
latência p99 > 2s                     um pod reiniciou
idade da fila > 10 min                disco a 70%
```

Alertas baseados em causa disparam quando nada está errado e perdem falhas que você não previu. Alertas baseados em sintoma disparam exatamente quando os usuários estão sofrendo, seja qual for a causa.

Regras para todo alerta que você criar:

1. **Precisa ser acionável.** Se a resposta é "ignora, se resolve sozinho", delete o alerta.
2. **Aponta para um runbook** — mesmo que de três linhas: o que significa, primeira query a rodar, caminho de escalação.
3. **Tem limiar e duração** justificados pelo SLO ou por dados históricos, não por chute.
4. Use apenas duas severidades: **page** (impacto no usuário, aja agora) e **ticket** (degradação, aja esta semana). Um terceiro nível vira ruído que treina as pessoas a ignorar tudo.

### 7. Verifique a própria telemetria

Instrumentação é código; pode estar errada. Antes de dar o trabalho por concluído, acione os caminhos e olhe a saída real:

- Force um erro em staging → encontre-o nos logs pelo `requestId`, confirme que os campos estão estruturados (não serializações quebradas)
- Envie tráfego de teste → confirme que as séries de métricas aparecem com as dimensões esperadas e valores sensatos
- Siga uma requisição entre serviços na UI de tracing (X-Ray ou equivalente) → sem spans quebrados
- Dispare cada alerta novo uma vez (baixe o limiar temporariamente) → confirme que chega no canal certo e que o link do runbook funciona

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Adiciono logging depois que funcionar" | "Depois" vira "depois do primeiro incidente", que é o momento mais caro para descobrir que você está cego. Instrumente enquanto constrói. |
| "Mais logs = mais observabilidade" | Ruído não estruturado torna incidentes mais lentos, não mais rápidos. Três eventos consultáveis vencem trezentas linhas de prosa. |
| "fmt.Println resolve por enquanto" | Saída não estruturada não pode ser filtrada, correlacionada nem gerar alerta. O logger estruturado custa cinco minutos extras, uma vez. |
| "A gente olha os dashboards quando algo quebrar" | Dashboards construídos sem perguntas definidas mostram tudo, menos a resposta. Comece pelas perguntas do plantão. |
| "Alerta em tudo que é importante, ajustamos depois" | Um pager barulhento treina as pessoas a ignorá-lo. O ajuste nunca acontece; o page real perdido, sim. |
| "User ID como dimensão de métrica facilita o debug" | Também derruba o backend de métricas. Buscas de alta cardinalidade pertencem a logs e traces. |
| "Tracing é exagero para nossos dois serviços" | Dois serviços já significam perguntas de latência entre serviços que logs não respondem. A auto-instrumentação torna o custo trivial. |

## Sinais de Alerta

- Um PR de funcionalidade com retries, filas ou chamadas externas e zero telemetria nova
- Linhas de log montadas por interpolação de string em vez de campos estruturados
- Sem correlation/request ID — cada linha de log é órfã
- Métricas com dimensões de user ID, URL crua ou texto de mensagem de erro (bomba de cardinalidade)
- Latência acompanhada como média, sem percentis
- Alertas que disparam diariamente e são reconhecidos sem ação
- Alertas de causa (CPU, memória) acionando humanos enquanto a taxa de erro visível ao usuário não é monitorada
- Segredos, tokens ou corpos de requisição inteiros aparecendo em logs
- "Funciona na minha máquina" como única evidência de que uma funcionalidade de produção está saudável

## Verificação

Depois de instrumentar uma funcionalidade, confirme:

- [ ] As perguntas do plantão para esta funcionalidade estão escritas, e cada sinal mapeia para uma delas
- [ ] Toda saída de log é estruturada (JSON), com nomes de evento estáveis e correlation ID em toda linha
- [ ] Nenhum segredo, token ou PII sem redação em qualquer linha de log (confira a saída real por amostragem)
- [ ] Métricas RED existem para todo endpoint novo e toda dependência externa, com conjuntos de dimensões limitados
- [ ] Latência é um histograma; p95/p99 são consultáveis
- [ ] Uma única requisição pode ser seguida de ponta a ponta na UI de tracing sem spans quebrados
- [ ] Todo alerta novo é baseado em sintoma, tem link de runbook e foi disparado uma vez em teste
- [ ] Uma falha induzida em staging foi localizada apenas via telemetria, sem ler o código-fonte

Para a versão resumida desta lista, incluindo o gate de instrumentação pré-lançamento, veja `references/observability-checklist.md`.
