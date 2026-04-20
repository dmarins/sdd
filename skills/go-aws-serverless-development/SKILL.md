---
name: go-aws-serverless-development
description: Guia o desenvolvimento em projetos Go com AWS e Terraform. Use ao implementar ou evoluir APIs, Lambdas, filas, eventos, IAM ou infraestrutura serverless em projetos que usam Go, AWS e Terraform como stack principal. Use quando precisar de um workflow de execução por camadas, validação completa e integração com CI/CD e documentação sem acoplar o fluxo a um projeto específico.
---

# Desenvolvimento Go + AWS + Terraform

## Visão Geral

Esta skill funciona como um perfil de execução para projetos serverless em Go. Ela não substitui as skills base do repositório. O papel dela é especializar o fluxo quando a tarefa cair claramente no contexto Go + AWS + Terraform.

Use em composição com:

- `incremental-implementation` para fatiar e executar a mudança
- `test-driven-development` para provar comportamento
- `context-engineering` para localizar exemplos locais e restrições
- `ci-cd-and-automation` quando a mudança exigir pipeline, quality gates ou smoke tests
- `documentation-and-adrs` quando a mudança alterar contratos, arquitetura ou operação

## Quando Usar

- Ao criar ou alterar funções AWS Lambda em Go
- Ao adicionar ou evoluir recursos de API Gateway, EventBridge, SQS, SNS, DynamoDB, S3 ou IAM
- Ao modificar módulos Terraform que provisionam componentes da aplicação
- Ao implementar uma feature ponta a ponta em backend serverless
- Ao precisar de um workflow mais prescritivo para projetos cuja stack principal é Go + AWS + Terraform

**Quando NÃO usar:** tarefas agnósticas de stack, mudanças puramente documentais, ajustes pequenos em um único arquivo sem impacto de integração, ou projetos cujo backend não siga esse modelo.

## O Papel Desta Skill

Pense nela como um perfil especializado, não como uma fase nova do fluxo. O ciclo continua sendo:

```text
/spec -> /plan -> /build -> /test -> /review -> /ship
```

O que muda é o nível de orientação dentro do `build` e das skills de apoio quando a stack exige decisões repetitivas sobre camadas, infraestrutura, validação e operação.

## Sequência Recomendada

Quando a tarefa cair nesta stack, siga esta ordem:

1. Entenda a feature e identifique o recurso principal afetado
2. Localize uma implementação de referência já existente no projeto
3. Mapeie as camadas afetadas: contrato, handler, serviço/use case, adapter/repository, infraestrutura, automação e documentação
4. Implemente em fatias pequenas, de dentro para fora ou por caminho vertical completo, conforme o risco
5. Valide em camadas: unitário, integração e ponta a ponta quando a mudança cruzar fronteiras reais
6. Atualize pipeline, smoke tests e documentação sempre que a mudança criar nova superfície operacional

## Preparação Antes de Codar

Antes da primeira edição, confirme:

```text
CHECKLIST DE CONTEXTO:
1. Qual é o recurso principal? API, evento, fila, job, integração ou infra?
2. Qual arquivo ou módulo existente é o melhor modelo local?
3. Quais fronteiras serão cruzadas? HTTP, fila, banco, IAM, evento, deploy?
4. Quais verificações locais e de CI precisam mudar junto?
5. Existe impacto em documentação operacional, contrato público ou rollout?
```

Se você não encontrou um exemplo local confiável, pare e procure um antes de inventar um padrão novo.

## Modelo de Referência Local

O repositório atual é sempre a referência principal. Esta skill não pressupõe que o agente vá buscar código em outro projeto durante a execução. O objetivo aqui é evitar que padrões externos, usados como inspiração na criação desta skill, sejam tratados como regra universal no projeto em que ela estiver sendo aplicada.

Faça assim:

1. Localize no projeto atual uma feature parecida já implementada
2. Use esse exemplo como referência principal de nomenclatura, construtores, testes, wiring e Terraform
3. Se não houver exemplo completo, monte a referência a partir de dois ou três pontos locais menores
4. Só proponha um padrão novo quando os exemplos locais forem insuficientes ou inconsistentes

**Ruim:** “sempre use a entidade X de outro projeto como modelo obrigatório”.

**Bom:** “encontre no projeto atual a implementação mais próxima e siga esse padrão”.

## Ordem de Construção

Em tarefas desta stack, a ordem mais segura costuma ser uma destas:

### Caminho vertical completo

```text
Contrato -> handler -> serviço/use case -> adapter/repository -> infra -> testes -> docs
```

Use quando a feature precisa entregar comportamento visível de ponta a ponta rapidamente.

