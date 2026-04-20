---
name: ci-cd-and-automation
description: Automatiza a configuração de pipelines de CI/CD. Use ao configurar ou modificar pipelines de build e deploy. Use quando precisar automatizar gates de qualidade, configurar executores de teste na CI ou definir estratégias de deploy.
---

# CI/CD e Automação

## Visão Geral

Automatize os gates de qualidade para que nenhuma mudança chegue à produção sem passar por testes, lint, validação de infraestrutura e build. CI/CD é o mecanismo de enforcement das outras skills: encontra o que humanos e agentes deixam passar, e faz isso com consistência em toda alteração.

**Shift Left:** quanto antes um problema é detectado, menor o custo. Um erro pego por `gofmt` leva segundos; o mesmo problema só descoberto após deploy em Lambda custa investigação, rollback e risco operacional. Traga verificações para o início do pipeline.

**Mais rápido é mais seguro:** lotes pequenos e releases frequentes reduzem risco. Um deploy com 3 mudanças é mais fácil de validar e reverter que um deploy com 30.

## Quando Usar

- Ao configurar o pipeline inicial de um projeto
- Ao adicionar ou modificar checagens automáticas
- Ao estruturar deploy para ambientes AWS
- Ao automatizar validação de Terraform e planos de mudança
- Ao investigar falhas de CI ou regressões de deploy

## O Pipeline de Qualidade

Toda mudança deve passar por estes gates antes do merge:

```
Pull Request Aberto
    │
    ▼
┌──────────────────────────┐
│   FORMAT CHECK           │  gofmt -l, terraform fmt -check
│   ↓ pass                 │
│   STATIC ANALYSIS        │  go vet, golangci-lint
│   ↓ pass                 │
│   UNIT TESTS             │  go test ./...
│   ↓ pass                 │
│   BUILD                  │  go build ./...
│   ↓ pass                 │
│   INFRA VALIDATION       │  terraform validate
│   ↓ pass                 │
│   INTEGRATION TESTS      │  API/DB/AWS mocks
│   ↓ pass                 │
│   TERRAFORM PLAN         │  revisão da mudança infra
│   ↓ pass                 │
│   SECURITY CHECKS        │  govulncheck, IAM review
└──────────────────────────┘
    │
    ▼
 Pronto para revisão
```

**Nenhum gate deve ser pulado.** Se `go vet` falha, corrija o código. Se `terraform validate` falha, corrija o módulo. Não transforme o pipeline em decoração.

## Quando Código e Pipeline Precisam Mudar Juntos

Sempre que a mudança introduzir um novo entrypoint, recurso de infraestrutura, pacote relevante de build ou fluxo crítico de deploy, revise também a automação.

Checklist rápido:

- O pipeline ainda compila tudo o que precisa compilar?
- Os testes certos estão sendo executados para a nova superfície?
- A validação de infraestrutura cobre o módulo ou ambiente alterado?
- Existem smoke tests, alarmes ou checks mínimos para o comportamento novo?

Se a resposta for "não sei", o pipeline ainda não representa corretamente a mudança.

## Configuração com GitHub Actions

### Pipeline Base de CI

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: Verify formatting
        run: |
          test -z "$(gofmt -l .)"
          terraform -chdir=terraform fmt -check -recursive

      - name: Go vet
        run: go vet ./...

      - name: GolangCI-Lint
        uses: golangci/golangci-lint-action@v6
        with:
          version: v1.64

      - name: Unit tests
        run: go test ./... -count=1 -race

      - name: Build
        run: go build ./...

      - name: Terraform init
        run: terraform -chdir=terraform init -backend=false

      - name: Terraform validate
        run: terraform -chdir=terraform validate

      - name: Govulncheck
        run: go run golang.org/x/vuln/cmd/govulncheck@latest ./...
