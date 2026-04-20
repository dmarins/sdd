---
name: go-runtime-and-dependency-upgrades
description: Atualiza runtime Go e dependências Go com segurança. Use ao fazer upgrade da versão do Go, atualizar módulos do go.mod, renovar dependências diretas ou indiretas, responder a advisories de segurança, ou revisar compatibilidade de toolchain, CI e runtime após um bump de Go.
---

# Upgrades de Runtime e Dependências Go

## Visão Geral

Esta skill trata upgrades planejados de toolchain e dependências Go como uma mudança de engenharia completa, não como um simples `go get` seguido de `go mod tidy`.

Ela cobre três modos de trabalho:

1. **Runtime only** — atualizar a versão do Go e os pontos onde ela é referenciada
2. **Dependencies only** — atualizar módulos Go sem trocar a versão do runtime
3. **Runtime + dependencies** — executar os dois movimentos de forma coordenada

Use esta skill quando a mudança for de manutenção planejada. Para adicionar uma única biblioteca por necessidade de feature, siga o fluxo normal de implementação.

## Quando Usar

- Ao atualizar a versão do Go no `go.mod`, `toolchain`, CI, Dockerfile ou runtime associado
- Ao atualizar dependências diretas ou indiretas do projeto
- Ao responder a CVEs, advisories ou módulos descontinuados
- Ao preparar o projeto para nova versão de build image, runtime AWS ou compatibilidade de tooling
- Ao revisar um repositório que está defasado e precisa de refresh de toolchain e módulos

**Quando NÃO usar:** adição pontual de uma dependência para uma feature nova, pequenas mudanças sem impacto de toolchain, ou tarefas que não envolvam Go.

## Composição com Outras Skills

Combine com:

- `ci-cd-and-automation` para revisar pipeline, cache, imagens base e quality gates
- `deprecation-and-migration` quando o upgrade introduzir breaking changes, APIs removidas ou substituição de módulos
- `debugging-and-error-recovery` quando o upgrade quebrar build, testes ou integrações
- `go-aws-serverless-development` quando o projeto usar Go + AWS + Terraform e o upgrade impactar runtime, Lambda, imagens ou deploy

## Escolha o Modo de Upgrade

Antes de começar, classifique o trabalho:

```text
1. O objetivo é atualizar a versão do Go?
   -> runtime only

2. O objetivo é atualizar bibliotecas ou módulos?
   -> dependencies only

3. Os dois precisam andar juntos?
   -> runtime + dependencies
```

Não misture os modos por conveniência. Se houver risco alto, faça em incrementos separados.

## Princípios Centrais

### 1. Alvo Explícito, Não “latest” Cego

Sempre trabalhe com uma versão-alvo ou política de upgrade explícita:

- upgrade para uma versão específica do Go
- upgrade patch de dependências
- upgrade de uma lista explícita de módulos
- refresh controlado de dependências com revisão de majors

**Ruim:** “atualizar tudo para o mais recente e ver o que quebra”.

**Bom:** “subir para Go 1.24.x e atualizar dependências patch/minor, revisando majors separadamente”.

### 2. O Repositório Atual Define a Superfície de Mudança

Antes de executar o upgrade, mapeie onde a versão do Go e as dependências aparecem de fato:

- `go.mod` e `go.sum`
- `Dockerfile`, imagens base e toolchain pinning
- workflows de CI/CD
- arquivos como `.tool-versions`, `mise.toml`, `asdf`, `devcontainer`, `Taskfile`, `Makefile`
- runtimes e build scripts de Lambda ou deploy serverless

Não assuma que o projeto usa apenas `go.mod` como fonte de verdade.

### 3. Upgrade É Mudança de Compatibilidade

Uma mudança de runtime ou dependência pode alterar:

- comportamento de build
- APIs disponíveis
- warnings e regras de lint
- imagens de container
- cache de CI
- runtimes de produção
- tempo de cold start, binários e empacotamento

Por isso, valide a superfície completa afetada.

## Preparação

Antes da primeira edição, responda:

```text
CHECKLIST DE PREPARAÇÃO:
1. Qual é o alvo exato do upgrade?
2. O upgrade é runtime, dependências ou ambos?
3. Quais arquivos referenciam a versão do Go ou o processo de build?
4. Há dependências críticas com histórico de breaking changes?
5. O projeto depende de runtime específico em CI, Docker, Lambda ou infraestrutura?
6. Qual é o comando local de testes, build, lint e smoke test deste repositório?
7. Como reverter se o upgrade falhar?
```

Se você não consegue responder à pergunta 6, ainda não está pronto para executar o upgrade.

## O Processo de Upgrade

### Etapa 1: Mapear a Superfície Impactada

Leia os arquivos relevantes antes de alterar qualquer coisa:

