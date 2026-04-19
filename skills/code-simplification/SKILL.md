---
name: code-simplification
description: Simplifica código para clareza. Use ao refatorar código para clareza sem alterar o comportamento. Use quando o código funciona, mas está mais difícil de ler, manter ou estender do que deveria. Use ao revisar código que acumulou complexidade desnecessária.
---

# Simplificação de Código

> Inspirada no plugin Claude Code Simplifier. Adaptada aqui como uma skill agnóstica de modelo e orientada a processo para agentes que trabalham em bases backend com Go, AWS e Terraform.

## Visão Geral

Simplifique o código reduzindo complexidade sem alterar o comportamento observável. O objetivo não é ter menos linhas, e sim código mais fácil de ler, entender, modificar e depurar. Toda simplificação deve passar por um teste simples: "uma pessoa nova no time entenderia isso mais rápido do que a versão anterior?"

## Quando Usar

- Depois que um recurso funciona e os testes passam, mas a implementação está mais pesada do que deveria
- Durante revisão de código, quando problemas de legibilidade ou complexidade forem apontados
- Ao encontrar lógica profundamente aninhada, funções longas ou nomes pouco claros
- Ao refatorar código escrito sob pressão
- Ao consolidar lógica relacionada espalhada entre handlers, use cases, repositórios e módulos Terraform
- Depois de mesclar mudanças que introduziram duplicação ou inconsistências

**Quando NÃO usar:**

- O código já está limpo e legível; não simplifique por esporte
- Você ainda não entende o que o código faz; compreenda antes de simplificar
- O trecho é crítico de performance e a versão "mais simples" seria comprovadamente mais lenta
- O módulo será substituído por completo em seguida; simplificar código descartável é desperdício

## Os Cinco Princípios

### 1. Preserve o Comportamento Exatamente

Não mude o que o código faz, apenas como ele expressa isso. Entradas, saídas, efeitos colaterais, comportamento de erro e casos extremos devem permanecer idênticos. Se não houver confiança de que a simplificação preserva o comportamento, não faça a mudança.

```
PERGUNTE ANTES DE CADA MUDANÇA:
-> Isso produz a mesma saída para toda entrada válida e inválida?
-> O comportamento de erro permanece o mesmo?
-> Os mesmos efeitos colaterais continuam ocorrendo na mesma ordem?
-> Todos os testes existentes continuam passando sem alteração?
```

### 2. Siga as Convenções do Projeto

Simplificar é alinhar o código ao restante da base, não impor preferência pessoal. Antes de simplificar:

```
1. Leia CLAUDE.md, README ou convenções do projeto
2. Estude como o código vizinho resolve padrões parecidos
3. Siga o estilo do projeto para:
	- Organização de pacotes, imports e módulos
	- Assinaturas de função e interfaces
	- Convenções de nomenclatura
   - Tratamento e empacotamento de erros
	- Estrutura de handlers, use cases e repositórios
	- Organização de módulos Terraform e variáveis
```

Simplificação que quebra a consistência do projeto não é simplificação, é churn.

### 3. Prefira Clareza a Esperteza

Código explícito é melhor que código compacto quando a versão compacta exige pausa mental para ser entendida.

```go
// POUCO CLARO: condicionais demais em cascata
func statusLabel(order Order) string {
	if order.IsNew {
		return "new"
	}
	if order.IsPaid {
		return "paid"
	}
	if order.IsCancelled {
		return "cancelled"
	}
	return "processing"
}

// CLARO: fluxo direto e facil de seguir
func statusLabel(order Order) string {
	switch {
	case order.IsNew:
		return "new"
	case order.IsPaid:
		return "paid"
	case order.IsCancelled:
		return "cancelled"
	default:
		return "processing"
	}
}
```

```go
// POUCO CLARO: acumulação com lógica redundante
func countByOrder(events []OrderEvent) map[string]int {
	counts := map[string]int{}
	for _, event := range events {
		if _, ok := counts[event.OrderID]; !ok {
			counts[event.OrderID] = 0
		}
		counts[event.OrderID] = counts[event.OrderID] + 1
	}
	return counts
}

// CLARO: intenção direta
func countByOrder(events []OrderEvent) map[string]int {
	counts := make(map[string]int, len(events))
	for _, event := range events {
		counts[event.OrderID]++
	}
	return counts
}
```

### 4. Mantenha Equilíbrio

Simplificação também falha por excesso. Fique atento a estas armadilhas:

- **Inlining agressivo demais:** remover um helper que nomeava um conceito pode piorar o ponto de uso
- **Misturar responsabilidades:** juntar duas funções simples em uma função complexa não é simplificar
- **Remover abstrações úteis:** algumas abstrações existem por testabilidade, isolamento do AWS SDK ou extensibilidade real
- **Otimizar por contagem de linhas:** o objetivo não é menos linhas; é entendimento mais rápido

