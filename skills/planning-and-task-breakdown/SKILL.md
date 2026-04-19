---
name: planning-and-task-breakdown
description: Divide o trabalho em tarefas ordenadas. Use quando você tiver uma especificação ou requisitos claros e precisar dividir o trabalho em tarefas implementáveis. Use quando uma tarefa parecer grande demais para começar, quando precisar estimar o escopo ou quando o trabalho paralelo for possível.
---

# Planejamento e Detalhamento de Tarefas

## Visão Geral

---
name: planning-and-task-breakdown
description: Divide o trabalho em tarefas ordenadas. Use quando você tiver uma especificação ou requisitos claros e precisar dividir o trabalho em tarefas implementáveis. Use quando uma tarefa parecer grande demais para começar, quando precisar estimar o escopo ou quando o trabalho paralelo for possível.
---

# Planejamento e Detalhamento de Tarefas

## Visão Geral

Decomponha o trabalho em tarefas pequenas, ordenadas e verificáveis, com critérios de aceitação explícitos. Um bom detalhamento de tarefas é a diferença entre um agente que conclui o trabalho com previsibilidade e outro que gera uma sequência caótica de mudanças. Cada tarefa deve ser pequena o suficiente para ser implementada, testada e verificada em uma única sessão focada.

## Quando Usar

- Você tem uma especificação e precisa dividi-la em unidades implementáveis
- A tarefa parece grande ou vaga demais para ser iniciada diretamente
- O trabalho pode ser paralelizado entre agentes, pessoas ou sessões
- É preciso comunicar escopo, ordem e riscos para um humano
- A ordem de implementação não está óbvia

**Quando NÃO usar:** alterações pequenas, de escopo óbvio e isoladas em um único arquivo ou módulo.

## O Processo de Planejamento

### Etapa 1: Entrar em Modo de Planejamento

Antes de escrever qualquer código, opere em modo somente leitura:

- Leia a especificação e as partes relevantes do código-fonte
- Identifique padrões e convenções existentes
- Mapeie dependências entre código Go, infraestrutura AWS e módulos Terraform
- Registre riscos, restrições e desconhecidos

**Não escreva código durante o planejamento.** A saída desta fase é um plano, não a implementação.

### Etapa 2: Identificar o Grafo de Dependências

Mapeie o que depende do que:

```
Terraform / IAM / eventos / storage
    │
    ├── Configuração do serviço e clientes AWS
    │       │
    │       ├── Modelos de domínio e contratos
    │       │       │
    │       │       ├── Repositórios / gateways
    │       │       │       │
    │       │       │       └── Casos de uso
    │       │       │               │
    │       │       │               └── Handlers HTTP / consumidores de fila
    │       │       │
    │       │       └── Regras de validação
    │       │
    │       └── Observabilidade, alarmes e dashboards
    │
    └── Seeds, jobs e migrações de dados
```

A ordem de implementação segue o grafo de dependências: construa a base primeiro, mas entregue valor em fatias verticais sempre que possível.

### Etapa 3: Fatiamento Vertical

Em vez de construir toda a infraestrutura, depois toda a camada de dados e só no final os handlers, monte caminhos completos de funcionalidade.

**Ruim, fatiamento horizontal:**

```
Tarefa 1: Criar todos os módulos Terraform
Tarefa 2: Criar todos os repositórios e clientes AWS
Tarefa 3: Criar todos os handlers e rotas
Tarefa 4: Conectar tudo
```

**Bom, fatiamento vertical:**

```
Tarefa 1: Cliente cria pedido
    -> rota POST /orders + Lambda Go + persistência + permissão IAM + logs

Tarefa 2: Cliente consulta pedido
    -> rota GET /orders/{id} + repositório + serialização + alarmes básicos

Tarefa 3: Sistema cancela pedido
    -> regra de negócio + atualização persistente + evento EventBridge + auditoria

Tarefa 4: Operação lista pedidos com filtros
    -> query paginada + observabilidade + contrato documentado
```

Cada fatia vertical entrega comportamento funcional e testável.

### Etapa 4: Escrever Tarefas Claras

Cada tarefa deve seguir uma estrutura consistente:

```markdown
## Tarefa [N]: [Título curto e descritivo]

**Descrição:** Um parágrafo explicando o que esta tarefa entrega.

**Critérios de aceitação:**
- [ ] [Condição específica e testável]
- [ ] [Condição específica e testável]

**Verificação:**
- [ ] Testes: `go test ./... -run TestNomeDoCaso`
- [ ] Build: `go build ./cmd/...`
- [ ] Infra: `terraform validate` e `terraform plan`
- [ ] Verificação manual: [descreva o fluxo ou métrica]

**Dependências:** [números das tarefas anteriores ou "Nenhuma"]

**Arquivos provavelmente alterados:**
- `cmd/api/main.go`
- `internal/usecase/create_order.go`
- `terraform/orders-api/main.tf`

**Escopo estimado:** [XS | S | M | L]
```

