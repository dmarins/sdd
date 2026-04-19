---
name: deprecation-and-migration
description: Gerencia descontinuação e migração. Use ao remover sistemas, APIs ou funcionalidades antigas. Use ao migrar usuários de uma implementação para outra. Use ao decidir se deve manter ou aposentar código existente.
---

# Depreciação e Migração

## Visão Geral

Código é passivo, não ativo. Cada linha traz custo contínuo: correção de bugs, atualização de dependências, patches de segurança, documentação e carga cognitiva. Depreciação é a disciplina de remover o que não compensa mais manter. Migração é o processo de mover consumidores com segurança do velho para o novo.

Times costumam ser bons em construir e ruins em remover. Esta skill existe para fechar essa lacuna.

## Quando Usar

- Ao substituir um sistema, API, pacote ou módulo Terraform antigo
- Ao descontinuar uma feature que perdeu valor
- Ao consolidar implementações duplicadas
- Ao remover código morto que ainda tem consumidores
- Ao planejar o ciclo de vida de um sistema novo
- Ao decidir entre manter legado ou investir em migração

## Princípios Centrais

### Código É um Passivo

Cada linha de código cobra manutenção contínua: testes, observabilidade, segurança, compatibilidade e conhecimento operacional. O valor está na funcionalidade entregue, não no volume de código. Se a mesma funcionalidade pode existir com menos código, menor complexidade ou limites mais limpos, o código antigo deve sair.

### A Lei de Hyrum Torna Remoção Difícil

Com usuários suficientes, todo comportamento observável vira dependência, inclusive bugs, ordem de resposta, mensagens e efeitos colaterais. É por isso que depreciação exige migração ativa, não só anúncio. Consumidores quase nunca “trocam sozinhos” quando dependem de comportamento não documentado.

### Planejamento de Depreciação Começa no Design

Ao construir algo novo, pergunte: “como removo isso em três anos?”. Sistemas com contratos claros, flags, métricas e pouca exposição de implementação são muito mais fáceis de aposentar depois.

## A Decisão de Deprecar

Antes de deprecar qualquer coisa, responda:

```text
1. Esse sistema ainda entrega valor único?
	-> Se sim, mantenha. Se não, prossiga.

2. Quantos consumidores dependem dele?
	-> Quantifique escopo e risco da migração.

3. Existe substituto viável?
	-> Se não existe, construa antes. Não depreque sem alternativa.

4. Qual o custo de migração por consumidor?
   -> Se for automatizavel, automatize. Se for manual e alto, compare com o custo de manter.

5. Qual o custo de NÃO deprecar?
	-> Risco de segurança, tempo de engenharia, custo operacional, complexidade.
```

## Depreciação Compulsória vs Consultiva

| Tipo | Quando Usar | Mecanismo |
|---|---|---|
| **Consultiva** | Migração é opcional e o sistema antigo ainda é estável | Avisos, docs, métricas e incentivo gradual |
| **Compulsória** | O sistema antigo é inseguro, bloqueia evolução ou custa caro demais | Prazo firme, tooling de migração e suporte ativo |

**Prefira consultiva por padrão.** A compulsória só se justifica quando custo ou risco da manutenção realmente exigem forçar migração.

## O Processo de Migração

### Passo 1: Construir o Substituto

Não depreque sem alternativa funcional. O substituto precisa:

- Cobrir todos os casos críticos do sistema antigo
- Ter documentação e guia de migração
- Estar validado em ambiente real ou equivalente confiável

### Passo 2: Anunciar e Documentar

```markdown
## Aviso de Depreciação: Legacy Task API

**Status:** Depreciada em 2026-04-19
**Substituta:** Task API v2
**Data de remoção:** Consultiva por enquanto
**Motivo:** A API antiga não suporta idempotência, observabilidade adequada
            nem autenticação padronizada. A v2 resolve esses pontos.

### Guia de Migração
1. Atualize o client para usar `/v2/tasks`
2. Adapte o payload para o novo contrato OpenAPI
3. Rode `go test ./...` no consumidor
4. Verifique o plano de infra se houver ajuste em integração ou IAM
```

### Passo 3: Migrar Incrementalmente

Migre consumidor por consumidor, não tudo de uma vez.

