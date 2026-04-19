---
name: shipping-and-launch
description: Prepara lançamentos em produção. Use ao se preparar para implantar em produção. Use quando precisar de uma checklist pré-lançamento, configurar monitoramento, planejar rollout gradual ou definir uma estratégia de rollback.
---

# Entrega e Lançamento

## Visão Geral

Lance com segurança. O objetivo não é apenas fazer deploy, é fazer deploy com monitoração pronta, plano de rollback definido e critérios claros de sucesso. Em plataformas backend com Go, AWS e Terraform, todo lançamento deve ser reversível, observável e incremental.

## Quando Usar

- Ao colocar um recurso em produção pela primeira vez
- Ao liberar uma mudança significativa para clientes ou sistemas consumidores
- Ao migrar dados, filas, regras IAM ou infraestrutura
- Ao abrir beta, canario ou rollout gradual
- Em qualquer deploy que carregue risco, ou seja, todos

## Checklist Pré-Lançamento

### Qualidade de Código

- [ ] Todos os testes relevantes passam: unitários, integração e ponta a ponta quando aplicável
- [ ] A build em Go conclui sem erros
- [ ] Lint e formatação passam
- [ ] O código foi revisado e aprovado
- [ ] Não há comentários TODO que deveriam bloquear o release
- [ ] Tratamento de erro cobre falhas previsíveis

### Segurança

- [ ] Não há segredos no código ou no controle de versão
- [ ] `govulncheck ./...` e scanners equivalentes não mostram risco crítico sem tratamento
- [ ] Toda entrada externa e validada nas fronteiras
- [ ] Autenticação e autorização estão verificadas
- [ ] Politicas IAM seguem menor privilegio
- [ ] Throttling, rate limiting e WAF estao configurados quando aplicavel

### Performance e Confiabilidade

- [ ] p95, p99 e taxa de erro estão dentro do budget
- [ ] Não há N+1 queries, scans desnecessários ou gargalos conhecidos nos caminhos críticos
- [ ] Cold start, memória e concorrência de Lambda estão dentro do esperado
- [ ] Retries, DLQ, timeout e idempotência foram revisados
- [ ] Alarmes e dashboards cobrem erro, latência, throttling e backlog

### Infraestrutura

- [ ] `terraform fmt -check`, `terraform validate` e `terraform plan` foram executados
- [ ] Variáveis, workspaces e backends estão corretos para produção
- [ ] Migrações de dados ou infraestrutura estão prontas para aplicar e para reverter
- [ ] Rotas, DNS, certificados, filas e permissions boundaries estao corretos
- [ ] Health check existe e responde

### Observabilidade e Operação

- [ ] Logging estruturado está habilitado
- [ ] Traces e métricas estão chegando ao destino esperado
- [ ] Alarmes de alta severidade estão configurados e roteando para o canal certo
- [ ] Runbook e plano de resposta a incidente estão atualizados
- [ ] O time sabe quem acompanha o deploy e os primeiros minutos após o release

### Documentação

- [ ] README, ADRs e documentação operacional estão atualizados
- [ ] Contratos de API foram atualizados se houve mudança de comportamento
- [ ] Changelog ou notas de release foram preparados
- [ ] O plano de rollback está documentado

## Estratégia de Feature Flag e Release Controlado

Desacople deploy de release. Em AWS, isso pode ser feito com AppConfig, alias de Lambda com roteamento de peso, parâmetros do SSM ou configuração em banco.

```go
type LaunchConfig struct {
	EnableOrderCancellationV2 bool
}

func (c LaunchConfig) OrderCancellationV2Enabled() bool {
	return c.EnableOrderCancellationV2
}
```

**Ciclo de vida da flag:**

```
1. DEPLOY com flag desligada
2. HABILITAR para time interno
3. ROLLOUT gradual: 5% -> 25% -> 50% -> 100%
4. MONITORAR em cada etapa
5. REMOVER a flag e o código morto após estabilização
```

**Regras:**

- Toda flag tem dono e data alvo para remoção
- Limpe flags antigas rapidamente
- Não aninhe flags sem necessidade real
- Teste ambos os estados, ligado e desligado

## Rollout em Etapas

### Sequência Recomendada

```
1. DEPLOY em staging
   -> Rodar testes e smoke test do fluxo crítico

2. DEPLOY em produção com flag OFF ou tráfego em 0%
   -> Validar health check e dashboards

3. HABILITAR para time interno
   -> Uso real por pessoas próximas ao contexto

4. CANARIO em 5%
   -> Monitorar erro, latência, throttling e métricas de negócio

5. AUMENTO gradual para 25%, 50% e 100%
   -> Avançar apenas se os limites forem respeitados

6. ESTABILIZAÇÃO
   -> Monitorar por período definido e remover a flag depois
```