```

### Testes de Integração com Banco

```yaml
  integration:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: app_test
          POSTGRES_USER: ci_user
          POSTGRES_PASSWORD: ${{ secrets.CI_DB_PASSWORD }}
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: Run integration tests
        env:
          DATABASE_URL: postgres://ci_user:${{ secrets.CI_DB_PASSWORD }}@localhost:5432/app_test?sslmode=disable
        run: go test ./integration/... -count=1 -v
```

> **Mesmo em banco de teste de CI, use GitHub Secrets ou cofre de segredos.** Hardcode de credenciais ruins em teste vira credencial ruim em produção cedo ou tarde.

### Plano de Terraform em Pull Request

```yaml
  terraform-plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.8

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-plan
          aws-region: us-east-1

      - name: Terraform init
        run: terraform -chdir=terraform/envs/dev init

      - name: Terraform plan
        run: terraform -chdir=terraform/envs/dev plan -out=tfplan

      - name: Upload plan artifact
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan
          path: terraform/envs/dev/tfplan
```

Use `OIDC` para autenticação com AWS sempre que possível. Evite credenciais estáticas em secrets quando o GitHub Actions pode assumir um role temporário.

## Realimentando Falhas de CI para Agentes

O valor de CI com agentes está no loop de feedback. Quando CI falha:

```
CI falha
    │
    ▼
Extraia a falha específica
    │
    ▼
Entregue ao agente:
"O pipeline falhou com este erro:
[trecho relevante]
Corrija a causa raiz e valide localmente antes de enviar de novo."
    │
    ▼
Agente corrige -> envia -> CI roda novamente
```

**Padrões úteis:**

```
Falha de formatação -> Rodar gofmt/terraform fmt e corrigir
Falha de análise estática -> Ler o ponto exato e corrigir a causa
Falha de teste -> Seguir debugging-and-error-recovery
Falha de build -> Validar imports, tags de build e módulos
Falha de plan -> Revisar variáveis, providers e mudança de estado
```

## Estratégias de Deploy

### Ambientes Efêmeros por PR

Para backend serverless, o equivalente a preview deploy é um stack efêmero em conta sandbox ou workspace isolado:

```yaml
deploy-preview:
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    - uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::123456789012:role/github-actions-preview
        aws-region: us-east-1
    - run: terraform -chdir=terraform/envs/preview init
    - run: terraform -chdir=terraform/envs/preview apply -auto-approve -var="pr_number=${{ github.event.number }}"
```

Ambientes efêmeros ajudam a validar integrações reais com API Gateway, Lambda, DynamoDB e permissões IAM sem tocar produção.

### Feature Flags

Feature flags desacoplam deploy de release. Em backend, isso pode ser controle por configuração, alias de Lambda, parâmetro em AppConfig ou rollout por tenant.

```go
if flags.Enabled(ctx, "new-pricing-engine", tenantID) {
	return newEngine.Calculate(ctx, request)
}

return legacyEngine.Calculate(ctx, request)
```

**Ciclo de vida da flag:** criar -> habilitar para teste -> canário -> rollout completo -> remover flag e código morto. Flag eterna vira dívida.

### Rollout em Etapas

```
PR mergeado em main
    │
    ▼
 Deploy em staging (automático)
    │ Verificação manual e smoke tests
    ▼
 Deploy em produção (manual ou promovido)
    │
    ▼
 Monitoração em CloudWatch / alarms / métricas por 15 minutos
    │
    ├── Erros detectados -> rollback
    └── Sem regressão -> concluído
```

### Plano de Rollback

Todo deploy precisa ser reversível:

```yaml
name: Rollback
on:
  workflow_dispatch:
    inputs:
      lambda_version:
        description: Versão anterior da Lambda para restaurar no alias
        required: true

jobs:
  rollback:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-prod
          aws-region: us-east-1

      - name: Repoint alias
        run: |
          aws lambda update-alias \
            --function-name task-api \
            --name prod \
            --function-version "${{ inputs.lambda_version }}"