```text
1. Identificar todos os pontos de contato com o sistema depreciado
2. Atualizar para usar o substituto
3. Verificar equivalência de comportamento
4. Remover referências ao sistema antigo
5. Confirmar ausência de regressão
```

**Regra do Churn:** se você é dono da plataforma que está sendo depreciada, você é responsável por migrar consumidores ou oferecer compatibilidade suficiente para que eles quase não precisem agir.

### Passo 4: Remover o Sistema Antigo

Só depois que todos os consumidores tiverem migrado:

```text
1. Verificar uso zero com métricas, logs e análise de dependências
2. Remover o código
3. Remover testes, documentação e configuração associados
4. Remover avisos de depreciação
5. Registrar a remoção
```

## Padrões de Migração

### Strangler Pattern

Execute o sistema antigo e o novo em paralelo, movendo tráfego gradualmente:

```text
Fase 1: sistema novo recebe 0%, antigo 100%
Fase 2: sistema novo recebe 10% (canario)
Fase 3: sistema novo recebe 50%
Fase 4: sistema novo recebe 100%, antigo ocioso
Fase 5: remover sistema antigo
```

Em AWS, isso pode ser feito com alias ponderado de Lambda, roteamento por API Gateway ou feature flag por tenant.

### Adapter Pattern

Crie um adaptador para manter a interface antiga enquanto a implementação nova assume por baixo:

```go
type OldTaskAPI interface {
	GetTask(ctx context.Context, id int64) (OldTask, error)
}

type LegacyTaskService struct {
	newService NewTaskService
}

func (s LegacyTaskService) GetTask(ctx context.Context, id int64) (OldTask, error) {
	task, err := s.newService.GetTask(ctx, TaskID(strconv.FormatInt(id, 10)))
	if err != nil {
		return OldTask{}, err
	}

	return toOldTask(task), nil
}
```

### Migração com Feature Flag

Troque consumidores aos poucos:

```go
func ResolveTaskService(ctx context.Context, cfg Config, tenantID string) TaskService {
	if cfg.Flags.Enabled(ctx, "task-service-v2", tenantID) {
		return NewTaskServiceV2()
	}

	return NewTaskServiceV1()
}
```

## Código Zumbi

Código zumbi é código sem dono claro, com consumidores ativos e manutenção negligenciada. Sinais típicos:

- Sem commits relevantes há meses, mas ainda com tráfego
- Sem time ou responsável explícito
- Testes quebrados que ninguém corrige
- Dependências vulneráveis ou runtime velho sem plano de atualização
- Módulos Terraform, Lambdas ou filas antigas referenciadas só por legado

**Resposta:** ou alguém assume oficialmente e mantém, ou o sistema entra em depreciação com plano concreto.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Ainda funciona, por que remover?" | Código sem manutenção acumula dívida operacional e de segurança mesmo funcionando. |
| "Alguém pode precisar disso depois" | Se voltar a ser necessário, reconstruir costuma ser mais barato que manter lixo indefinidamente. |
| "A migração custa caro demais" | Compare esse custo com dois ou três anos de manutenção paralela. |
| "Deprecamos quando o sistema novo estiver pronto" | Se não planejar agora, a remoção nunca vira prioridade. |
| "Os consumidores migram sozinhos" | Não migram. É preciso tooling, comunicação e suporte. |
| "Mantemos os dois para sempre" | Dois sistemas equivalentes dobram custo de teste, docs, observabilidade e onboarding. |

## Sinais de Alerta

- Sistema depreciado sem substituto disponível
- Aviso de depreciação sem tooling nem documentação
- “Depreciação temporária” há anos sem progresso
- Código zumbi com tráfego ativo e sem dono
- Features novas adicionadas ao sistema já depreciado
- Deprecar sem medir uso atual
- Remover código sem confirmar consumo zero

## Verificação

Depois de concluir uma depreciação:

- [ ] O substituto cobre os casos críticos e está comprovado operacionalmente
- [ ] Existe guia de migração com passos concretos
- [ ] Todos os consumidores ativos foram migrados ou têm plano explícito
- [ ] Código antigo, testes, docs e configuração foram removidos
- [ ] Não restaram referências ao sistema depreciado
- [ ] Os avisos de depreciação foram limpos quando deixaram de ser necessários