### 5. Limite ao Que Mudou

Por padrão, simplifique o código modificado recentemente. Evite refatorações paralelas em código não relacionado sem pedido explícito. Simplificação sem escopo polui o diff e aumenta o risco de regressão.

## O Processo de Simplificação

### Etapa 1: Entenda Antes de Tocar

Antes de mudar ou remover qualquer coisa, entenda por que aquilo existe. É o princípio da cerca de Chesterton: se há uma cerca no caminho e você não sabe por que ela está ali, não a derrube. Primeiro descubra a razão, depois decida se ela ainda faz sentido.

```
ANTES DE SIMPLIFICAR, RESPONDA:
- Qual é a responsabilidade deste código?
- Quem chama isso? O que isso chama?
- Quais são os casos extremos e caminhos de erro?
- Existem testes definindo o comportamento esperado?
- Por que isso pode ter sido escrito assim? (cold start, limite de Lambda, IAM, histórico do projeto?)
- O git blame ou o histórico explicam a decisão original?
```

Se você não consegue responder a essas perguntas, ainda não está pronto para simplificar.

### Etapa 2: Identifique Oportunidades Reais

Procure estes padrões. Cada um é um sinal concreto, não um cheiro vago.

**Complexidade estrutural:**

| Padrão | Sinal | Simplificação |
|---|---|---|
| Aninhamento profundo (3+ níveis) | Fluxo de controle difícil de seguir | Extraia guard clauses ou helpers nomeados |
| Funções longas (50+ linhas) | Várias responsabilidades | Divida em funções focadas com nomes descritivos |
| `if` repetido em vários handlers | Mesmo predicado em vários pontos | Extraia validação ou policy comum |
| Flags booleanas em funções | `process(true, false, true)` | Use struct de opções ou funções separadas |
| Terraform com ternários espalhados | Difícil prever o plano | Use `locals`, `for_each` e nomes intermediários |

**Nomeacao e legibilidade:**

| Padrão | Sinal | Simplificação |
|---|---|---|
| Nomes genéricos | `data`, `result`, `tmp`, `cfg` | Renomeie para refletir o conteúdo real |
| Abreviações obscuras | `ordSvc`, `reqCtx`, `ddbCfg` | Use palavras completas, exceto siglas óbvias |
| Nome enganoso | `GetOrder` grava auditoria e muda estado | Renomeie para o comportamento real |
| Comentários explicando o óbvio | `// incrementa contador` sobre `count++` | Remova o comentário |
| Comentários explicando o motivo | `// usa leitura eventual para reduzir custo` | Preserve, porque carregam intenção |

**Redundancia:**

| Padrão | Sinal | Simplificação |
|---|---|---|
| Lógica duplicada | Mesmo bloco em handlers e jobs | Extraia para use case ou helper compartilhado |
| Código morto | Branches inalcançáveis, variáveis não usadas, blocos comentados | Remova depois de confirmar que estão mortos |
| Wrappers sem valor | Função só repassa para o AWS SDK sem adicionar contrato | Inline ou simplifique a interface |
| Abstração exagerada | Fábrica para um único adaptador | Use a implementação direta |
| Conversões redundantes | `string([]byte(s))`, `fmt.Sprintf("%s", x)` | Remova o excesso |

### Etapa 3: Aplique Mudanças Incrementalmente

Faça uma simplificação por vez. Rode verificações depois de cada mudança. Refatoração deve ser separada de feature e de bugfix.

```
PARA CADA SIMPLIFICAÇÃO:
1. Faça a mudança
2. Rode os testes relevantes
3. Se tudo passar -> siga para a próxima simplificação
4. Se algo falhar -> reverta e reavalie
```

Evite agrupar muitas simplificações num único bloco não testado. Se quebrar, você precisa saber qual mudança causou isso.

**Regra dos 500:** se uma refatoração vai tocar mais de 500 linhas, invista em automação ou em uma estratégia mecânica revisável, e não em edição manual dispersa.

### Etapa 4: Verifique o Resultado

Ao final, compare o antes e o depois:

```
COMPARE ANTES E DEPOIS:
- A versão nova está realmente mais fácil de entender?
- Algum padrão novo ficou inconsistente com o restante da base?
- O diff está limpo e revisável?
- Um colega aprovaria isso como melhoria liquida?
```

Se a versão "simplificada" estiver mais difícil de entender ou revisar, reverta.

## Orientacoes por Linguagem e Camada

### Go

