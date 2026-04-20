---
name: documentation-and-adrs
description: Registra decisões e documentação. Use ao tomar decisões arquiteturais, alterar APIs públicas, lançar funcionalidades ou quando precisar registrar contexto que futuros engenheiros e agentes precisarão para entender o código-base.
---

# Documentação e ADRs

## Visão Geral

Documente decisões, não só código. A documentação de maior valor captura o *porquê*: contexto, restrições e trade-offs que levaram à decisão. Código mostra *o que* foi implementado; documentação explica *por que foi feito assim* e *quais alternativas foram consideradas*. Isso é essencial para pessoas e agentes que vão trabalhar neste código depois.

## Quando Usar

- Ao tomar decisão arquitetural relevante
- Ao escolher entre abordagens concorrentes
- Ao adicionar ou alterar uma API pública
- Ao entregar uma feature com impacto de comportamento
- Ao facilitar onboarding de novos membros ou agentes
- Quando você se pega explicando a mesma coisa repetidamente

**Quando NÃO usar:** não documente código óbvio e não escreva docs para protótipos descartáveis.

## Architecture Decision Records (ADRs)

ADRs registram o raciocínio por trás de decisões técnicas significativas. Estão entre as formas mais valiosas de documentação.

### Quando Escrever um ADR

- Ao escolher framework, biblioteca ou dependência importante
- Ao desenhar modelo de dados ou schema de banco
- Ao selecionar estratégia de autenticação
- Ao decidir arquitetura de API, filas ou integração assíncrona
- Ao escolher plataforma de hospedagem ou infraestrutura
- Em qualquer decisão cara de reverter

### Template de ADR

Armazene ADRs em `docs/decisions/` com numeração sequencial:

```markdown
# ADR-001: Usar API Gateway + AWS Lambda para a API publica

## Status
Accepted | Superseded by ADR-XXX | Deprecated

## Date
2026-04-19

## Context
Precisamos expor uma API HTTP para a plataforma de tarefas. Requisitos:
- Escalar sob demanda com custo baixo em ociosidade
- Integrar com IAM, CloudWatch e observabilidade AWS
- Deploy automatizado por Terraform
- Equipe pequena, com preferencia por operação enxuta

## Decision
Usar API Gateway HTTP API na frente de funcoes AWS Lambda escritas em Go.

## Alternatives Considered

### ECS/Fargate
- Pros: processo de longa duracao, mais controle de runtime
- Cons: maior carga operacional e custo base continuo
- Rejected: overkill para o perfil atual de trafego

### EC2 autogerenciada
- Pros: flexibilidade maxima
- Cons: operação, patching e autoscaling mais caros
- Rejected: não compensa para o tamanho atual da equipe

### ALB + Lambda
- Pros: integração simples em alguns cenarios
- Cons: menos aderente ao contrato HTTP público e ao modelo atual
- Rejected: API Gateway oferece controles e observabilidade melhores para a API externa

## Consequences
- O tempo de resposta precisa considerar cold starts
- Limites de timeout e payload da Lambda entram no design da API
- Terraform precisa gerenciar API Gateway, roles IAM e observabilidade
- O time ganha deploy mais simples e custo menor em baixa utilizacao
```

### Ciclo de Vida de ADR

```text
PROPOSED -> ACCEPTED -> (SUPERSEDED ou DEPRECATED)
```

- **Não apague ADR antigo.** Ele preserva contexto histórico.
- Se a decisão mudar, escreva um novo ADR referenciando o anterior.

## Documentação Inline

### Quando Comentar

Comente o *porquê*, não o *o quê*:

```go
// Ruim: repete o código
counter++

// Bom: explica a intencao não obvia
// Usamos janela deslizante para limitar burst por tenant.
// Reset em fronteira de janela evita que dois batches consecutivos
// dobrem a taxa efetiva permitida.
if now.Sub(windowStart) > windowSize {
	counter = 0
	windowStart = now
}
```

### Quando NÃO Comentar

```go
// Não comente o que ja esta claro no próprio código
func Sum(values []int) int {
	total := 0
	for _, value := range values {
		total += value
	}

	return total
}

// Não deixe TODO para algo que deveria ser feito agora
// TODO: tratar erro

// Não deixe código comentado
// oldImplementation()
```

### Documente Gotchas Reais

```go
// IMPORTANT: este bootstrap precisa rodar no init da Lambda.
// Se a carga de configuracao atrasar para a primeira requisicao,
// o cold start aumenta e pode estourar o SLA desse endpoint.
// Veja ADR-003 para o racional completo.
func InitializeConfig(ctx context.Context) error {
	// ...
	return nil
}
```

## Documentação de API

Para APIs públicas, bibliotecas ou contratos internos relevantes:

### Inline com Go Doc

```go
// CreateTask cria uma nova tarefa.
//
// O payload exige titulo e aceita descricao opcional.
// Retorna a tarefa persistida com ID e timestamps gerados pelo servidor.
//
// Erros possiveis:
// - ErrValidation quando o titulo e invalido
// - ErrUnauthorized quando o caller não tem credenciais validas
func (s Service) CreateTask(ctx context.Context, input CreateTaskInput) (Task, error) {
	// ...
	return Task{}, nil
}
```

