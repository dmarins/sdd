---
name: performance-optimization
description: Otimiza o desempenho da aplicação. Use quando existirem requisitos de desempenho, quando suspeitar de regressões de performance ou quando Core Web Vitals ou tempos de carregamento precisarem melhorar. Use quando profiling revelar gargalos que precisam ser corrigidos.
---

# Otimizacao de Performance

## Visão Geral

Meça antes de otimizar. Trabalho de performance sem medição é chute, e chute leva a otimizações prematuras que aumentam complexidade sem melhorar o que importa. Em sistemas backend serverless com Go, AWS e Terraform, isso significa medir latência, cold starts, throughput, uso de memória, custo e gargalos reais em banco, filas, rede e serialização. Profile primeiro, identifique o gargalo real, corrija e meça de novo.

## Quando Usar

- Existem requisitos de performance na especificação, como SLOs, SLAs ou orçamento de custo por requisição
- Usuários, dashboards ou alarmes apontam lentidão
- Suspeita de regressao apos uma mudança
- O recurso precisa lidar com alto volume, bursts ou grandes volumes de dados
- Ha sinais de gargalo em Lambda, RDS, DynamoDB, SQS, EventBridge ou chamadas externas

**Quando NÃO usar:** não otimize sem evidência. Complexidade de performance sem necessidade cobra juros em manutenção.

## Métricas-Guia para Backend Serverless

| Metrica | Boa | Atencao | Ruim |
|---|---|---|---|
| Latência p95 de API | <= 200 ms | <= 500 ms | > 500 ms |
| Latência p99 de API | <= 500 ms | <= 1000 ms | > 1000 ms |
| Cold start de Lambda | <= 800 ms | <= 1500 ms | > 1500 ms |
| Taxa de erro | <= 0,5% | <= 2% | > 2% |
| Throttling | 0 | episodico | recorrente |
| Idade da fila / backlog | dentro do SLO | crescente | fora do SLO |

Se o sistema tambem tiver superficie web, métricas de browser continuam relevantes, mas o foco desta skill e backend-first.

## O Fluxo de Otimizacao

```
1. MEDIR       -> estabelecer baseline com dados reais
2. IDENTIFICAR -> achar o gargalo real, não o imaginado
3. CORRIGIR    -> atacar o gargalo especifico
4. VERIFICAR   -> medir de novo e confirmar melhora
5. PROTEGER    -> adicionar monitoração, budget ou teste de regressao
```

### Etapa 1: Medir

Use mais de uma fonte de evidencia:

- **Metrica de produção:** CloudWatch Metrics, X-Ray, Datadog, New Relic, OpenTelemetry, dashboards e alarmes
- **Perfil local ou controlado:** `pprof`, benchmarks em Go, testes de carga com `k6`, `vegeta` ou `wrk`
- **Metrica de banco e infra:** Performance Insights, logs lentos, DynamoDB throttling, conexoes, CPU, memoria

**Backend em Go:**

```bash
# Benchmarks e alocacoes
go test ./... -bench=. -benchmem

# CPU / heap profile quando a aplicacao suporta pprof
go tool pprof http://localhost:6060/debug/pprof/profile
go tool pprof http://localhost:6060/debug/pprof/heap

# Teste de carga local ou contra ambiente controlado
k6 run scripts/perf/orders-api.js
```

**Lambda / AWS:**

```bash
# Medir duracao e erros por funcao
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=orders-api

# Investigar traces e subsegmentos
aws xray batch-get-traces --trace-ids ...
```

### Onde Comecar a Medir

Use o sintoma para escolher a primeira lente:

