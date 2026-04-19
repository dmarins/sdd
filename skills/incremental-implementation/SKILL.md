---
name: incremental-implementation
description: Entrega mudanças de forma incremental. Use ao implementar qualquer funcionalidade ou mudança que toque mais de um arquivo. Use quando você estiver prestes a escrever uma grande quantidade de código de uma só vez ou quando a tarefa parecer grande demais para entrar em uma única etapa.
---

# Implementação Incremental

## Visão Geral

Construa em fatias verticais finas: implemente uma parte, teste, verifique e depois expanda. Evite tentar entregar um recurso inteiro em uma única passada. Cada incremento deve deixar o sistema em um estado funcional e testável. Essa é a disciplina de execução que torna recursos grandes controláveis.

## Quando Usar

- Ao implementar qualquer mudança que toque vários arquivos
- Ao construir um novo recurso a partir de um plano de tarefas
- Ao refatorar código existente
- Sempre que a tentação for escrever mais de ~100 linhas antes de validar algo

**Quando NÃO usar:** alterações pequenas, isoladas em um único arquivo, cujo escopo já é mínimo.

## O Ciclo de Incremento

```
┌──────────────────────────────────────┐
│                                      │
│   Implementar -> Testar -> Verificar │
│       ^                       │      │
│       └──── Commitar <────────┘      │
│               │                      │
│               ▼                      │
│           Próxima fatia              │
│                                      │
└──────────────────────────────────────┘
```

Para cada fatia:

1. **Implemente** a menor parte completa de funcionalidade
2. **Teste**: rode os testes relevantes ou escreva um teste se ainda não existir
3. **Verifique**: confirme que a fatia funciona como esperado
4. **Commite**: salve o progresso com uma mensagem descritiva
5. **Passe para a próxima fatia**: avance sobre uma base estável, sem recomeçar

## Estrategias de Fatiamento

### Fatias Verticais

Construa um caminho funcional completo pela stack:

```
Fatia 1: Criar pedido
	-> API Gateway + Lambda Go + persistência + teste de contrato

Fatia 2: Consultar pedido
	-> rota GET + repositório + serialização + testes

Fatia 3: Cancelar pedido
	-> regra de negócio + persistência + auditoria + handler

Fatia 4: Publicar evento de pedido
	-> EventBridge + permissão IAM + observabilidade
```

Cada fatia entrega funcionalidade completa de ponta a ponta.

### Fatiamento por Contrato

Quando times ou agentes precisam trabalhar em paralelo:

```
Fatia 0: Definir contrato da API
    -> OpenAPI, structs Go, payloads de erro e exemplos

Fatia 1a: Implementar backend contra o contrato
	-> handlers, testes HTTP e validação

Fatia 1b: Implementar consumidor contra mocks do contrato
	-> fixtures, contratos versionados e testes de integração

Fatia 2: Integrar e validar ponta a ponta
```

### Fatiamento pelo Risco

Ataque primeiro a parte mais incerta:

```
Fatia 1: Provar que a Lambda consegue assumir a role correta e publicar no EventBridge
Fatia 2: Construir o fluxo de negócio sobre essa integração validada
Fatia 3: Adicionar retries, DLQ e observabilidade
```

Se a primeira fatia falhar, você descobre isso antes de investir no restante.

## Regras de Implementação

### Regra 0: Simplicidade Primeiro

Antes de escrever código, pergunte: "qual é a coisa mais simples que pode funcionar?"

Depois de escrever, revise com estas perguntas:

- Isso pode ser feito com menos moving parts?
- Essas abstrações realmente se pagam?
- Um engenheiro sênior perguntaria "por que você não fez do jeito direto?"
- Estou construindo para uma necessidade real ou para um futuro hipotético?

```
CHECAGEM DE SIMPLICIDADE:
✗ Pipeline genérico de eventos para um único webhook de notificação
✓ Uma chamada direta para o publicador do EventBridge

✗ Módulo Terraform hiper-genérico para um único serviço simples
✓ Um módulo focado para a Lambda, IAM e alarmes desse serviço

✗ Camada de configuração abstrata demais para três flags
✓ Struct de configuração clara carregada de AppConfig, SSM ou env vars
```

Três linhas repetidas ainda podem ser melhores que uma abstração prematura.

### Regra 0.5: Disciplina de Escopo

Toque apenas o que a tarefa exige.

Não faça:

- "Limpeza" em código adjacente sem relação com a tarefa
- Refatoração de imports ou nomenclatura em arquivos que você não está mudando
- Remoção de comentários que você não entendeu completamente
- Inclusão de recursos não pedidos porque "parecem úteis"
- Modernização de sintaxe em arquivos apenas lidos

