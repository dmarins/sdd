---
name: api-and-interface-design
description: Orienta o design estável de APIs e interfaces. Use ao projetar APIs, limites entre módulos ou qualquer interface pública. Use ao criar endpoints REST ou GraphQL, definir contratos de tipos entre módulos ou estabelecer limites entre frontend e backend.
---

# Design de APIs e Interfaces

## Visão Geral

Projete interfaces estáveis, bem documentadas e difíceis de usar de forma incorreta. Boas interfaces tornam o caminho correto simples e o incorreto custoso. Neste repositório, isso se aplica principalmente a APIs HTTP, contratos OpenAPI, eventos publicados em filas ou barramentos, limites entre módulos Go e qualquer superfície em que um sistema converse com outro.

## Quando Usar

- Ao desenhar novos endpoints HTTP ou handlers Lambda
- Ao definir contratos entre times, serviços ou módulos internos em Go
- Ao modelar eventos para SQS, SNS ou EventBridge
- Ao criar schemas de banco que influenciam o formato da API
- Ao alterar qualquer interface pública já consumida por outros sistemas

## Princípios Centrais

### Lei de Hyrum

> Com usuários suficientes de uma API, todo comportamento observável do sistema passa a ser dependido por alguém, independentemente do que o contrato promete oficialmente.

Na prática: cada detalhe público, inclusive quirks não documentados, texto de erro, ordenação, paginação, latência percebida e campos opcionais, vira contrato de fato quando consumidores passam a depender disso. Implicações de design:

- **Seja intencional sobre o que expõe.** Todo comportamento observável pode virar compromisso.
- **Não vaze detalhes de implementação.** Se o consumidor consegue perceber, ele pode acoplar nisso.
- **Planeje descontinuação no momento do design.** Veja `deprecation-and-migration` para remover comportamentos com segurança.
- **Testes não bastam.** Mesmo com bons contract tests, mudanças “seguras” podem quebrar consumidores reais que dependem do não documentado.

### Regra de Uma Versão

Evite forçar consumidores a escolher entre várias versões do mesmo contrato. Problemas de dependência em diamante também aparecem em APIs e módulos compartilhados. Projete para um mundo em que uma única versão ativa exista por vez: prefira extensão compatível a bifurcações paralelas.

### 1. Contrato Primeiro

Defina a interface antes da implementação. O contrato é a especificação; o código vem depois.

```go
// O contrato vem antes do handler, do repositório e da infraestrutura.
type TaskService interface {
	// Cria uma tarefa e retorna o recurso persistido com campos gerados pelo servidor.
	CreateTask(ctx context.Context, input CreateTaskInput) (Task, error)

	// Lista tarefas com filtros e paginação explícitos.
	ListTasks(ctx context.Context, params ListTasksParams) (PaginatedResult[Task], error)

	// Busca uma tarefa ou retorna ErrTaskNotFound.
	GetTask(ctx context.Context, id TaskID) (Task, error)

	// Atualiza apenas os campos enviados.
	UpdateTask(ctx context.Context, id TaskID, input UpdateTaskInput) (Task, error)

	// Exclusão idempotente: sucesso mesmo se o recurso já não existir.
	DeleteTask(ctx context.Context, id TaskID) error
}
```

Para contratos externos, complemente a interface com OpenAPI ou AsyncAPI. Interfaces Go ajudam no código interno; especificações formais ajudam integrações, SDKs e revisão de breaking changes.

### 2. Semântica de Erro Consistente

Escolha uma estratégia de erro e aplique-a em toda a API:

```go
type APIErrorResponse struct {
	Error APIError `json:"error"`
}

type APIError struct {
	Code      string         `json:"code"`
	Message   string         `json:"message"`
	Details   map[string]any `json:"details,omitempty"`
	RequestID string         `json:"request_id,omitempty"`
}

// Mapeamento recomendado:
// 400 -> payload malformado
// 401 -> não autenticado
// 403 -> autenticado, mas sem permissão
// 404 -> recurso inexistente
// 409 -> conflito de versão, idempotency key ou estado
// 422 -> validação semântica falhou
// 500 -> erro interno (sem expor detalhes internos)
```

**Não misture padrões.** Se alguns handlers retornam `nil, nil`, outros serializam `{ error }` e outros propagam `panic`, o consumidor não consegue prever comportamento nem o operador consegue observar o sistema com consistência.

### 3. Valide nas Fronteiras

Confie no código interno tipado. Valide apenas quando dados não confiáveis entram no sistema:

