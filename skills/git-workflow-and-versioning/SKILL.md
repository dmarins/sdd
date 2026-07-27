---
name: git-workflow-and-versioning
description: Estrutura práticas de fluxo de trabalho com Git. Use ao fazer qualquer mudança de código. Use ao criar commits, branches, resolver conflitos ou quando precisar organizar o trabalho em vários fluxos paralelos. Use ao cortar uma release, escolher o bump de versão semântica, criar a tag ou escrever o changelog.
---

# Workflow de Git e Versionamento

## Visão Geral

Git é sua rede de segurança. Trate commits como save points, branches como sandboxes e o histórico como documentação. Com agentes gerando mudanças em alta velocidade, versionamento disciplinado é o que mantém alterações gerenciáveis, revisáveis e reversíveis.

## Quando Usar

Sempre. Toda mudança de código passa por Git.

## Princípios Centrais

### Desenvolvimento Trunk-Based (Recomendado)

Mantenha `main` sempre implantável. Trabalhe em branches curtas que voltem para `main` em 1 a 3 dias. Branch longa é custo escondido: diverge, cria conflito e atrasa integração.

```text
main ──●──●──●──●──●──●──●──●──●──  (sempre deployavel)
        ╲      ╱  ╲    ╱
         ●──●─╱    ●──╱    <- branches curtas (1-3 dias)
```

Esse é o padrão recomendado. Times que usam outro modelo ainda devem preservar os princípios: commits atômicos, mudanças pequenas e mensagens úteis.

- **Branch de desenvolvimento é custo.** Cada dia vivo aumenta risco de merge.
- **Branch de release é aceitável** quando você precisa estabilizar uma entrega enquanto `main` anda.
- **Feature flag é melhor que branch longa.** Prefira deployar código incompleto atrás de flag a manter semanas de divergência.

### 1. Commitar Cedo, Commitar Sempre

Cada incremento verificado merece um commit. Não acumule uma montanha não commitada.

```text
Padrao:
  Implementar slice -> Testar -> Verificar -> Commitar -> Próximo slice

Não isto:
  Implementar tudo -> Torcer -> Commit gigante
```

Commits são save points. Se o próximo passo quebrar algo, você volta para o último estado bom com baixo custo.

### 2. Commits Atômicos

Cada commit faz uma única coisa lógica:

```text
# Bom
git log --oneline
a1b2c3d Adicionar handler de criacao de tarefas com validacao
d4e5f6g Provisionar IAM role da task-api via Terraform
h7i8j9k Adicionar testes de integração para criacao de tarefas

# Ruim
git log --oneline
x1y2z3a Ajustes gerais, refactor, infra, testes e fixes
```

### 3. Mensagens Descritivas

Mensagem de commit deve explicar o *porquê*, não só o *o quê*:

```text
# Bom: explica a intenção
feat: adicionar validação de idempotency key no endpoint de tarefas

Evita criações duplicadas em retries do API Gateway e alinha o handler
ao contrato documentado no OpenAPI.

# Ruim: descreve o que já é óbvio pelo diff
update handler.go
```

**Formato:**

```text
<tipo>: <descricao curta>

<corpo opcional explicando por que>
```

**Tipos comuns:**
- `feat` -> nova funcionalidade
- `fix` -> correção de bug
- `refactor` -> mudança estrutural sem alterar comportamento
- `test` -> criação ou ajuste de testes
- `docs` -> documentação
- `chore` -> tooling, config, dependências

### 4. Separe Preocupações

Não misture formatação com mudança de comportamento. Não misture refactor com feature. Idealmente, cada preocupação vai em commit e PR próprios.

```text
# Bom
git commit -m "refactor: extrair validacao de payload para pacote interno"
git commit -m "feat: adicionar validacao de tenant no handler de tarefas"

# Ruim
git commit -m "refactor do handler e adiciona tenant validation"
```

**Refatoração e feature são mudanças diferentes.** Separar simplifica review, revert e entendimento histórico.

### 5. Dimensione a Mudança

Mire em ~100 linhas por commit ou PR. Mudanças com ~1000 linhas devem ser divididas. Veja `code-review-and-quality` para estratégias de splitting.

```text
~100 linhas  -> Facil de revisar e reverter
~300 linhas  -> Aceitavel para uma unica mudança logica
~1000 linhas -> Dividir
```

## Estratégia de Branches

### Feature Branches

```text
main (sempre deployavel)
  │
  ├── feature/task-api-create
  ├── feature/billing-webhook
  └── fix/duplicate-tasks
```

- Crie a branch a partir de `main`
- Mantenha-a curta e viva por pouco tempo
- Delete depois do merge
- Prefira flags a branches longas para trabalho incompleto

### Nome de Branch

