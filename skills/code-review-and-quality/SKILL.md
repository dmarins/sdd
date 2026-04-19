---
name: code-review-and-quality
description: Conduz revisão de código multidimensional. Use antes de fazer merge de qualquer mudança. Use ao revisar código escrito por você, por outro agente ou por uma pessoa. Use quando precisar avaliar a qualidade do código em múltiplas dimensões antes de ele entrar na branch principal.
---

# Revisão de Código e Qualidade

## Visão Geral

Faça revisão multidimensional com gates claros de qualidade. Toda mudança deve ser revisada antes do merge. A revisão cobre cinco eixos: correção, legibilidade, arquitetura, segurança e desempenho.

**Padrão para aprovar:** aprove quando a mudança melhora claramente a saúde geral do código, mesmo que não seja perfeita. Código perfeito não existe. O objetivo é melhorar o sistema sem baixar a barra técnica.

## Quando Usar

- Antes de fazer merge em qualquer PR ou alteração
- Depois de concluir uma feature ou correção de bug
- Ao revisar código produzido por agente, modelo ou pessoa
- Durante refatorações
- Após qualquer bug fix, revisando também o teste de regressão

## A Revisão em Cinco Eixos

Toda revisão deve avaliar o código nestas dimensões:

### 1. Correção

O código faz o que diz que faz?

- Atende ao spec, ticket ou requisito informado?
- Casos de borda foram cobertos: vazio, zero, duplicidade, timeout, paginação, reprocessamento?
- Caminhos de erro foram tratados ou só o caminho feliz?
- Os testes validam o comportamento certo?
- Há risco de corrida, inconsistência de estado, retry não idempotente ou erro off-by-one?

### 2. Legibilidade e Simplicidade

Outro engenheiro entende isso sem o autor explicar?

- Nomes são descritivos e coerentes com convenções do projeto? Evite `tmp`, `data`, `result` sem contexto.
- O fluxo de controle é direto? Evite lógica excessivamente esperta, branching profundo e funções inchadas.
- O código está organizado por responsabilidade?
- Há abstrações prematuras ou helpers genéricos sem terceira ocorrência real?
- **Isso poderia ser resolvido em menos linhas?** Verbosidade desnecessária é custo.
- Comentários ajudam a explicar intenção não óbvia?
- Há resíduos de código morto, compatibilidade temporária ou TODOs esquecidos?

### 3. Arquitetura

A mudança se encaixa no desenho do sistema?

- Segue os padrões já usados para handlers, serviços, repositórios e módulos Terraform?
- Mantém limites claros entre domínio, transporte, persistência e infraestrutura?
- Existe duplicação que deveria virar código compartilhado?
- Dependências fluem na direção certa, sem acoplamento circular?
- O nível de abstração é adequado ou há overengineering?

### 4. Segurança

Para orientação detalhada, veja `security-and-hardening`. A mudança introduz risco?

- Input externo é validado nas bordas do sistema?
- Segredos ficam fora de código, logs e versionamento?
- Autenticação e autorização são checadas onde necessário?
- Consultas SQL são parametrizadas?
- Policies IAM seguem privilégio mínimo?
- Payloads de SQS, SNS, EventBridge, webhooks e APIs terceiras são tratados como dados não confiáveis?
- Logs evitam expor PII, tokens e material de autenticação?

### 5. Desempenho

Para profiling e otimização, veja `performance-optimization`. A mudança introduz gargalos?

- Há padrão N+1 em PostgreSQL, DynamoDB ou chamadas para serviços AWS?
- Existem loops sem limite ou scans caros sem critério de acesso?
- Há risco de cold start maior por dependências ou binários desnecessários?
- Endpoints de lista têm paginação e limites explícitos?
- Handlers fazem trabalho síncrono que deveria ir para fila ou processamento assíncrono?
- Memória, timeout e concorrência foram pensados para Lambda e jobs?

## Tamanho da Mudança

Mudanças pequenas são mais fáceis de revisar, mais rápidas de aprovar e mais seguras para deploy. Mire nestes tamanhos:

```
~100 linhas alteradas   -> Ótimo. Revisável em uma sessão.
~300 linhas alteradas   -> Aceitável se for uma única mudança lógica.
~1000 linhas alteradas  -> Grande demais. Divida.
```

**O que conta como uma mudança:** algo autocontido que resolve uma coisa, inclui verificação relacionada e mantém o sistema íntegro após submissão.

**Estratégias para dividir quando está grande demais:**