### OpenAPI para APIs REST

```yaml
paths:
  /v1/tasks:
    post:
      summary: Criar tarefa
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateTaskInput'
      responses:
        '201':
          description: Tarefa criada
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'
        '422':
          description: Erro de validacao
```

Para eventos, considere também AsyncAPI ou documentação equivalente do envelope.

## Estrutura de README

Todo projeto deveria ter README cobrindo pelo menos:

```markdown
# Nome do Projeto

Um paragrafo curto explicando o objetivo do servico.

## Quick Start
1. Instale Go, Terraform e AWS CLI nas versoes suportadas
2. Baixe dependencias: `go mod download`
3. Configure ambiente: `cp .env.example .env`
4. Rode testes: `go test ./...`
5. Gere build local: `go build ./...`

## Commands
| Command | Description |
|---------|-------------|
| `go test ./...` | Executa os testes |
| `go vet ./...` | Analise estatica basica |
| `go build ./...` | Compila os binarios |
| `gofmt -w .` | Formata o código Go |
| `terraform -chdir=terraform validate` | Valida a infraestrutura |

## Architecture
Resumo da estrutura do servico, modulos e principais decisoes.
Link para ADRs e para o contrato OpenAPI.

## Contributing
Fluxo de PR, convencoes e verificacoes obrigatorias.
```

## Manutenção de Changelog

Para features entregues:

```markdown
# Changelog

## [1.2.0] - 2026-04-19
### Added
- Endpoint de criacao de tarefas com idempotencia (#123)
- Alarme para DLQ da fila de processamento (#124)

### Fixed
- Correcao de duplicidade em consultas de tarefas (#125)

### Changed
- Timeout da Lambda `task-api` reduzido para 10s com retry controlado (#126)
```

## Lessons Learned vs Gotchas vs ADRs

Use o artefato certo para o tipo certo de aprendizado:

- **`/docs/lessons.md`**: ponto de entrada para erro validado, achado de review ou gap de processo. Toda lição começa aqui.
- **Gotcha inline**: quando a prevenção precisa ficar colada ao código afetado para evitar recaída naquele ponto específico.
- **Skill, comando ou instrução**: quando a lição é generalizável e deve mudar o comportamento futuro do workflow.
- **ADR**: quando a lição expõe uma decisão arquitetural, trade-off duradouro ou mudança cara de reverter.

Regra prática:

1. Registre a lição em `/docs/lessons.md`
2. Se ela for apenas local, pare aí ou complemente com gotcha inline
3. Se ela for global, promova para o artefato correto com referência ao `lesson ID`
4. Se o impacto for arquitetural, complemente com ADR em vez de esconder tudo dentro da lição

## Promover de Planejado para Implementado

Quando o projeto separar documentação de planejamento e documentação de funcionalidade já entregue, trate essa promoção como parte da conclusão da tarefa.

Fluxo recomendado:

1. Valide a implementação final e as verificações operacionais
2. Remova ou atualize o item no material de planejamento
3. Promova o conteúdo equivalente para a documentação de implementado
4. Ajuste README, runbook, changelog ou índice quando a nova feature mudar a navegação da documentação

Não deixe o projeto em um estado em que a feature já existe no código, mas continue aparecendo só como plano.

## Documentação para Agentes

Considerações especiais para contexto de IA:

- **Arquivos de regras** como `.github/copilot-instructions.md` documentam convenções do projeto
- **Specs** evitam que agentes implementem comportamento errado
- **ADRs** explicam por que decisões antigas existem e evitam rediscussão
- **Lessons learned** preservam erros confirmados e a promoção explícita das regras que nasceram deles
- **Gotchas inline** impedem que agentes caiam em armadilhas recorrentes
- **OpenAPI/AsyncAPI** ajudam agentes a gerar handlers, clients e testes coerentes

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "O código já se documenta sozinho" | Código mostra o que; não mostra por quê, alternativas rejeitadas ou restrições. |
| "Escrevemos docs quando estabilizar" | Documentação ajuda a estabilizar. Escrever cedo testa o design. |
| "Ninguém lê docs" | Pessoas, agentes e o seu eu de daqui a três meses leem. |
| "ADR é overhead" | Dez minutos de ADR evitam horas de debate repetido depois. |
| "Comentários ficam desatualizados" | Comentários sobre o porquê envelhecem muito menos que comentários sobre o quê. |

## Sinais de Alerta

- Decisões arquiteturais sem racional escrito
- APIs públicas sem documentação ou contrato
- README que não explica como rodar o projeto
- Código comentado em vez de removido
- TODOs abandonados por semanas
- Projeto complexo sem ADRs
- Documentação que só repete o código em vez de explicar intenção

## Verificação

Depois de documentar:

- [ ] Existem ADRs para decisões arquiteturais relevantes
- [ ] O README cobre quick start, comandos e visão de arquitetura
- [ ] APIs públicas têm documentação de parâmetros, retorno e erros
- [ ] Gotchas importantes estão documentados perto do código afetado
- [ ] Não restou código comentado sem necessidade
- [ ] Arquivos de regras estão atualizados com a realidade do projeto