```text
feature/<descricao-curta>   -> feature/task-api-create
fix/<descricao-curta>       -> fix/duplicate-tasks
chore/<descricao-curta>     -> chore/update-go-version
refactor/<descricao-curta>  -> refactor/task-service
```

### Checagem de Freshness Antes de Começar

Antes de iniciar uma mudança relevante, confira se sua base está atualizada em relação ao trunk principal:

```bash
# Ver branch atual
git branch --show-current

# Estando em main, atualize antes de abrir a branch
git pull origin main

# Estando em branch de trabalho, confira a distancia para main
git fetch origin
git log HEAD..origin/main --oneline
```

Se houver divergencia relevante, integre isso cedo. Conflito descoberto no fim do trabalho custa mais do que conflito descoberto no inicio.

## Trabalhando com Worktrees

Para trabalho paralelo com múltiplos agentes, use `git worktree`:

```bash
git worktree add ../task-api-create feature/task-api-create
git worktree add ../billing-webhook feature/billing-webhook

# Cada worktree tem sua propria branch e diretorio
ls ../
  sdd/
  task-api-create/
  billing-webhook/

# Ao terminar
git worktree remove ../task-api-create
```

Benefícios:

- Agentes podem trabalhar em paralelo sem trocar de branch
- Cada diretório fica isolado por feature
- Experimentos ruins podem ser descartados sem sujar o fluxo principal
- Nada é misturado até merge explícito

## O Padrão de Save Point

```text
Agente inicia trabalho
    │
    ├── Faz uma mudança
    │   ├── Testes passam? -> Commit -> Continua
    │   └── Testes falham? -> Reverte a ultima fatia local -> Investiga
    │
    ├── Faz outra mudança
    │   ├── Testes passam? -> Commit -> Continua
    │   └── Testes falham? -> Volta ao ultimo estado bom -> Investiga
    │
    └── Feature concluida -> Histórico limpo e revisavel
```

Esse padrão limita a perda máxima a um único incremento. Em vez de acumular retrabalho, você ancora progresso em estados verificados.

## Resumo de Mudanças

Depois de modificar algo, forneça resumo estruturado. Isso ajuda review, reforça disciplina de escopo e evidencia o que ficou de fora:

```text
MUDANÇAS FEITAS:
- internal/handlers/tasks_create.go: adicionada validacao do payload
- internal/validation/task.go: criado schema de validacao
- terraform/modules/task_api/main.tf: ajustada policy IAM do handler

NÃO TOQUEI (INTENCIONALMENTE):
- internal/handlers/auth.go: tem padrao semelhante, mas fora do escopo
- terraform/modules/network: sem relação com esta mudança

PONTOS DE ATENCAO:
- A validacao nova rejeita campos extras no payload; confirmar se e desejado
- O timeout da Lambda segue em 10s; se o fluxo crescer, revisar
```

Esse padrão reduz suposições erradas e facilita revisão dirigida.

## Higiene Pré-Commit

Antes de cada commit:

```bash
# 1. Veja o que realmente vai entrar
git diff --staged

# 2. Procure segredo evidente
git diff --staged | grep -Ei "password|secret|api[_-]?key|token|aws_access_key_id"

# 3. Rode verificacoes de código
gofmt -w .
go vet ./...
go test ./...
go build ./...

# 4. Se mexeu em infraestrutura
terraform -chdir=terraform fmt -recursive
terraform -chdir=terraform validate
```

Automatize parte disso com hooks quando fizer sentido.

## Lidando com Arquivos Gerados

- **Commitar** arquivos gerados que o projeto espera versionar, como `go.sum`, `.terraform.lock.hcl`, migrations ou especificações geradas aprovadas pelo time
- **Não commitar** binários, cobertura, `terraform.tfstate`, `.terraform/`, `.env` ou credenciais
- **Mantenha um `.gitignore`** cobrindo pelo menos: `bin/`, `coverage.out`, `.env`, `.terraform/`, `terraform.tfstate*`, `*.pem`

## Usando Git para Depuração

```bash
# Encontrar o commit que introduziu um bug
git bisect start
git bisect bad HEAD
git bisect good <commit-bom-conhecido>

# Ver mudanças recentes em uma area
git log --oneline -20 -- internal/handlers/

# Ver quem mudou uma linha critica
git blame internal/service/task_service.go

# Buscar commits por palavra-chave
git log --grep="idempotency" --oneline
```

## Release e Versionamento

Commits são como *você* acompanha a mudança; uma **versão** é como os seus *consumidores* a acompanham. No momento em que qualquer outra coisa depende do seu código — outro time, um pacote publicado, um cliente implantado — "o mais recente na main" deixa de ser resposta suficiente para "o que estou rodando, e é seguro atualizar?". Um número de versão e um changelog são o contrato que responde a isso.