| Estratégia | Como | Quando |
|---|---|---|
| **Empilhar** | Submeter uma mudança pequena e basear a próxima nela | Dependências sequenciais |
| **Por grupo de arquivos** | Separar infraestrutura, domínio e transporte quando fizer sentido | Revisores diferentes ou riscos distintos |
| **Horizontal** | Criar base compartilhada primeiro, depois consumidores | Arquitetura em camadas |
| **Vertical** | Fatiar um fluxo completo menor | Feature work |

**Quando mudanças grandes podem ser aceitáveis:** exclusão total de arquivos, atualização mecânica amplamente automatizada ou geração revisada por contrato claro.

**Separe refatoração de feature.** Refatorar e mudar comportamento ao mesmo tempo quase sempre piora revisão, rollback e blame.

## Descrição da Mudança

Toda alteração precisa de descrição que sobreviva no histórico.

**Primeira linha:** curta, imperativa, independente. Exemplo: “Adicionar validação de payload no handler de criação de tarefas”.

**Corpo:** explique o que muda e por quê. Registre contexto, restrições, trade-offs e referências que não são visíveis no diff.

**Antipadrões:** “fix bug”, “ajustes”, “fase 1”, “move código”, “refactor geral”. Isso não ajuda ninguém a entender a história do sistema.

## Processo de Revisão

### Passo 1: Entender o Contexto

Antes de olhar o código, entenda a intenção:

```
- O que essa mudança pretende resolver?
- Qual requisito, incidente ou spec ela atende?
- Que comportamento esperado muda em produção?
```

### Passo 2: Revisar os Testes Primeiro

Testes revelam intenção e cobertura:

```
- Existem testes para a mudança?
- Eles validam comportamento e não detalhe de implementação?
- Casos de borda foram cobertos?
- Nomes dos testes deixam claro o cenário?
- O teste realmente pegaria regressão futura?
```

### Passo 3: Revisar a Implementação

Percorra o código com os cinco eixos em mente:

```
Para cada arquivo alterado:
1. Correção: faz o que o teste e o requisito pedem?
2. Legibilidade: alguém entende sem explicação oral?
3. Arquitetura: encaixa no desenho do sistema?
4. Segurança: abriu superfície de ataque ou vazamento?
5. Performance: piorou caminho quente, custo ou latência?
```

### Passo 4: Categorizar Achados

Toda observação precisa de severidade para separar obrigatório de opcional:

| Prefixo | Significado | Ação do autor |
|---|---|---|
| *(sem prefixo)* | Mudança requerida | Precisa resolver antes do merge |
| **Critical:** | Bloqueia merge | Vulnerabilidade, perda de dados, quebra funcional |
| **Nit:** | Opcional e pequeno | Pode ignorar |
| **Optional:** / **Consider:** | Sugestão | Vale avaliar, não é mandatória |
| **FYI** | Contexto apenas | Sem ação necessária |

Sem isso, todo comentário vira “será que preciso mudar?” e o review perde eficiência.

### Passo 5: Verificar a Verificação

Avalie a história de verificação do autor:

```
- Que testes foram rodados?
- go test ./... passou?
- go vet ./... passou?
- go build ./... passou?
- terraform validate / plan foram executados quando infra mudou?
- Houve verificação manual do fluxo em staging ou sandbox?
```

## Padrão Multi-Modelo de Revisão

Use modelos diferentes para perspectivas diferentes:

```
Modelo A escreve o código
    │
    ▼
Modelo B revisa correção e arquitetura
    │
    ▼
Modelo A endereça feedback
    │
    ▼
Humano toma a decisão final
```

Isso ajuda a capturar pontos cegos diferentes. Especialmente útil em mudanças que envolvem Go, AWS IAM e Terraform simultaneamente.

**Prompt útil para um agente revisor:**

```text
Revise esta mudança para correção, segurança, impacto operacional e aderência
às convenções do projeto. O requisito é [X]. A alteração deveria [Y].
Sinalize problemas como Critical, Required ou Suggestion.
```

## Higiene de Código Morto

Depois de qualquer refatoração ou implementação, procure por código órfão:

1. Identifique o que ficou inalcançável ou sem uso
2. Liste explicitamente
3. **Pergunte antes de remover** quando houver dúvida de escopo

```
CÓDIGO MORTO IDENTIFICADO:
- normalizeLegacyTaskID() em internal/id/legacy.go -> substituido por ParseTaskID()
- modulo terraform/modules/legacy-api -> sem referencias remanescentes
- flag ENABLE_LEGACY_ROUTING -> alias Lambda já não usa mais
-> Removo agora?
```

Não deixe entulho técnico confundindo futuros revisores e agentes.

## Velocidade de Review

Review lento bloqueia o time inteiro.

- **Responda em até um dia útil** como limite máximo
- **Cadência ideal:** feedback rápido logo após o pedido, se a mudança for revisável
- **Priorize respostas rápidas** a aprovações tardias; desbloquear cedo reduz retrabalho
- **Mudanças grandes:** peça para dividir em vez de revisar um diff inviável

