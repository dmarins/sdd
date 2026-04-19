# Referência de Padrões de Teste

Referência rápida para padrões comuns de teste no stack. Use em conjunto com a skill `test-driven-development`.

## Sumário

- [Estrutura de Teste (Arrange-Act-Assert)](#estrutura-de-teste-arrange-act-assert)
- [Convenções de Nomes de Teste](#convenções-de-nomes-de-teste)
- [Asserções Comuns](#asserções-comuns)
- [Padrões de Mock](#padrões-de-mock)
- [Testes de API e Integração](#testes-de-api-e-integração)
- [Testes E2E](#testes-e2e)
- [Antipadrões de Teste](#antipadrões-de-teste)

## Estrutura de Teste (Arrange-Act-Assert)

```go
func TestCreateTask(t *testing.T) {
	// Arrange: prepara dados e pré-condições
	input := CreateTaskInput{Title: "Test Task", Priority: "high"}

	// Act: executa a ação testada
	result, err := createTask(context.Background(), input)

	// Assert: verifica o resultado
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.Title != "Test Task" {
		t.Fatalf("expected title Test Task, got %s", result.Title)
	}
	if result.Priority != "high" {
		t.Fatalf("expected priority high, got %s", result.Priority)
	}
	if result.Status != "pending" {
		t.Fatalf("expected status pending, got %s", result.Status)
	}
}
```

## Convenções de Nomes de Teste

```go
func TestTaskService_CreateTask_SetsDefaultPendingStatus(t *testing.T) {}
func TestTaskService_CreateTask_ReturnsValidationErrorWhenTitleIsEmpty(t *testing.T) {}
func TestTaskService_CreateTask_TrimsWhitespaceFromTitle(t *testing.T) {}
func TestTaskService_CreateTask_GeneratesUniqueID(t *testing.T) {}
```

## Asserções Comuns

```go
if got != expected {
	t.Fatalf("expected %v, got %v", expected, got)
}

if len(items) != 3 {
	t.Fatalf("expected 3 items, got %d", len(items))
}

if err == nil {
	t.Fatal("expected error, got nil")
}

if !errors.Is(err, ErrValidation) {
	t.Fatalf("expected ErrValidation, got %v", err)
}

if diff := cmp.Diff(want, got); diff != "" {
	t.Fatalf("unexpected diff (-want +got):\n%s", diff)
}
```

## Padrões de Mock

### Fakes e Stubs em Go

```go
type fakeTaskRepository struct {
	createFn func(ctx context.Context, task Task) error
}

func (f fakeTaskRepository) Create(ctx context.Context, task Task) error {
	return f.createFn(ctx, task)
}
```

### Mocks Gerados

```bash
# Exemplo com mockgen
mockgen -source=internal/tasks/repository.go -destination=internal/tasks/repository_mock_test.go -package=tasks
```

### Faça Mock Só nas Fronteiras

```
Faça mock destes:              Não faça mock destes:
├── chamadas de banco          ├── funções utilitárias internas
├── requests HTTP              ├── lógica de negócio
├── operações de filesystem    ├── transformações de dados
├── chamadas a APIs externas   ├── funções de validação
└── tempo/data, quando preciso └── funções puras
```

## Testes de API e Integração

```go
func TestCreateTaskHandler(t *testing.T) {
	handler := NewCreateTaskHandler(fakeService{})
	req := httptest.NewRequest(http.MethodPost, "/v1/tasks", strings.NewReader(`{"title":"Test Task"}`))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d", rr.Code)
	}
}
```

## Testes E2E

```text
Fluxo E2E crítico:
1. Autenticar
2. Criar recurso principal
3. Confirmar persistência
4. Disparar integração relevante
5. Verificar efeito observável, como evento, fila, resposta de API ou estado final
```

## Antipadrões de Teste

| Antipadrão | Problema | Abordagem Melhor |
|---|---|---|
| Testar detalhes de implementação | Quebra em refactor | Teste entradas e saídas |
| Snapshot para tudo | Ninguém revisa diffs grandes | Faça asserts específicos |
| Estado mutável compartilhado | Um teste polui o outro | Setup e teardown por teste |
| Testar código de terceiros | Perda de tempo, não é seu bug | Faça mock na fronteira |
| Pular teste para passar CI | Esconde bug real | Corrija ou remova o teste |
| Usar `t.Skip()` permanentemente | Código morto | Remova ou corrija |
| Asserções amplas demais | Não capturam regressões | Seja específico |
| Falta de tratamento correto de erro assíncrono | Falso positivo | Sempre espere a conclusão e valide erro explicitamente |