```go
func CreateTaskHandler(svc TaskService) func(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	return func(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
		var input CreateTaskInput
		if err := json.Unmarshal([]byte(req.Body), &input); err != nil {
			return writeJSON(http.StatusBadRequest, APIErrorResponse{
				Error: APIError{
					Code:      "INVALID_JSON",
					Message:   "Corpo da requisicao invalido",
					RequestID: req.RequestContext.RequestID,
				},
			})
		}

		if validationErrs := ValidateCreateTaskInput(input); len(validationErrs) > 0 {
			return writeJSON(http.StatusUnprocessableEntity, APIErrorResponse{
				Error: APIError{
					Code:      "VALIDATION_ERROR",
					Message:   "Payload invalido para criacao de tarefa",
					Details:   validationErrs,
					RequestID: req.RequestContext.RequestID,
				},
			})
		}

		task, err := svc.CreateTask(ctx, input)
		if err != nil {
			return mapDomainError(err, req.RequestContext.RequestID)
		}

		return writeJSON(http.StatusCreated, task)
	}
}
```

Onde a validação pertence:
- Handlers HTTP e Lambda, onde o input entra
- Consumidores de SQS, SNS, EventBridge e DLQ
- Parsing de respostas de serviços externos e webhooks
- Carregamento de configuração e variáveis de ambiente

> **Resposta de terceiros também é dado não confiável.** Valide forma, conteúdo e enums antes de usar em lógica de negócio, autorização ou persistência.

Onde a validação NÃO pertence:
- Entre funções internas que já compartilham tipos e invariantes
- Em utilitários chamados por código já validado
- Em dados recém-lidos do seu próprio banco, salvo quando houver legado inconsistente que exija saneamento explícito

### 4. Prefira Adição a Modificação

Estenda contratos sem quebrar consumidores existentes:

```go
type CreateTaskInput struct {
	Title       string   `json:"title"`
	Description *string  `json:"description,omitempty"`
	Priority    *string  `json:"priority,omitempty"` // adicionado depois, opcional
	Labels      []string `json:"labels,omitempty"`   // adicionado depois, opcional
}

// Evite isto:
// - remover campos já públicos
// - trocar tipo de campo existente
// - reaproveitar um campo antigo com novo significado
```

Em APIs HTTP e eventos, compatibilidade retroativa quase sempre significa:
- Novos campos opcionais
- Novos valores de enum documentados
- Novos endpoints ou novos tipos de evento
- Campos antigos mantidos até migração completa

### 5. Nomes Previsíveis

| Padrão | Convenção | Exemplo |
|---|---|---|
| Endpoints REST | Substantivos no plural, sem verbos | `GET /v1/tasks`, `POST /v1/tasks` |
| Query params | `snake_case` consistente | `?sort_by=created_at&page_size=20` |
| Campos JSON | `snake_case` consistente | `{ "created_at": "...", "task_id": "..." }` |
| Campos booleanos | Prefixo semântico claro | `is_complete`, `has_attachments` |
| Valores de enum | `UPPER_SNAKE_CASE` | `"IN_PROGRESS"`, `"COMPLETED"` |

Consistência importa mais do que a preferência específica. Se o contrato público usa `snake_case`, mantenha isso em todos os endpoints, eventos e documentação.

## Padrões de API REST

### Design de Recursos

```
GET    /v1/tasks               -> Lista tarefas com filtros e paginação
POST   /v1/tasks               -> Cria uma tarefa
GET    /v1/tasks/{id}          -> Busca uma tarefa
PATCH  /v1/tasks/{id}          -> Atualiza parcialmente
DELETE /v1/tasks/{id}          -> Remove uma tarefa

GET    /v1/tasks/{id}/comments -> Lista comentarios da tarefa
POST   /v1/tasks/{id}/comments -> Adiciona comentario na tarefa
```

Para fluxos assíncronos, explicite também o contrato de evento:

```json
{
  "event_type": "TASK_CREATED",
  "event_version": 1,
  "task_id": "tsk_123",
  "tenant_id": "acme",
  "occurred_at": "2026-04-19T14:00:00Z"
}
```

### Paginação

Todo endpoint de lista deve paginar desde o início:

```http
GET /v1/tasks?page=1&page_size=20&sort_by=created_at&sort_order=desc
```

```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_items": 142,
    "total_pages": 8,
    "next_cursor": null
  }
}
```

Se a base crescer rápido, prefira paginação por cursor em vez de `offset` para manter latência estável.

### Filtros

Use query params para filtros simples:

```http
GET /v1/tasks?status=IN_PROGRESS&assignee_id=user_123&created_after=2026-01-01T00:00:00Z
```