## Como Lidar com Discordâncias

Use esta hierarquia:

1. **Fatos técnicos e dados** vencem opinião
2. **Style guides e convenções escritas** mandam em estilo
3. **Design de software** deve ser avaliado por princípios de engenharia, não gosto pessoal
4. **Consistência do código-base** é valiosa se não piorar a saúde geral do sistema

**Não aceite “limpo depois”.** Limpeza adiada quase nunca acontece. Exija ajuste antes do merge, salvo emergência real.

## Honestidade na Revisão

Ao revisar código, seja ele seu, de um agente ou de outra pessoa:

- **Não carimbe sem revisar.** “LGTM” sem evidência é ruído.
- **Não suavize bug real.** Se quebra produção, diga claramente.
- **Quantifique quando possível.** “Essa policy IAM abre `s3:*` na conta inteira” é melhor que “isso parece amplo”.
- **Questione abordagens com problema objetivo.** Sycophancy em review é falha.
- **Aceite override com contexto.** Se o autor tem informação que você não tem, ajuste a recomendação sem personalizar a discussão.

## Disciplina de Dependências

Parte da revisão é revisar dependências:

**Antes de adicionar qualquer dependência:**
1. A stack atual já resolve isso? Muitas vezes sim.
2. Qual o impacto em cold start, tamanho do binário ou complexidade operacional?
3. O projeto é mantido ativamente?
4. Há vulnerabilidades conhecidas? Rode `govulncheck ./...` ou ferramenta equivalente.
5. A licença é compatível?

**Regra:** prefira biblioteca padrão, utilitários existentes e serviços já aprovados. Toda dependência é um compromisso de manutenção.

## Checklist de Review

```markdown
## Review: [titulo do PR/mudança]

### Contexto
- [ ] Entendi o objetivo e a justificativa

### Correcao
- [ ] A mudança atende ao requisito
- [ ] Casos de borda foram tratados
- [ ] Caminhos de erro foram tratados
- [ ] Testes cobrem a mudança adequadamente

### Legibilidade
- [ ] Nomes sao claros e consistentes
- [ ] A logica e direta
- [ ] Não ha complexidade desnecessaria

### Arquitetura
- [ ] Segue os padroes existentes
- [ ] Não introduz acoplamento indevido
- [ ] O nivel de abstracao e apropriado

### Segurança
- [ ] Sem segredos no código
- [ ] Inputs validados nas bordas
- [ ] Sem SQL injection ou policy IAM excessiva
- [ ] Auth/AuthZ avaliados
- [ ] Dados externos tratados como não confiaveis

### Performance
- [ ] Sem N+1 ou scans desnecessarios
- [ ] Sem operações deslimitadas
- [ ] Endpoints de lista paginados
- [ ] Sem custo operacional desnecessario em Lambda

### Verificação
- [ ] go test ./... passou
- [ ] go build ./... passou
- [ ] terraform validate/plan passou quando aplicavel
- [ ] Verificação manual feita quando necessário

### Veredito
- [ ] **Approve**
- [ ] **Request changes**
```

## Veja Também

- Para revisão detalhada de segurança, veja `references/security-checklist.md`
- Para verificação detalhada de performance, veja `references/performance-checklist.md`

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Funciona, então está bom" | Código que funciona mas é ilegível, inseguro ou mal desenhado vira dívida cumulativa. |
| "Eu escrevi, então sei que está correto" | Autores são cegos às próprias suposições. Toda mudança ganha com outro olhar. |
| "A gente limpa depois" | Depois não chega. Review é o gate de qualidade. |
| "Código gerado por IA deve estar ok" | Código de IA exige mais revisão, não menos. Ele parece plausível mesmo quando está errado. |
| "Os testes passaram, então está pronto" | Teste é necessário, não suficiente. Não cobre arquitetura, segurança nem legibilidade. |

## Sinais de Alerta

- PRs sem qualquer revisão real
- Review que só olha resultado de testes
- “LGTM” sem evidência de leitura cuidadosa
- Mudança sensível de segurança sem revisão focada nesse eixo
- PRs grandes demais para revisão séria
- Bug fix sem teste de regressão
- Comentários sem severidade, deixando obrigatório e opcional misturados
- Aceitar “depois eu ajusto”

## Verificação

Após concluir a revisão:

- [ ] Todos os problemas críticos foram resolvidos
- [ ] Itens importantes foram resolvidos ou explicitamente adiados com justificativa
- [ ] Testes passam
- [ ] Build passa
- [ ] A história de verificação está documentada de forma objetiva