### Limiares para Avançar, Segurar ou Reverter

| Métrica | Avançar | Segurar e investigar | Reverter |
|---|---|---|---|
| Taxa de erro | dentro de 10% do baseline | 10% a 100% acima do baseline | > 2x o baseline |
| Latência p95 | dentro de 20% do baseline | 20% a 50% acima | > 50% acima |
| Throttling | zero ou residual | intermitente | recorrente |
| Backlog / idade da fila | estável | aumentando lentamente | fora do SLO |
| Métricas de negócio | neutras ou positivas | leve degradação | degradação clara |

### Quando Reverter Imediatamente

Reverta sem hesitar se:

- A taxa de erro ultrapassar 2x o baseline
- A latência p95 subir mais de 50%
- Houver problema de integridade de dados
- Surgir vulnerabilidade de segurança relevante
- Alarmes críticos dispararem de forma consistente
- Usuários ou sistemas consumidores reportarem erro sistêmico

## Monitoração e Observabilidade

### O Que Monitorar

```
Métricas de aplicação:
├── Erro total e por endpoint / handler
├── Latência p50, p95 e p99
├── Volume de requisições e throughput
├── Saturação, backlog e retries
└── Métricas de negócio relevantes

Métricas de infraestrutura:
├── Concurrency, throttles e duração de Lambda
├── CPU, memória e conexões de banco
├── Uso de filas, DLQ e idade das mensagens
├── Erros de API Gateway, ALB ou EventBridge
└── Custos ou consumo anormal por recurso crítico
```

### Alarmes e Proteção com Terraform

```hcl
resource "aws_cloudwatch_metric_alarm" "orders_api_errors" {
  alarm_name          = "orders-api-errors-high"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    FunctionName = aws_lambda_function.orders.function_name
  }
}
```

### Verificação Pós-Lançamento

Na primeira hora depois do deploy:

```
1. Confirmar health check retornando sucesso
2. Verificar dashboards de erro, latência e throttling
3. Rodar smoke test do fluxo crítico
4. Confirmar logs e traces chegando corretamente
5. Verificar backlog de filas e DLQ
6. Confirmar que o rollback está pronto para ser executado
```

## Estratégia de Rollback

Todo deploy precisa de rollback definido antes de acontecer.

```markdown
## Plano de Rollback para [Feature/Release]

### Gatilhos
- Taxa de erro > 2x baseline
- Latência p95 > [X] ms
- Problema de integridade ou segurança

### Passos
1. Desligar a feature flag ou zerar o peso do alias canario
2. Se necessário, voltar à versão anterior da Lambda / artefato
3. Reaplicar a configuração Terraform anterior, se a mudança estiver na infraestrutura
4. Validar health check e dashboards após rollback
5. Comunicar o incidente ao time

### Considerações de Dados
- Migração [X] possui plano de reversão? [sim/não]
- Mensagens em fila precisam ser drenadas ou preservadas? [detalhar]

### Tempo Esperado de Reversão
- Flag ou alias: < 1 minuto
- Redeploy de versão anterior: < 5 minutos
- Infraestrutura / dados: depende do plano documentado
```

## Veja Também

- Para verificações de segurança antes do release, veja `references/security-checklist.md`
- Para budgets e medições, veja `references/performance-checklist.md`

## Justificativas Comuns

| Justificativa | Realidade |
|---|---|
| "Em staging funcionou, em produção vai funcionar" | Produção tem dados, tráfego e integrações diferentes. |
| "Não precisamos de flag para isso" | Mesmo mudança simples se beneficia de kill switch. |
| "Monitoração é overhead" | Sem monitoração, o usuário vira seu sistema de alerta. |
| "A gente monta o rollback se der problema" | Rollback improvisado e lento justamente quando você mais precisa de velocidade. |
| "Deploy grande é mais eficiente" | Blast radius grande torna investigação e reversão muito piores. |

## Sinais de Alerta

- Deploy sem plano de rollback
- Ausência de monitoração ou alertas em produção
- Release big bang sem etapas ou canario
- Flags sem dono ou sem previsão de limpeza
- Ninguém designado para acompanhar o deploy
- Configuração de produção feita de memória e não em código
- Lançar mudança arriscada no fim da semana sem cobertura operacional

## Verificação

Antes do deploy:

- [ ] Checklist pré-lançamento concluído
- [ ] Mecanismo de rollout gradual ou kill switch definido
- [ ] Plano de rollback documentado
- [ ] Dashboards e alarmes prontos
- [ ] Responsáveis pelo acompanhamento do release definidos

Depois do deploy:

- [ ] Health check está verde
- [ ] Taxa de erro e latência estão normais
- [ ] Logs, métricas e traces estão chegando
- [ ] Fluxo crítico foi validado
- [ ] Rollback continua disponivel e testado ou revisado