Filtros compostos e caros devem ter limites claros, paginação obrigatória e comportamento determinístico de ordenação.

### Atualizações Parciais com PATCH

Receba apenas os campos alterados:

```json
PATCH /v1/tasks/tsk_123
{
  "title": "Titulo atualizado"
}
```

Se usar Go, diferencie “campo ausente” de “campo enviado vazio” com ponteiros ou tipos auxiliares de patch.

## Padrões de Interface em Go

### Use Tipos Explícitos para Variantes de Estado

Go não tem discriminated unions nativas, então modele estados com enums e campos explícitos:

```go
type TaskStatus string

const (
	TaskStatusPending    TaskStatus = "PENDING"
	TaskStatusInProgress TaskStatus = "IN_PROGRESS"
	TaskStatusCompleted  TaskStatus = "COMPLETED"
	TaskStatusCancelled  TaskStatus = "CANCELLED"
)

type TaskState struct {
	Status      TaskStatus `json:"status"`
	AssigneeID  *UserID    `json:"assignee_id,omitempty"`
	StartedAt   *time.Time `json:"started_at,omitempty"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
	CancelledAt *time.Time `json:"cancelled_at,omitempty"`
	Reason      *string    `json:"reason,omitempty"`
}
```

Documente invariantes: por exemplo, `completed_at` só pode existir quando `status == COMPLETED`.

### Separe Input de Output

```go
type CreateTaskInput struct {
	Title       string  `json:"title"`
	Description *string `json:"description,omitempty"`
}

type Task struct {
	ID          TaskID    `json:"id"`
	Title       string    `json:"title"`
	Description *string   `json:"description,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	CreatedBy   UserID    `json:"created_by"`
	State       TaskState `json:"state"`
	Version     int64     `json:"version"`
}
```

Input representa o que o cliente pode enviar. Output representa o recurso persistido e enriquecido pelo servidor.

### Use Tipos Nominais para IDs

```go
type TaskID string
type UserID string
type TenantID string

func (svc Service) GetTask(ctx context.Context, id TaskID) (Task, error) {
	return Task{}, nil
}
```

Isso evita confundir IDs diferentes e torna assinaturas mais legíveis.

## OpenAPI, Eventos e Persistência

- Mantenha OpenAPI versionado junto com o código do handler.
- Para eventos, use `event_version` explícito e evolução compatível.
- Em DynamoDB, modele chaves de acesso no contrato desde o início; filtros caros que exigem scan são cheiro ruim de API.
- Em PostgreSQL, não exponha detalhes de tabela diretamente; exponha recursos estáveis, não a implementação física.
- Em integrações com Lambda, documente timeouts, idempotência e requisitos de autenticação/IAM como parte do contrato operacional.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Documentamos a API depois" | O contrato é a primeira validação do design. Documente primeiro. |
| "Paginação pode esperar" | Assim que aparecerem 100+ registros, o endpoint vira risco operacional. |
| "Vamos usar PUT porque PATCH dá mais trabalho" | Consumidores quase sempre querem atualização parcial. Modele isso corretamente. |
| "Versionamos quando precisar" | Breaking change sem estratégia de compatibilidade quebra integrações em produção. |
| "Ninguém depende desse detalhe não documentado" | Lei de Hyrum: se é observável, alguém depende. |
| "Mantemos duas versões em paralelo" | Duas versões dobram custo de manutenção, observabilidade e suporte. |
| "API interna não precisa de contrato" | Consumidor interno continua sendo consumidor. Contratos evitam acoplamento acidental. |

## Sinais de Alerta

- Endpoints que retornam formatos diferentes dependendo da condição
- Erros inconsistentes entre handlers
- Validação espalhada no código interno em vez de concentrada nas bordas
- Mudanças breaking em campos existentes
- Endpoints de lista sem paginação
- Verbos em URLs REST (`/createTask`, `/getUsers`)
- Eventos consumidos sem validação de schema ou versão
- Respostas de terceiros usadas diretamente sem saneamento

## Verificação

Após desenhar ou alterar uma API:

- [ ] Todo endpoint tem schema claro de entrada e saída
- [ ] Erros seguem um formato único e previsível
- [ ] A validação acontece nas fronteiras do sistema
- [ ] Endpoints de lista suportam paginação
- [ ] Campos novos são aditivos e compatíveis com versões anteriores
- [ ] Convenções de nome são consistentes em HTTP, eventos e documentação
- [ ] OpenAPI, AsyncAPI ou equivalente foi versionado junto com a implementação
