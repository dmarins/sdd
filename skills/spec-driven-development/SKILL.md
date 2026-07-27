---
name: spec-driven-development
description: Cria especificações antes de codificar. Use ao iniciar um novo projeto, funcionalidade ou mudança significativa quando ainda não existe especificação. Use quando os requisitos estiverem pouco claros, ambíguos ou existirem apenas como uma ideia vaga.
---

# Desenvolvimento Guiado por Especificação

## Visão Geral

Escreva uma especificação estruturada antes de escrever qualquer código. A spec é a fonte de verdade compartilhada entre você e o engenheiro humano — ela define o que estamos construindo, por quê, e como saberemos que está pronto. Código sem spec é chute.

## Quando Usar

- Início de um novo projeto ou funcionalidade
- Requisitos ambíguos ou incompletos
- A mudança toca múltiplos arquivos ou módulos
- Você está prestes a tomar uma decisão arquitetural
- A tarefa levaria mais de 30 minutos para ser implementada

**Quando NÃO usar:** correções de uma linha, ajustes de typo ou mudanças cujos requisitos são inequívocos e autocontidos.

## O Workflow com Gates

O desenvolvimento guiado por especificação tem quatro fases. Não avance para a próxima fase até a atual ser validada.

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Humano     Humano   Humano     Humano
 revisa     revisa   revisa     revisa
```

### Fase 1: Especificar

Comece com a visão de alto nível. Faça perguntas esclarecedoras ao humano até os requisitos ficarem concretos.

**Exponha as premissas imediatamente.** Antes de escrever qualquer conteúdo da spec, liste o que você está assumindo:

```
PREMISSAS QUE ESTOU ASSUMINDO:
1. Esta é uma API serverless em Go (não um serviço em container)
2. Autenticação usa JWT do Cognito (não sessão em cookie)
3. O banco é DynamoDB com single-table design (baseado no schema existente)
4. Isolamento multi-tenant é feito por userID em toda query
-> Corrija agora ou seguirei com essas premissas.
```

Não preencha requisitos ambíguos em silêncio. O propósito inteiro da spec é expor mal-entendidos *antes* de o código ser escrito — premissas são a forma mais perigosa de mal-entendido.

**Escreva um documento de spec cobrindo estas seis áreas centrais:**

1. **Objetivo** — O que estamos construindo e por quê? Quem é o usuário? Como é o sucesso?

2. **Comandos** — Comandos executáveis completos, com flags, não apenas nomes de ferramentas.
   ```
   Build: make build
   Testes: make tests
   Formatação: make fmt
   Deploy local: make deploy-local
   E2E local: make deploy-and-local-tests
   ```

3. **Estrutura do Projeto** — Onde vive o código-fonte, onde ficam os testes, onde ficam os docs.
   ```
   cmd/             -> entrypoints (um por Lambda)
   internal/domain  -> entidades e regras de negócio
   internal/usecase -> casos de uso da aplicação
   internal/infra   -> adaptadores AWS (DynamoDB, Cognito, API Gateway)
   terraform/       -> infraestrutura como código
   docs/            -> spec, plano e estado do workflow
   ```

4. **Estilo de Código** — Um snippet real mostrando o estilo vale mais do que três parágrafos descrevendo-o. Inclua convenções de nomenclatura, regras de formatação e exemplos de saída boa.

5. **Estratégia de Testes** — Qual framework, onde os testes vivem, expectativas de cobertura, quais níveis de teste para quais preocupações.

6. **Limites** — Sistema de três níveis:
   - **Sempre fazer:** rodar os testes antes de commitar, seguir as convenções de nomenclatura, validar entradas
   - **Perguntar antes:** mudanças de schema, adicionar dependências, alterar configuração de CI
   - **Nunca fazer:** commitar segredos, editar diretórios vendorizados, remover testes falhando sem aprovação

**Modelo de spec:**

```markdown
# Spec: [Nome do Projeto/Funcionalidade]

## Objetivo
[O que estamos construindo e por quê. User stories ou critérios de aceitação.]

## Tech Stack
[Framework, linguagem, dependências principais com versões]

## Comandos
[Build, testes, lint, dev — comandos completos]

## Estrutura do Projeto
[Layout de diretórios com descrições]

## Estilo de Código
[Snippet de exemplo + convenções principais]

## Estratégia de Testes
[Framework, localização dos testes, requisitos de cobertura, níveis de teste]

## Limites
- Sempre: [...]
- Perguntar antes: [...]
- Nunca: [...]

## Critérios de Sucesso
[Como saberemos que está pronto — condições específicas e testáveis]

## Questões em Aberto
[Qualquer coisa não resolvida que precise de decisão humana]
```

**Reformule instruções como critérios de sucesso.** Ao receber requisitos vagos, traduza-os em condições concretas:

```
REQUISITO: "Deixe a API mais rápida"