```go
// SIMPLIFICAR: wrapper desnecessario de erro
// Antes
func findOrder(ctx context.Context, repo OrderRepository, orderID string) (Order, error) {
	order, err := repo.FindByID(ctx, orderID)
	if err != nil {
		return Order{}, err
	}
	return order, nil
}

// Depois
func findOrder(ctx context.Context, repo OrderRepository, orderID string) (Order, error) {
	return repo.FindByID(ctx, orderID)
}

// SIMPLIFICAR: retorno booleano verboso
// Antes
func isValidStatus(status string) bool {
	if status == "pending" || status == "paid" || status == "cancelled" {
		return true
	}
	return false
}

// Depois
func isValidStatus(status string) bool {
	return status == "pending" || status == "paid" || status == "cancelled"
}

// SIMPLIFICAR: aninhamento desnecessario
// Antes
func handle(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	if req.PathParameters["id"] != "" {
		order, err := service.Get(ctx, req.PathParameters["id"])
		if err == nil {
			return ok(order), nil
		}
		return failure(err)
	}
	return badRequest("missing id"), nil
}

// Depois
func handle(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	orderID := req.PathParameters["id"]
	if orderID == "" {
		return badRequest("missing id"), nil
	}

	order, err := service.Get(ctx, orderID)
	if err != nil {
		return failure(err)
	}

	return ok(order), nil
}
```

### Terraform

```hcl
# SIMPLIFICAR: tags repetidas em varios recursos
# Antes
resource "aws_lambda_function" "orders" {
  function_name = "orders-api"
  tags = {
    Service = "orders"
    Env     = var.environment
    Owner   = "platform"
  }
}

resource "aws_cloudwatch_log_group" "orders" {
  name = "/aws/lambda/orders-api"
  tags = {
    Service = "orders"
    Env     = var.environment
    Owner   = "platform"
  }
}

# Depois
locals {
  common_tags = {
    Service = "orders"
    Env     = var.environment
    Owner   = "platform"
  }
}

resource "aws_lambda_function" "orders" {
  function_name = "orders-api"
  tags          = local.common_tags
}

resource "aws_cloudwatch_log_group" "orders" {
  name = "/aws/lambda/orders-api"
  tags = local.common_tags
}
```

```hcl
# SIMPLIFICAR: condicional espalhada
# Antes
resource "aws_lambda_alias" "live" {
  name             = var.environment == "prod" ? "live" : "staging"
  function_name    = aws_lambda_function.orders.function_name
  function_version = var.enable_canary ? aws_lambda_function.orders.version : "$LATEST"
}

# Depois
locals {
  alias_name        = var.environment == "prod" ? "live" : "staging"
  published_version = var.enable_canary ? aws_lambda_function.orders.version : "$LATEST"
}

resource "aws_lambda_alias" "live" {
  name             = local.alias_name
  function_name    = aws_lambda_function.orders.function_name
  function_version = local.published_version
}
```

## Justificativas Comuns

| Justificativa | Realidade |
|---|---|
| "Está funcionando, não preciso tocar" | Código que funciona mas é difícil de ler custa caro em toda mudança futura. |
| "Menos linhas sempre significa mais simples" | Um ternário denso de uma linha pode ser pior que cinco linhas explícitas. |
| "Já que estou aqui, vou simplificar esse outro trecho também" | Simplificação sem escopo gera diff barulhento e risco de regressão. |
| "Os tipos e interfaces já documentam tudo" | Tipos documentam estrutura, não necessariamente a intenção. |
| "Essa abstracao pode ser util depois" | Complexidade especulativa continua sendo complexidade. |
| "Quem escreveu devia ter um motivo" | Talvez. Verifique o histórico, mas não trate complexidade acidental como sagrada. |
| "Vou refatorar junto com a feature" | Misturar refatoração com feature piora revisão, rollback e leitura histórica. |

## Sinais de Alerta

- Simplificação que exige alterar testes para passar, indicando mudança de comportamento
- Código "simplificado" que ficou mais longo e mais difícil de seguir
- Renomeações guiadas por preferência pessoal em vez de convenções do projeto
- Remoção de tratamento de erro porque "deixa mais limpo"
- Simplificar código que você ainda não entende completamente
- Agrupar muitas simplificações num único commit difícil de revisar
- Refatorar fora do escopo sem ter sido solicitado

## Verificação

Depois de concluir uma rodada de simplificação:

- [ ] Todos os testes existentes passam sem modificação
- [ ] A compilação segue limpa e sem novos avisos
- [ ] Formatador e linter passam sem regressão de estilo
- [ ] Cada simplificação é incremental e revisável
- [ ] O diff está limpo, sem mudanças paralelas
- [ ] O código simplificado segue as convenções do projeto
- [ ] Nenhum tratamento de erro foi removido ou enfraquecido
- [ ] Nenhum código morto ficou para trás
- [ ] Um colega ou agente de revisão aprovaria a mudança como melhoria líquida