### Etapa 5: Ordenar e Inserir Pontos de Verificação

Organize as tarefas para que:

1. As dependências sejam satisfeitas na ordem correta
2. Cada tarefa deixe o sistema em um estado funcional
3. Exista um ponto de verificação a cada 2 ou 3 tarefas
4. O risco técnico mais alto apareça cedo

Adicione checkpoints explícitos:

```markdown
## Ponto de Verificação: após as Tarefas 1-3
- [ ] `go test ./...` passa
- [ ] `go build ./cmd/...` passa
- [ ] `terraform validate` e `terraform plan` passam
- [ ] O fluxo principal da API funciona ponta a ponta
- [ ] Um humano revisou a direção antes da próxima fase
```

## Diretrizes de Tamanho

| Tamanho | Arquivos | Escopo | Exemplo |
|---|---|---|---|
| **XS** | 1 | Função única ou ajuste pequeno de configuração | Adicionar validação de campo |
| **S** | 1-2 | Um handler, use case ou módulo pequeno | Novo endpoint simples |
| **M** | 3-5 | Uma fatia funcional completa | Fluxo de criação de pedido |
| **L** | 5-8 | Funcionalidade com vários componentes | Processamento assíncrono com retries e alarmes |
| **XL** | 8+ | Grande demais, divida | — |

Se uma tarefa for L ou maior, ela provavelmente precisa ser quebrada. Agentes operam melhor em tarefas XS, S e M.

**Quando dividir uma tarefa:**

- Ela exigiria mais de uma sessão focada de implementação
- Não dá para descrever os critérios de aceitação em até 3 itens claros
- Ela mexe em dois ou mais subsistemas independentes
- O título exige um "e" para caber tudo, sinal de que são duas tarefas

## Modelo de Documento de Planejamento

```markdown
# Plano de Implementação: [Nome do Recurso]

## Visão Geral
[Resumo em um parágrafo do que será entregue]

## Decisões de Arquitetura
- [Decisão principal e justificativa]
- [Decisão principal e justificativa]

## Lista de Tarefas

### Fase 1: Fundações
- [ ] Tarefa 1: ...
- [ ] Tarefa 2: ...

### Ponto de Verificação: Fundações
- [ ] Testes, build e validação de Terraform passam

### Fase 2: Fluxos Principais
- [ ] Tarefa 3: ...
- [ ] Tarefa 4: ...

### Ponto de Verificação: Fluxos Principais
- [ ] Fluxo ponta a ponta validado

### Fase 3: Robustez e Operação
- [ ] Tarefa 5: ...
- [ ] Tarefa 6: ...

### Ponto de Verificação: Concluído
- [ ] Todos os critérios de aceitação atendidos
- [ ] Pronto para revisão

## Riscos e Mitigações
| Risco | Impacto | Mitigação |
|---|---|---|
| [Risco] | [Alto/Médio/Baixo] | [Estratégia] |

## Questões em Aberto
- [Questão que precisa de resposta humana]
```

## Oportunidades de Paralelização

Quando houver vários agentes ou pessoas disponíveis:

- **Seguro paralelizar:** testes para código já estabilizado, documentação, mocks de contrato, dashboards e runbooks
- **Deve ser sequencial:** migrações, contratos compartilhados ainda instáveis, IAM, mudanças em estado compartilhado
- **Exige coordenação:** fluxos que dependem do mesmo contrato HTTP, mesma fila ou mesmo módulo Terraform

## Justificativas Comuns

| Justificativa | Realidade |
|---|---|
| "Vou descobrir fazendo" | Isso produz retrabalho e lacunas. Dez minutos de planejamento economizam horas. |
| "As tarefas são óbvias" | Se são óbvias, documentá-las será rápido e ainda assim revelará dependências esquecidas. |
| "Planejar é burocracia" | Planejar é reduzir risco. Implementar sem plano é digitar no escuro. |
| "Consigo guardar tudo na cabeça" | O contexto é finito. Plano escrito sobrevive à troca de sessão e à revisão. |

## Sinais de Alerta

- Começar implementação sem lista de tarefas escrita
- Tarefas com nome genérico como "implementar recurso"
- Ausência de etapas de verificação no plano
- Tarefas XL dominando o documento
- Falta de checkpoints entre fases
- Ordem de dependência ignorada