```
O que esta lento?
├── Endpoint HTTP / API Gateway
│   ├── Tempo total alto? -> medir p50/p95/p99 e comparar por rota
│   ├── Tempo de integração alto? -> separar handler, banco e chamadas externas
│   └── Erro intermitente? -> correlacionar com throttling, timeout ou retries
├── Lambda
│   ├── Cold start alto? -> checar init, dependencias, arquitetura e memoria
│   ├── Duracao alta? -> profile de CPU, I/O, serializacao e chamadas AWS
│   └── Concurrency / throttling? -> avaliar limites, reserved concurrency e backpressure
├── Banco / armazenamento
│   ├── Query lenta? -> indexes, plano de execucao, N+1 e scans completos
│   ├── DynamoDB throttling? -> chave de particao, hot partitions, capacidade
│   └── Pool esgotado? -> conexoes, timeouts e reuse em Lambda
└── Processamento assincrono
    ├── Fila crescendo? -> consumers lentos, falhas ou throughput insuficiente
    ├── Retries em cascata? -> idempotencia, DLQ, jitter, backoff
    └── Evento atrasado? -> medir tempo ponta a ponta e gargalo por etapa
```

### Etapa 2: Identificar o Gargalo

Gargalos comuns por categoria:

| Sintoma | Causa provavel | Investigacao |
|---|---|---|
| API lenta | Query ruim, N+1, serializacao excessiva, chamada externa lenta | tracing, logs estruturados, perfil de endpoint |
| Crescimento de memoria | objetos grandes, caches sem limite, slices/copias desnecessarias | heap profile, allocs por requisicao |
| CPU alta | JSON excessivo, compressao, regex ruim, loop caro | CPU profile, benchmark focal |
| Lambda lenta no primeiro hit | pacote grande, SDK inicializado demais, VPC, pouca memoria | init duration, cold start traces |
| Throttling | concorrencia acima do limite, particao quente, burst inesperado | CloudWatch metrics e dashboards |
| Fila com atraso | consumidores insuficientes, retries sem limite, dependência externa lenta | idade da fila, DLQ, tracing por mensagem |

### Etapa 3: Corrigir Anti-Padroes Comuns

#### N+1 Queries

```go
// RUIM: busca pedidos e depois consulta cliente um a um
func LoadOrders(ctx context.Context, db *sql.DB) ([]OrderView, error) {
	orders, err := listOrders(ctx, db)
	if err != nil {
		return nil, err
	}

	views := make([]OrderView, 0, len(orders))
	for _, order := range orders {
		customer, err := findCustomerByID(ctx, db, order.CustomerID)
		if err != nil {
			return nil, err
		}
		views = append(views, OrderView{Order: order, Customer: customer})
	}

	return views, nil
}

// BOM: consulta consolidada ou prefetch controlado
const listOrdersWithCustomers = `
SELECT o.id, o.total_amount, c.id, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.account_id = $1
ORDER BY o.created_at DESC
LIMIT $2 OFFSET $3
`
```

#### Leitura Sem Limite ou Paginacao

```go
// RUIM: carrega tudo
rows, err := db.QueryContext(ctx, `SELECT id, status FROM orders`)

// BOM: pagina e ordena com critério estável
rows, err := db.QueryContext(ctx, `
	SELECT id, status
	FROM orders
	WHERE account_id = $1
	ORDER BY created_at DESC
	LIMIT $2 OFFSET $3
`, accountID, limit, offset)
```

#### Trabalho Demais no Handler da Lambda

```go
// RUIM: parse, validacao, regra de negocio, persistencia e resposta no mesmo bloco enorme
func Handle(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// 100+ linhas de logica misturada
}

// BOM: handler fino, use case separado e dependencias reutilizaveis
func Handle(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	input, err := decodeCreateOrderRequest(req.Body)
	if err != nil {
		return badRequest(err), nil
	}

	output, err := createOrderUseCase.Execute(ctx, input)
	if err != nil {
		return mapError(err)
	}

	return created(output), nil
}
```

#### Cold Start e Inicializacao Pesada