CRITÉRIOS DE SUCESSO REFORMULADOS:
- Latência p99 dos endpoints de leitura < 200ms
- Cold start das Lambdas < 500ms
- Nenhuma query de listagem faz Scan no DynamoDB
-> Esses são os alvos corretos?
```

Isso permite iterar, tentar de novo e resolver problemas rumo a um objetivo claro, em vez de adivinhar o que "mais rápida" significa.

### Fase 2: Planejar

Com a spec validada, gere um plano técnico de implementação:

1. Identifique os componentes principais e suas dependências
2. Determine a ordem de implementação (o que precisa ser construído primeiro)
3. Anote riscos e estratégias de mitigação
4. Identifique o que pode ser construído em paralelo vs. o que é sequencial
5. Defina checkpoints de verificação entre as fases

> Siga `planning-and-task-breakdown` para a mecânica de mapeamento do grafo de dependências e fatiamento vertical por trás desses passos; ela é a fonte canônica. Os itens acima são um resumo leve; se divergirem, `planning-and-task-breakdown` prevalece.
>
> **Convenção de saída:** salve o plano em `/docs/plan.md` e a lista de tarefas em `/docs/tasks.md`, conforme a convenção do comando `/plan` e o contrato de `docs/workflow-state.md`. Os comandos seguintes (`/build`, `/resume`, etc.) esperam esses caminhos.

O plano deve ser revisável: o humano precisa conseguir lê-lo e dizer "sim, essa é a abordagem certa" ou "não, mude X".

### Fase 3: Tarefas

Quebre o plano em tarefas discretas e implementáveis:

- Cada tarefa deve ser concluível em uma única sessão focada
- Cada tarefa tem critérios de aceitação explícitos
- Cada tarefa inclui um passo de verificação (teste, build, checagem manual)
- Tarefas são ordenadas por dependência, não por importância percebida
- Nenhuma tarefa deve exigir mudar mais de ~5 arquivos

> Siga `planning-and-task-breakdown` para a mecânica completa de dimensionamento e ordenação por dependência; ela é a fonte canônica. O modelo abaixo é uma forma inline leve; se divergirem, `planning-and-task-breakdown` prevalece.

**Modelo de tarefa:**
```markdown
- [ ] Tarefa: [Descrição]
  - Aceitação: [O que precisa ser verdade quando terminar]
  - Verificar: [Como confirmar — comando de teste, build, checagem manual]
  - Arquivos: [Quais arquivos serão tocados]
```

### Fase 4: Implementar

Execute as tarefas uma de cada vez seguindo `incremental-implementation` e `test-driven-development`. Use `context-engineering` para carregar as seções certas da spec e os arquivos-fonte relevantes a cada passo, em vez de inundar o agente com a spec inteira.

## Mantendo a Spec Viva

A spec é um documento vivo, não um artefato de uma vez só:

- **Atualize quando decisões mudarem** — Se você descobrir que o modelo de dados precisa mudar, atualize a spec primeiro, depois implemente.
- **Atualize quando o escopo mudar** — Funcionalidades adicionadas ou cortadas devem refletir na spec.
- **Commite a spec** — A spec pertence ao controle de versão, ao lado do código.
- **Referencie a spec nos PRs** — Aponte cada PR para a seção da spec que ele implementa.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Isso é simples, não preciso de spec" | Tarefas simples não precisam de specs *longas*, mas ainda precisam de critérios de aceitação. Uma spec de duas linhas está ótima. |
| "Escrevo a spec depois de codificar" | Isso é documentação, não especificação. O valor da spec está em forçar clareza *antes* do código. |
| "A spec vai nos atrasar" | Uma spec de 15 minutos evita horas de retrabalho. Waterfall em 15 minutos vence debugging em 15 horas. |
| "Os requisitos vão mudar de qualquer jeito" | Por isso a spec é um documento vivo. Uma spec desatualizada ainda é melhor que nenhuma spec. |
| "O usuário sabe o que quer" | Mesmo pedidos claros carregam premissas implícitas. A spec expõe essas premissas. |

## Sinais de Alerta

- Começar a escrever código sem nenhum requisito escrito
- Perguntar "posso simplesmente começar a construir?" antes de esclarecer o que "pronto" significa
- Implementar funcionalidades que não constam em nenhuma spec ou lista de tarefas
- Tomar decisões arquiteturais sem documentá-las
- Pular a spec porque "é óbvio o que construir"

## Verificação

Antes de seguir para a implementação, confirme:

- [ ] A spec cobre as seis áreas centrais
- [ ] O humano revisou e aprovou a spec
- [ ] Os critérios de sucesso são específicos e testáveis
- [ ] Os limites (Sempre/Perguntar antes/Nunca) estão definidos
- [ ] A spec está salva em um arquivo no repositório (`/docs/spec.md`)