- `go.mod` e `go.sum`
- pipeline de CI
- arquivos de build local
- Dockerfiles e imagens base
- scripts de release, deploy ou empacotamento
- arquivos de runtime relacionados a Lambda ou ambiente de produção

Monte uma lista explícita do que precisa mudar junto.

### Etapa 2: Definir a Estratégia

Escolha uma destas estratégias:

#### Runtime only

- Atualizar a versão do Go explicitamente
- Ajustar os pontos onde o projeto fixa toolchain ou runtime
- Rodar verificação completa

#### Dependencies only

- Atualizar dependências de forma conservadora e revisável
- Preferir módulos explícitos, faixas controladas ou upgrades patch/minor antes de majors
- Tratar upgrades major como mudanças com impacto de compatibilidade, não como detalhe de manutenção

#### Runtime + dependencies

- Atualizar o runtime primeiro ou em fatia separada se o risco for alto
- Atualizar dependências em seguida
- Validar o resultado consolidado e documentar o que mudou em cada camada

### Etapa 3: Executar o Upgrade

Execute somente o necessário para a estratégia escolhida.

Exemplos de operações comuns:

- atualizar versão do Go no `go.mod`
- atualizar ou revisar diretiva `toolchain`
- rodar `go mod tidy`
- rodar `go fix ./...` quando a mudança de runtime justificar
- atualizar dependências específicas ou grupos de dependências

Adapte os comandos ao repositório atual. Esta skill não presume um único comando universal para todos os projetos.

### Etapa 4: Corrigir Compatibilidade

Depois do bump inicial:

- leia os erros de compilação e warnings novos
- ajuste usos de API removida ou alterada
- trate quebras de interface ou mudanças de comportamento
- revise código gerado, mocks e artefatos quando o projeto exigir

Se o upgrade expuser breaking changes grandes, pare de tratar isso como manutenção invisível e aplique também `deprecation-and-migration`.

### Etapa 5: Validar Localmente

Rode as verificações relevantes do projeto atual. Como baseline:

```text
1. go test ./...
2. go build ./...
3. go vet ./...
4. lint ou análise estática do projeto
5. smoke tests, integração ou deploy local quando o projeto exigir
```

Se o projeto for Go + AWS + Terraform, verifique também build de Lambda, empacotamento, Terraform e fluxos de deploy local relevantes.

### Etapa 6: Revisar CI/CD e Runtime

Confirme que o upgrade não deixou a automação desatualizada:

- `setup-go` ou equivalente usam a nova versão?
- Dockerfile e imagens base ainda estão compatíveis?
- cache de módulos e build continua válido?
- scripts de build, release e deploy usam a mesma toolchain?
- runtimes AWS, empacotamento e pipelines serverless continuam corretos?

Upgrade de Go sem revisão de CI é upgrade incompleto.

### Etapa 7: Reportar Resultado e Plano de Reversão

Ao concluir, reporte:

- versão anterior e nova do runtime, quando aplicável
- dependências principais alteradas
- verificações executadas
- erros ou avisos encontrados e como foram resolvidos
- pontos que ainda exigem acompanhamento
- plano de rollback, se a mudança ainda não foi promovida

## Breaking Changes e Dependências Major

Trate com cuidado especial:

- upgrades major de módulos amplamente usados
- mudanças de comportamento do runtime Go
- bibliotecas de observabilidade, auth, HTTP, AWS SDK, ORM ou serialização
- alteração de imagem base ou empacotamento de runtime

Nesses casos:

1. Faça o diff conceitual do que mudou
2. Identifique os pontos consumidores
3. Corrija com validação explícita
4. Documente a mudança se ela impactar a equipe ou a operação

## Antipadrões

| Antipadrão | Problema | Correção |
|---|---|---|
| Atualizar tudo para `latest` sem estratégia | O diff explode e a causa das quebras fica difusa | Trabalhe com alvo explícito e fatias menores |
| Rodar só `go mod tidy` e encerrar | Não prova compatibilidade nem runtime | Execute build, testes, lint e checks reais |
| Ignorar CI, Dockerfile ou runtime AWS | O projeto passa localmente e quebra fora | Revise toda a superfície de execução |
| Tratar major upgrade como rotina invisível | APIs quebram silenciosamente | Separe, revise e migre conscientemente |
| Assumir comandos fixos de outro projeto | O workflow não generaliza | Descubra os comandos reais do repositório atual |

## Verificação

Antes de concluir o upgrade, confirme:

- [ ] O alvo do upgrade foi definido explicitamente
- [ ] A superfície impactada foi mapeada antes das mudanças
- [ ] Runtime, dependências, CI e build foram revisados conforme o escopo
- [ ] Os comandos reais de validação do projeto foram executados
- [ ] Breaking changes e módulos major receberam tratamento explícito
- [ ] Existe resumo do que mudou e como reverter, se necessário