```

Se o deploy depende de Terraform, mantenha também a estratégia para reaplicar uma revisão conhecida de infraestrutura.

## Gerenciamento de Ambientes

```
.env.example             -> Commitado (template local, sem segredos reais)
.env                     -> Não commitado
GitHub Secrets           -> Segredos do pipeline
AWS Secrets Manager      -> Segredos de runtime
SSM Parameter Store      -> Configuracoes por ambiente
OIDC + IAM Role          -> Credenciais temporarias para CI/CD
```

CI nunca deve ter acesso amplo a segredos de produção. Dê a cada job o menor conjunto possível de permissões IAM.

## Automação Além de CI

### Dependabot / Renovate

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: gomod
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

### Build Cop

Defina alguém responsável por manter a pipeline verde. Quando o build quebra, o Build Cop corrige ou reverte. Isso evita acúmulo de pipelines vermelhos esperando “alguém” agir.

### Checagens de PR

- **Reviews obrigatórios:** ao menos 1 aprovação antes do merge
- **Status checks obrigatórios:** CI e plan precisam passar
- **Proteção de branch:** sem force-push em `main`
- **Auto-merge:** permitido só após aprovação e pipeline verde

## Otimização de CI

Se o pipeline passa de 10 minutos, aplique nesta ordem:

```
Pipeline lento?
├── Cache de dependencias Go e plugins Terraform
│   └── Use cache do setup-go e TF_PLUGIN_CACHE_DIR
├── Jobs em paralelo
│   └── Separe lint, test, build e plan
├── Rodar apenas o que mudou
│   └── Path filters para ignorar docs-only PRs
├── Matrix quando fizer sentido
│   └── Shard de testes de integração ou multiplas versoes suportadas de Go
├── Tirar testes lentos do caminho crítico
│   └── Rodar nightly ou em pipeline dedicada
└── Runners maiores
    └── Quando compilacao ou testes realmente justificarem
```

**Exemplo com paralelismo:**

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true
      - run: test -z "$(gofmt -l .)"
      - run: go vet ./...

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true
      - run: go test ./... -count=1 -race

  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform -chdir=terraform init -backend=false
      - run: terraform -chdir=terraform fmt -check -recursive
      - run: terraform -chdir=terraform validate
```

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "CI está lento demais" | Otimize o pipeline; não desative os gates. Cinco minutos de CI evitam horas de incidente. |
| "Essa mudança é trivial, não precisa pipeline" | Mudança trivial também quebra build, permissão IAM e Terraform. |
| "O teste está flaky, é só rodar de novo" | Flakiness mascara bugs reais e corrói confiança no pipeline. Corrija a causa. |
| "A gente coloca CI depois" | Projetos sem CI acumulam estados quebrados cedo demais. Configure no dia zero. |
| "Teste manual basta" | Não escala, não é repetível e não protege produção de regressão. |

## Sinais de Alerta

- Projeto sem pipeline de CI
- Falhas de CI ignoradas ou “silenciadas”
- Testes desativados para fazer pipeline passar
- Deploy em produção sem validação em staging
- Ausência de rollback operacional
- Segredos armazenados em código, variáveis do workflow ou `terraform.tfvars`
- Pipeline lento sem esforço de otimização

## Verificação

Depois de configurar ou alterar o CI/CD:

- [ ] Todos os gates estão presentes: formatação, análise estática, testes, build e validação de infra
- [ ] O pipeline roda em todo PR e push para `main`
- [ ] Falhas bloqueiam merge via branch protection
- [ ] Resultados de CI alimentam o loop de correção do time/agentes
- [ ] Segredos ficam em GitHub Secrets, AWS Secrets Manager ou equivalente
- [ ] Deploy tem mecanismo claro de rollback
- [ ] O caminho crítico do pipeline fica abaixo de 10 minutos ou tem justificativa operacional