## Verificação

Antes de iniciar a implementação, confirme:

- [ ] Cada tarefa tem critérios de aceitação claros
- [ ] Cada tarefa tem uma etapa de verificação
- [ ] As dependências entre tarefas estão identificadas e ordenadas
- [ ] Nenhuma tarefa toca mais do que o necessário
- [ ] Existem checkpoints entre as fases principais
- [ ] O plano foi revisado e aprovado por um humano

## Quando Usar

- Você tem uma especificação e precisa dividi-la em unidades implementaveis
- A tarefa parece grande ou vaga demais para ser iniciada diretamente
- O trabalho pode ser paralelizado entre agentes, pessoas ou sessoes
- E preciso comunicar escopo, ordem e riscos para um humano
- A ordem de implementação não esta obvia

**Quando NÃO usar:** alterações pequenas, de escopo óbvio e isoladas em um único arquivo ou módulo.

## O Processo de Planejamento

### Etapa 1: Entrar em Modo de Planejamento

Antes de escrever qualquer código, opere em modo somente leitura:

- Leia a especificação e as partes relevantes do código-fonte
- Identifique padroes e convencoes existentes
- Mapeie dependencias entre código Go, infraestrutura AWS e modulos Terraform
- Registre riscos, restrições e desconhecidos

**Não escreva código durante o planejamento.** A saida desta fase e um plano, não a implementação.

### Etapa 2: Identificar o Grafo de Dependencias

Mapeie o que depende do que:

```
Terraform / IAM / eventos / storage
    │
    ├── Configuracao do servico e clientes AWS
    │       │
    │       ├── Modelos de dominio e contratos
    │       │       │
    │       │       ├── Repositorios / gateways
    │       │       │       │
    │       │       │       └── Casos de uso
    │       │       │               │
    │       │       │               └── Handlers HTTP / consumidores de fila
    │       │       │
    │       │       └── Regras de validacao
    │       │
    │       └── Observabilidade, alarmes e dashboards
    │
    └── Seeds, jobs e migracoes de dados
```

A ordem de implementação segue o grafo de dependencias: construa a base primeiro, mas entregue valor em fatias verticais sempre que possivel.

### Etapa 3: Fatiamento Vertical

Em vez de construir toda a infraestrutura, depois toda a camada de dados e so no final os handlers, monte caminhos completos de funcionalidade.

**Ruim, fatiamento horizontal:**

```
Tarefa 1: Criar todos os modulos Terraform
Tarefa 2: Criar todos os repositorios e clientes AWS
Tarefa 3: Criar todos os handlers e rotas
Tarefa 4: Conectar tudo
```

**Bom, fatiamento vertical:**

```
Tarefa 1: Cliente cria pedido
    -> rota POST /orders + Lambda Go + persistencia + permissao IAM + logs

Tarefa 2: Cliente consulta pedido
    -> rota GET /orders/{id} + repositorio + serializacao + alarmes basicos

Tarefa 3: Sistema cancela pedido
    -> regra de negocio + atualizacao persistente + evento EventBridge + auditoria

Tarefa 4: Operação lista pedidos com filtros
    -> query paginada + observabilidade + contrato documentado
```

Cada fatia vertical entrega comportamento funcional e testavel.

### Etapa 4: Escrever Tarefas Claras

Cada tarefa deve seguir uma estrutura consistente:

```markdown
## Tarefa [N]: [Titulo curto e descritivo]

**Descricao:** Um paragrafo explicando o que esta tarefa entrega.

**Critérios de aceitacao:**
- [ ] [Condicao especifica e testavel]
- [ ] [Condicao especifica e testavel]

**Verificação:**
- [ ] Testes: `go test ./... -run TestNomeDoCaso`
- [ ] Build: `go build ./cmd/...`
- [ ] Infra: `terraform validate` e `terraform plan`
- [ ] Verificação manual: [descreva o fluxo ou metrica]

**Dependencias:** [numeros das tarefas anteriores ou "Nenhuma"]

**Arquivos provavelmente alterados:**
- `cmd/api/main.go`
- `internal/usecase/create_order.go`
- `terraform/orders-api/main.tf`

**Escopo estimado:** [XS | S | M | L]
```

### Etapa 5: Ordenar e Inserir Pontos de Verificação

Organize as tarefas para que:

1. As dependencias sejam satisfeitas na ordem correta
2. Cada tarefa deixe o sistema em um estado funcional
3. Exista um ponto de verificação a cada 2 ou 3 tarefas
4. O risco tecnico mais alto apareca cedo