Se notar algo fora de escopo, registre, mas não conserte no mesmo incremento.

### Regra 1: Uma Coisa por Vez

Cada incremento muda uma coisa lógica. Não misture concerns.

**Ruim:** um único commit que altera Terraform, muda contrato de API, cria handler novo e refatora um pacote antigo.

**Bom:** commits separados e independentes para infraestrutura, contrato e implementação.

### Regra 2: Mantenha o Projeto Compilavel

Depois de cada incremento, o projeto precisa compilar e os testes existentes precisam passar. Não deixe a base quebrada entre fatias.

### Regra 3: Use Kill Switch ou Feature Flag Quando Necessário

Se o recurso ainda não está pronto para todo mundo, mas o incremento precisa ser mergeado:

```go
type RuntimeConfig struct {
	EnableOrderRetry bool
}

func shouldRetryOrder(cfg RuntimeConfig) bool {
	return cfg.EnableOrderRetry
}
```

Em AWS isso também pode significar rollout com alias da Lambda, pesos de tráfego ou AppConfig. O princípio é o mesmo: deploy e release são coisas separadas.

### Regra 4: Defaults Seguros

Código novo deve assumir comportamento seguro e conservador por padrão:

```go
type CreateOrderOptions struct {
	PublishEvent bool
}

func CreateOrder(ctx context.Context, input CreateOrderInput, opts *CreateOrderOptions) error {
	options := CreateOrderOptions{}
	if opts != nil {
		options = *opts
	}

	if options.PublishEvent {
		// publica somente quando explicitamente habilitado
	}

	return nil
}
```

### Regra 5: Facil de Reverter

Cada incremento deve ser revertível de forma independente:

- Mudanças aditivas são preferíveis a substituições grandes
- Alterações em código existente devem ser pequenas e focadas
- Migrações devem ter plano claro de rollback
- Evite deletar e substituir a mesma coisa no mesmo incremento se puder separar

## Trabalhando com Agentes

Ao orientar um agente para implementar incrementalmente:

```
"Vamos implementar a Tarefa 3 do plano.

Comece apenas pela alteracao no contrato HTTP, pelo handler Go e pelo teste de integração.
Não mexa no Terraform ainda; isso fica para o próximo incremento.

Depois de implementar, rode `go test ./...`, `go build ./cmd/...`
e `golangci-lint run`. Se a tarefa incluir infraestrutura,
rode tambem `terraform fmt -check`, `terraform validate`
e o `terraform plan` do modulo afetado."
```

Seja explícito sobre o que está em escopo e o que está fora de escopo em cada incremento.

## Checklist do Incremento

Depois de cada incremento, confirme:

- [ ] A mudança faz uma coisa logica e a faz por completo
- [ ] Os testes existentes passam: `go test ./...`
- [ ] A compilação passa: `go build ./cmd/...`
- [ ] O lint e a formatação passam: `golangci-lint run` e `gofmt -w` quando aplicável
- [ ] Se houver Terraform, `terraform fmt -check`, `terraform validate` e `terraform plan` foram executados
- [ ] A nova funcionalidade funciona como esperado
- [ ] O incremento está pronto para ser commitado com uma mensagem descritiva

## Justificativas Comuns

| Justificativa | Realidade |
|---|---|
| "Testo tudo no final" | Erros compostos contaminam as próximas fatias. Teste cada incremento. |
| "É mais rápido fazer tudo de uma vez" | Parece mais rápido até quebrar e você não saber qual de 500 linhas causou o problema. |
| "Essas mudanças são pequenas demais para commits separados" | Commits pequenos tornam rollback e revisão muito mais simples. |
| "Adiciono a flag depois" | Recurso incompleto não deve ficar visivel sem kill switch. |
| "Essa refatoracao cabe junto" | Refatoracao misturada com feature dificulta revisão, teste e rollback. |

## Sinais de Alerta

- Mais de 100 linhas escritas sem rodar nenhuma verificação
- Varias mudanças não relacionadas no mesmo incremento
- Expansao de escopo do tipo "ja que estou aqui"
- Pular a etapa de testar e verificar para "ganhar tempo"
- Build ou testes quebrados entre incrementos
- Grande volume de mudanças não commitadas acumulando
- Abstrações surgindo antes do terceiro caso real de uso
- Alterar arquivos fora do escopo "aproveitando a visita"

## Verificação

Depois de concluir todos os incrementos de uma tarefa:

- [ ] Cada incremento foi testado individualmente
- [ ] A suite completa relevante passa
- [ ] A build está limpa
- [ ] O recurso funciona de ponta a ponta como especificado
- [ ] Não restaram mudanças quebradas entre fatias