```go
// RUIM: criar clientes e carregar config toda vez dentro do handler
func Handle(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return serverError(err)
	}

	client := dynamodb.NewFromConfig(cfg)
	_ = client
	return ok(nil), nil
}

// BOM: inicializar uma vez por ambiente de execucao
var (
	awsConfig aws.Config
	ddbClient *dynamodb.Client
)

func init() {
	ctx := context.Background()
	var err error
	awsConfig, err = config.LoadDefaultConfig(ctx)
	if err != nil {
		panic(err)
	}
	ddbClient = dynamodb.NewFromConfig(awsConfig)
}
```

#### Cache Ausente em Dados Quentes e Pouco Mutaveis

```go
type ConfigCache struct {
	value     AppConfig
	expiresAt time.Time
	mu        sync.RWMutex
}

func (c *ConfigCache) Get(ctx context.Context, loader func(context.Context) (AppConfig, error)) (AppConfig, error) {
	c.mu.RLock()
	if time.Now().Before(c.expiresAt) {
		value := c.value
		c.mu.RUnlock()
		return value, nil
	}
	c.mu.RUnlock()

	c.mu.Lock()
	defer c.mu.Unlock()

	if time.Now().Before(c.expiresAt) {
		return c.value, nil
	}

	value, err := loader(ctx)
	if err != nil {
		return AppConfig{}, err
	}

	c.value = value
	c.expiresAt = time.Now().Add(5 * time.Minute)
	return value, nil
}
```

#### Terraform Sem Guardas de Performance ou Escalabilidade

```hcl
resource "aws_cloudwatch_metric_alarm" "orders_api_p95" {
  alarm_name          = "orders-api-p95-high"
  namespace           = "AWS/ApiGateway"
  metric_name         = "Latency"
  statistic           = "p95"
  period              = 60
  evaluation_periods  = 5
  threshold           = 500
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ApiName = aws_apigatewayv2_api.orders.name
  }
}
```

## Orcamento de Performance

Defina budgets e cobre-os em revisão e CI:

```
API p95: < 200 ms
API p99: < 500 ms
Cold start de Lambda: < 800 ms
Taxa de erro: < 0,5%
Throttling: zero em carga nominal
Fila principal: idade maxima < 30 s
Uso de memoria: < 80% do limite configurado
```

**Aplicacao pratica em CI e pre-release:**

```bash
# Benchmarks críticos
go test ./internal/... -bench=. -benchmem

# Teste de carga controlado
k6 run scripts/perf/orders-api.js

# Verificação de Terraform e alarmes
terraform validate
terraform plan
```

## Veja Tambem

Para checklists detalhados, budgets e exemplos de medicao, consulte `references/performance-checklist.md`.

## Justificativas Comuns

| Justificativa | Realidade |
|---|---|
| "A gente otimiza depois" | Divida entre micro-otimizacao e gargalo real. O obvio ruim deve ser corrigido cedo. |
| "Na minha maquina esta rapido" | Seu notebook não representa produção, concorrencia nem cold start. |
| "Essa otimizacao e obvia" | Se você não mediu, não sabe. |
| "Usuário não percebe 100 ms" | Em APIs e filas, 100 ms por etapa vira segundos no fluxo inteiro. |
| "A AWS escala por mim" | Escalar não corrige query ruim, serializacao excessiva ou desenho ruim de chave. |

## Sinais de Alerta

- Otimizacao sem dado de baseline
- Padroes N+1 em consultas e chamadas externas
- Endpoints sem paginacao ou limites
- Alarmes inexistentes para latência, erro e throttling
- Crescimento de bundle de dependencias ou pacote de Lambda sem revisão
- Ausencia de monitoração em produção
- Uso indiscriminado de cache sem TTL, invalidacao ou medicao de hit ratio

## Verificação

Depois de qualquer mudança relacionada a performance:

- [ ] Existem medidas de antes e depois com numeros especificos
- [ ] O gargalo especifico foi identificado e tratado
- [ ] p95, p99, erros e throttling ficaram dentro do esperado
- [ ] Não houve regressao funcional
- [ ] Budgets e alarmes continuam coerentes
- [ ] Os testes existentes continuam passando