Adicione checkpoints explicitos:

```markdown
## Ponto de Verificação: apos as Tarefas 1-3
- [ ] `go test ./...` passa
- [ ] `go build ./cmd/...` passa
- [ ] `terraform validate` e `terraform plan` passam
- [ ] O fluxo principal da API funciona ponta a ponta
- [ ] Um humano revisou a direção antes da próxima fase
```

## Diretrizes de Tamanho

| Tamanho | Arquivos | Escopo | Exemplo |
|---|---|---|---|
| **XS** | 1 | Funcao unica ou ajuste pequeno de configuracao | Adicionar validacao de campo |
| **S** | 1-2 | Um handler, use case ou modulo pequeno | Novo endpoint simples |
| **M** | 3-5 | Uma fatia funcional completa | Fluxo de criacao de pedido |
| **L** | 5-8 | Funcionalidade com varios componentes | Processamento assincrono com retries e alarmes |
| **XL** | 8+ | Grande demais, divida | — |

Se uma tarefa for L ou maior, ela provavelmente precisa ser quebrada. Agentes operam melhor em tarefas XS, S e M.

**Quando dividir uma tarefa:**

- Ela exigiria mais de uma sessao focada de implementação
- Não da para descrever os critérios de aceitacao em ate 3 itens claros
- Ela mexe em dois ou mais subsistemas independentes
- O titulo exige um "e" para caber tudo, sinal de que sao duas tarefas

## Modelo de Documento de Planejamento

```markdown
# Plano de Implementação: [Nome do Recurso]

## Visão Geral
[Resumo em um paragrafo do que sera entregue]

## Decisoes de Arquitetura
- [Decisao principal e justificativa]
- [Decisao principal e justificativa]

## Lista de Tarefas

### Fase 1: Fundacoes
- [ ] Tarefa 1: ...
- [ ] Tarefa 2: ...

### Ponto de Verificação: Fundacoes
- [ ] Testes, build e validacao de Terraform passam

### Fase 2: Fluxos Principais
- [ ] Tarefa 3: ...
- [ ] Tarefa 4: ...

### Ponto de Verificação: Fluxos Principais
- [ ] Fluxo ponta a ponta validado

### Fase 3: Robustez e Operação
- [ ] Tarefa 5: ...
- [ ] Tarefa 6: ...

### Ponto de Verificação: Concluido
- [ ] Todos os critérios de aceitacao atendidos
- [ ] Pronto para revisão

## Riscos e Mitigacoes
| Risco | Impacto | Mitigacao |
|---|---|---|
| [Risco] | [Alto/Medio/Baixo] | [Estrategia] |

## Questoes em Aberto
- [Questao que precisa de resposta humana]
```

## Oportunidades de Paralelizacao

Quando houver varios agentes ou pessoas disponiveis:

- **Seguro paralelizar:** testes para código ja estabilizado, documentação, mocks de contrato, dashboards e runbooks
- **Deve ser sequencial:** migracoes, contratos compartilhados ainda instaveis, IAM, mudanças em estado compartilhado
- **Exige coordenacao:** fluxos que dependem do mesmo contrato HTTP, mesma fila ou mesmo modulo Terraform

## Justificativas Comuns

| Justificativa | Realidade |
|---|---|
| "Vou descobrir fazendo" | Isso produz retrabalho e lacunas. Dez minutos de planejamento economizam horas. |
| "As tarefas sao obvias" | Se sao obvias, documenta-las sera rapido e ainda assim revelara dependencias esquecidas. |
| "Planejar e burocracia" | Planejar e reduzir risco. Implementar sem plano e digitar no escuro. |
| "Consigo guardar tudo na cabeca" | O contexto e finito. Plano escrito sobrevive a troca de sessao e a revisão. |

## Sinais de Alerta

- Comecar implementação sem lista de tarefas escrita
- Tarefas com nome generico como "implementar recurso"
- Ausencia de etapas de verificação no plano
- Tarefas XL dominando o documento
- Falta de checkpoints entre fases
- Ordem de dependência ignorada

## Verificação

Antes de iniciar a implementação, confirme:

- [ ] Cada tarefa tem critérios de aceitacao claros
- [ ] Cada tarefa tem uma etapa de verificação
- [ ] As dependencias entre tarefas estao identificadas e ordenadas
- [ ] Nenhuma tarefa toca mais do que o necessário
- [ ] Existem checkpoints entre as fases principais
- [ ] O plano foi revisado e aprovado por um humano--- 