### Dentro para fora

```text
Domínio/contrato -> lógica -> adapters -> entrypoint -> infraestrutura
```

Use quando a complexidade principal está na regra de negócio ou no desenho das interfaces.

### Pelo risco

```text
IAM/permissão/integração crítica -> fluxo principal -> robustez operacional
```

Use quando o maior risco estiver em credenciais, wiring, provider, evento, fila ou permissão.

## Camadas que Geralmente Precisam Ser Revisadas

Ao implementar ou alterar uma feature, verifique explicitamente quais destas camadas entram no escopo:

- Contratos de entrada e saída
- Handler ou entrypoint
- Serviço, use case ou regra de negócio
- Adapter, repository ou client de integração
- Infraestrutura Terraform
- Pipeline e quality gates
- Testes de integração e smoke tests
- Documentação funcional ou operacional

Não assuma que só porque a mudança começou no handler ela termina ali.

## Validação em Camadas

Para esta stack, não pare na suite unitária se a mudança cruzar fronteiras reais.

### Mínimo esperado por tipo de mudança

| Mudança | Validação mínima |
|---|---|
| Regra pura de negócio | teste unitário |
| Handler ou adapter | unitário + integração local |
| Terraform ou wiring AWS | validação de infra + smoke test relevante |
| Nova feature ponta a ponta | unitário + integração + uma validação E2E ou equivalente |

### Sequência prática

```text
1. go test ./...
2. go build ./...
3. go vet ./...
4. terraform fmt -check / terraform validate, se houver infra
5. Smoke test local ou ambiente controlado, se a feature cruzar fronteiras reais
```

Adapte os comandos exatos ao projeto atual. A obrigação é a cobertura de risco, não o nome literal do comando.

## Quando Atualizar CI/CD

Se a mudança introduzir um novo entrypoint, novo tipo de recurso ou nova verificação obrigatória, revise também a automação.

Cheque pelo menos:

- build e testes continuam cobrindo os novos pacotes ou binários
- o pipeline valida a infraestrutura alterada
- smoke tests ou checks de deploy continuam representando o comportamento crítico
- novos recursos observáveis têm logs, métricas ou alarmes quando aplicável

Não trate pipeline como detalhe pós-feature. Em backend serverless, pipeline quebrado ou desatualizado é regressão funcional.

## Quando Atualizar Documentação

Atualize documentação quando houver mudança em qualquer um destes pontos:

- contrato público ou comportamento visível
- operação, deploy ou rollback
- arquitetura ou decisão estrutural
- catálogo de comandos, skills ou fluxo de trabalho do projeto

Se o projeto usar a separação entre “planejado” e “implementado”, promova o conteúdo correspondente depois que a validação final passar.

## Regras de Escopo

- Ao aplicar esta skill, parta sempre dos padrões e exemplos do próprio repositório alvo
- Não trate convenções externas usadas como inspiração para esta skill como regras universais do projeto atual
- Não replique nomes, paths, alvos de Makefile ou convenções sem validar antes se eles existem e fazem sentido no repositório atual
- Não crie uma skill genérica chamada `dev` se o catálogo atual já privilegia nomes explícitos por propósito
- Não duplique nas skills base o que só faz sentido nesta stack
- Não transforme o comando `build` em uma exceção longa e específica; mantenha a especialização nesta skill

## Antipadrões

| Antipadrão | Problema | Correção |
|---|---|---|
| Importar convenções externas sem validação local | O agente replica nomes, estrutura ou automações que não pertencem ao projeto atual | Use referências locais primeiro e adapte qualquer padrão externo antes de adotá-lo |
| Parar em teste unitário | Não prova wiring nem infra | Adicione integração ou smoke test adequado |
| Atualizar código sem CI/CD | Pipeline deixa de representar a feature | Revise quality gates e automação junto |
| Criar padrão novo sem referência local | A base perde coerência | Parta de um exemplo já existente |
| Enfiar tudo no `build` | Comando perde padronização | Use `build` como wrapper e esta skill como perfil |

## Verificação

Antes de concluir a tarefa, confirme:

- [ ] A mudança seguiu um exemplo local ou justificou a ausência dele
- [ ] As camadas afetadas foram identificadas explicitamente
- [ ] A validação cobriu o nível certo de risco: unitário, integração e/ou E2E
- [ ] CI/CD e smoke tests foram revisados quando necessário
- [ ] Documentação e operação foram atualizadas quando a mudança alterou comportamento, arquitetura ou rollout
- [ ] Nenhum nome, caminho ou convenção foi reproduzido sem confirmar que existe e faz sentido no repositório atual