### Versionamento Semântico

Para qualquer coisa com consumidores, versione `MAJOR.MINOR.PATCH` e deixe o número carregar significado:

```
  MAJOR  mudança quebrando compatibilidade — consumidores precisam mudar o código para atualizar
  MINOR  funcionalidade nova, retrocompatível — seguro atualizar
  PATCH  correção de bug, retrocompatível — seguro atualizar
```

O número é uma promessa, então faça o código corresponder a ele. Um "patch" que muda comportamento do qual consumidores dependiam é uma mudança major disfarçada (Lei de Hyrum — veja a skill `api-and-interface-design`). Na dúvida sobre se uma mudança quebra compatibilidade, assuma que quebra; um major surpresa é muito mais barato que um consumidor quebrado.

### Crie a tag da release, e deixe a tag ser a fonte de verdade

Uma release é um ponto imutável na história, não uma branch em movimento. Crie a tag para que ela sempre possa ser reproduzida:

```bash
git tag -a v1.4.0 -m "Release 1.4.0"
git push origin v1.4.0
```

Derive a versão da tag em vez de editá-la à mão em arquivos espalhados, para que o artefato, a tag e o changelog nunca possam discordar.

### Mantenha um changelog escrito para humanos

Um changelog não é `git log`. É a resposta curada, voltada ao consumidor, para "o que mudou e isso me afeta?" — agrupada por `Added / Changed / Fixed / Deprecated / Removed / Security`, mais recente no topo, cada entrada formulada em torno do impacto no usuário, não da mecânica interna.

```markdown
## [1.4.0] - 2025-06-12
### Added
- Importação de tarefas em lote via CSV
### Fixed
- Deriva de fuso horário nas datas de vencimento de tarefas recorrentes
### Deprecated
- `GET /v1/tasks/all` — use o paginado `GET /v1/tasks` (remoção na 2.0)
```

Escreva a entrada na mesma mudança que faz a mudança, enquanto o impacto está fresco — não reconstruída por arqueologia de commits na hora da release. Mudanças que quebram compatibilidade ganham nota de migração e janela de depreciação (siga a skill `deprecation-and-migration`); entregar a release em si é trabalho da skill `shipping-and-launch` — esta seção é o contrato de versionamento que a alimenta.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Eu commito quando terminar tudo" | Commit gigante é ruim de revisar, depurar e reverter. |
| "A mensagem não importa" | Mensagem é documentação de histórico. |
| "Depois eu faço squash e arrumo" | Melhor construir histórico limpo desde o começo. |
| "Branch dá trabalho" | Branch curta é barata e evita colisão. A branch longa é que custa caro. |
| "Depois eu separo esse diff" | Quanto antes dividir, mais seguro e revisável fica. |
| "Não preciso de `.gitignore`" | Até o dia em que `terraform.tfstate` ou `.env` entra no repositório. |
| "É só uma correçãozinha, sobe o patch" | Verifique o que os consumidores conseguem observar. Uma mudança de comportamento da qual eles dependiam é major, seja qual for o tamanho do diff. |
| "O changelog é só o log de commits" | Commits são para você; o changelog é para os consumidores, curado por impacto. Gerar um a partir de commits crus enterra o que importa. |
| "Escrevemos o changelog na hora da release" | A essa altura o impacto é reconstruído de memória e metade se perdeu. Escreva a entrada junto com a mudança. |

## Sinais de Alerta

- Mudanças grandes acumuladas sem commit
- Mensagens como “fix”, “update”, “misc”
- Formatação misturada com comportamento
- Ausência de `.gitignore`
- Commit de `.env`, `terraform.tfstate`, binários ou artefatos
- Branches longas e muito divergentes de `main`
- Force-push em branch compartilhada
- Mudança que quebra compatibilidade entregue sob bump minor ou patch
- Release sem tag, ou número de versão editado à mão fora de sincronia com a tag
- Release visível ao usuário sem entrada de changelog, ou changelog que é só um despejo de mensagens de commit

## Verificação

Para cada commit:

- [ ] O commit faz uma única coisa lógica
- [ ] A mensagem explica o porquê e segue convenção de tipo
- [ ] Testes passam antes do commit
- [ ] O diff não contém segredos
- [ ] Mudanças de formatação não foram misturadas com comportamento
- [ ] O `.gitignore` cobre exclusões padrão do stack

Para cada release (qualquer coisa com consumidores):

- [ ] O bump de versão corresponde à mudança: quebra → major, aditiva → minor, correção → patch
- [ ] A release tem tag, e a versão é derivada da tag, não editada à mão fora de sincronia
- [ ] O changelog tem uma entrada curada e legível por humanos, agrupada por impacto, para esta versão
