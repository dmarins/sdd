# sdd

Skills de engenharia para agentes de IA — uso pessoal.

Fork de [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), traduzido e adaptado para o fluxo de trabalho diário.

---

## Setup do path global do Claude Code

Para adicionar os itens deste repositório dentro da estrutura global do Claude Code, rode:

```bash
bash scripts/setup-claude-links.sh
```

O script cria links simbólicos para os filhos diretos de `agents`, `commands`, `skills` e `hooks` em:

- `CLAUDE_CONFIG_DIR` (quando definido)
- fallback: `~/.claude`

Comportamento em colisões de nome no destino:

- sempre substitui o item existente por um novo symlink apontando para este repositório
- em `skills`, o symlink é feito no diretório da skill; `SKILL.md` e demais arquivos internos são incluídos automaticamente

Compatibilidade:

- Linux e macOS: usa `ln -s`
- Windows (Git Bash): tenta `ln -s` e faz fallback para `mklink` quando necessário
- Windows (WSL): usa fluxo Linux normal

Exemplo com destino customizado:

```bash
CLAUDE_CONFIG_DIR="$HOME/.claude" bash scripts/setup-claude-links.sh
```

Exemplo em modo simulação (sem alterar arquivos):

```bash
bash scripts/setup-claude-links.sh --dry-run
```

---

## Fluxo de desenvolvimento

```
DEFINE        PLAN          BUILD         VERIFY        REVIEW        SHIP
/spec   →    /plan   →    /build   →    /test    →    /review  →    /ship
					↘
					 /resume

/workflow = o pipeline inteiro num comando só, com roteamento a especialistas
            e gates de aprovação (você continua decidindo nos checkpoints)
```

| Comando | Quando usar |
|---|---|
| `/workflow` | Feature completa de ponta a ponta — orquestra DEFINE → ROUTE → ANALYZE → PLAN → gate de aprovação → BUILD (especialistas por task) → REVIEW → DOCUMENT. `/workflow auto` não para entre tasks; os demais gates permanecem |
| `/spec` | Antes de codar qualquer feature nova — define objetivo, estrutura, testes e limites |
| `/plan` | Com a spec em mãos — quebra o trabalho em tasks com critérios de aceite |
| `/build` | Implementa a próxima task (TDD embutido: RED → GREEN → commit; pode compor uma skill de perfil por stack). `/build auto` executa o plano inteiro após um único checkpoint de aprovação |
| `/learn` | Registra uma lição aprendida a partir de erro identificado manualmente ou por review, com promoção explícita quando a regra for global |
| `/resume` | Retoma uma implementação interrompida reconciliando `/docs` com o estado atual do Git |
| `/test` | Código legado sem cobertura, ou para isolar e reproduzir um bug |
| `/simplify` | Após o build — limpa sem mudar comportamento |
| `/review` | Antes de abrir o PR — revisão em 5 eixos (corretude, legibilidade, arquitetura, segurança, performance) |
| `/ship` | Antes de abrir o PR — fan-out paralelo para `code-reviewer` + `security-auditor` + `test-engineer`, merge em 6 dimensões e decisão GO/NO-GO com plano de rollback |
| `/webperf` | Auditoria de web performance (Core Web Vitals) via `web-performance-auditor` — apenas para aplicações web |

> **CI/CD automático após merge:** `/review` e `/ship` são pré-requisitos do PR, não pós-merge.

---

## Workflow típico de uso

### 1. Nova feature do zero

**Caminho de um comando:** rode `/workflow` e o pipeline inteiro executa com gates — ele pergunta o especialista (ROUTE), investiga o código-base (`codebase-analyst`), gera o plano, **para até você aprovar**, implementa task a task delegando a `serverless-backend`/`frontend-react`/`developer`, passa o diff pelo `code-reviewer` e documenta. Reinvocar `/workflow` após qualquer interrupção retoma da fase correta pelo estado em `/docs`.

Três garantias do pipeline que valem destacar:

- **Escritor único:** o especialista implementa e testa, mas quem verifica de forma independente (suíte completa + build), atualiza `/docs` e commita é o agente principal — um commit por task, rollback limpo garantido.
- **Review retroalimenta o build:** achados `Critical`/`Important` do `code-reviewer` viram fix-tasks e voltam à fase BUILD, com teto de 2 ciclos; persistindo achados, a decisão volta para você.
- **`/ship` nunca roda sozinho:** ao final, o `/workflow` arquiva os artefatos e apenas *recomenda* o `/ship` — o GO/NO-GO de produção continua seu.

**Caminho manual** (você orquestra cada fase):

1. Rode `/spec` para definir objetivo, limites, testes e restrições.
2. Rode `/plan` para quebrar a spec em tarefas pequenas e inicializar `/docs/spec.md`, `/docs/plan.md`, `/docs/tasks.md`, `/docs/handoff.md` e `/docs/lessons.md`.
3. Rode `/build` para implementar a task atual em incrementos pequenos.
4. Se precisar reproduzir bug ou reforçar cobertura, rode `/test`.
5. Quando a implementação estiver pronta, rode `/review`.
6. Se o review aprovar e o pacote estiver consistente, rode `/ship` antes do PR.

Sequência curta:

```text
/spec -> /plan -> /build -> /test (quando necessário) -> /review -> /ship
```

### 2. Trabalho interrompido ou sessão perdida

Use este caminho quando você bateu no limite da sessão, fechou o editor ou quer retomar depois:

1. Rode `/resume` para reidratar contexto a partir de `/docs` e do estado atual do Git.
2. Revise a task `IN_PROGRESS`, o handoff e as lições `OPEN` ou recentemente `PROMOTED`.
3. Continue com `/build` a partir do menor incremento verificável.

Sequência curta:

```text
/resume -> /build
```

### 3. Erro encontrado ou padrão ruim detectado

Use este caminho quando você ou o `/review` encontrarem um erro do agente, um desvio de convenção ou um gap de processo:

1. Confirme o erro com evidência clara.
2. Rode `/learn` com uma descrição explícita do erro para registrar a lição em `/docs/lessons.md`.
3. Se a lição for local, mantenha-a só no projeto.
4. Se a lição for global, o próprio fluxo de `/learn` promove a regra para skill, comando, instrução ou ADR com referência ao `lesson ID`.

Quando o erro vier do `/review`, o ideal é que o contexto levado ao `/learn` já inclua quatro coisas:

1. qual arquivo ou área foi afetado
2. o que foi feito de forma errada
3. como deveria ser
4. qual convenção, padrão ou regra do projeto foi violado

Sequência curta:

```text
/review -> /learn
```

Formato recomendado quando o achado vier do `/review`:

```text
/learn no review identificamos que o arquivo X foi alterado de forma errada; deveria seguir Y em vez de Z porque o projeto usa o padrão W
```

ou, quando o achado vier direto de você:

```text
identifique o erro -> /learn o arquivo X foi modificado de forma errada; precisava seguir Y em vez de Z
```

Exemplos úteis:

```text
/learn o arquivo handlers/create_task.go foi modificado fora do padrão do projeto; a validação deveria ficar no service, não no handler
```

```text
/learn o review encontrou duplicação de regra de negócio em dois endpoints; o correto era extrair para o caso de uso compartilhado
```

---

## Estado persistido em `/docs`

O workflow passa a usar uma única área persistida para sobreviver a troca de sessão, limite de assinatura e interrupções inesperadas:

| Arquivo | Função |
|---|---|
| `/docs/spec.md` | Especificação da feature ou do escopo atual |
| `/docs/plan.md` | Plano de implementação com fases, dependências e checkpoints |
| `/docs/tasks.md` | Lista de tarefas com status `TODO`, `IN_PROGRESS`, `BLOCKED` ou `DONE` |
| `/docs/handoff.md` | Estado operacional atual: task ativa, arquivos tocados, verificações rodadas, blockers e próximo passo |
| `/docs/lessons.md` | Lições aprendidas a partir de erros, achados de review e gaps de processo, com promoção rastreável para skills ou comandos |

`/build` e `/review` podem gerar candidatos a lição. `/learn` registra a lição explicitamente em `/docs/lessons.md` e, quando ela for generalizável, promove a regra para o artefato certo. `/resume` usa esses artefatos para reconstruir o contexto e continuar com o menor retrabalho possível.

Quando dirigido pelo `/workflow`, o `plan.md` carrega o marker de aprovação (`> Status: DRAFT|APPROVED`), o handoff registra a `## Fase do workflow`, e o encerramento arquiva spec/plan/tasks em `/docs/archive/`. Detalhes em `docs/workflow-state.md`.

### Caminhos rápidos (o pipeline não é obrigação)

O `/workflow` é a esteira completa, não uma imposição — todos os caminhos abaixo continuam válidos. O rigor de teste e verificação é invariante em todos eles (não existe um knob `quality=pragmatic|balanced|strict` como em outros sistemas de pipeline); o que varia é **quanto de julgamento humano entra entre os passos**:

| Se você quer | Use |
|---|---|
| Mudança rápida e pequena, controle máximo | `/build` (uma task, para) |
| Executar um plano inteiro com um único gate | `/build auto` |
| Pipeline completo com especialistas e gates | `/workflow` |
| Pipeline completo parando só em alto risco | `/workflow auto` |
| Uma perspectiva pontual sobre um artefato | Invocação direta da persona (`code-reviewer`, `security-auditor`…) |
| Pular o fan-out do `/ship` | Permitido só para ≤2 arquivos, <50 linhas, sem tocar auth/pagamentos/dados/config |

---

## Loop de Aprendizado

Quando você identificar um erro do agente manualmente ou durante o `/review`, o fluxo recomendado é:

1. Confirmar o erro ou antipadrão com evidência clara
2. Acionar `/learn` com uma descrição objetiva do erro, do correto e, quando possível, do arquivo ou padrão afetado
3. Classificar se a lição é apenas local ao projeto ou se ela revela um gap de processo ou skill
4. Se a lição for global, atualizar imediatamente a skill, comando ou instrução correspondente com referência ao `lesson ID`

Esse loop não é silencioso: a promoção de uma lição para guidance persistido só acontece quando você aciona `/learn` ou quando aceita uma sugestão explícita surgida no `/review`.

---

## Entrando no meio do projeto

Se já existe uma spec informal ou tarefas planejadas:

1. Peça ao agente para converter o material existente em `/docs/spec.md` (formato da skill `spec-driven-development`)
2. Estruture o plano em `/docs/plan.md` e as tarefas em `/docs/tasks.md` apenas para o escopo atual — não é necessário migrar tudo
3. Inicialize `/docs/handoff.md` com o contexto corrente, mesmo que haja trabalho parcial já em andamento
4. Inicialize `/docs/lessons.md` para registrar lições desde a primeira iteração do trabalho
5. A partir daí, `/build`, `/learn` e `/resume` funcionam normalmente

---

## Skills disponíveis

### Define
| Skill | Uso |
|---|---|
| `interview-me` | Extrair o que o usuário realmente quer, uma pergunta por vez, antes de qualquer plano |
| `idea-refine` | Refinar uma ideia vaga antes de escrever a spec |
| `spec-driven-development` | Escrever spec antes de qualquer código (SPECIFY → PLAN → TASKS → IMPLEMENT) |

### Plan
| Skill | Uso |
|---|---|
| `planning-and-task-breakdown` | Decompor a spec em tasks implementáveis |

### Build
| Skill | Uso |
|---|---|
| `incremental-implementation` | Fatias verticais — implementar, testar, commitar |
| `test-driven-development` | RED → GREEN → Refactor, pirâmide de testes |
| `context-engineering` | Alimentar o agente com o contexto certo no momento certo |
| `source-driven-development` | Decisões baseadas na documentação oficial (com citação de fonte) |
| `doubt-driven-development` | Revisão adversarial de contexto limpo para decisões não triviais, com escalação cross-model opcional |
| `frontend-ui-engineering` | Componentes, design system, acessibilidade WCAG 2.1 AA |
| `api-and-interface-design` | Design contract-first, semântica de erros, validação de boundary |
| `go-aws-serverless-development` | Perfil de execução para projetos Go + AWS + Terraform sem inflar o comando `build` |

### Verify
| Skill | Uso |
|---|---|
| `browser-testing-with-devtools` | Inspecionar DOM, rede e performance via Chrome DevTools MCP |
| `debugging-and-error-recovery` | Triagem em 5 etapas: reproduzir → localizar → reduzir → corrigir → guardar |

### Review
| Skill | Uso |
|---|---|
| `code-review-and-quality` | Revisão em 5 eixos antes do merge |
| `code-simplification` | Reduzir complexidade sem mudar comportamento |
| `security-and-hardening` | OWASP Top 10, auth, segredos, dependências |
| `performance-optimization` | Core Web Vitals, profiling, bundle, anti-patterns |
| `pr-review-comments` | Processar comentários de revisão de PR criticamente e com segurança |

### Ship
| Skill | Uso |
|---|---|
| `git-workflow-and-versioning` | Trunk-based, commits atômicos, change sizing |
| `ci-cd-and-automation` | Pipelines, quality gates, feature flags |
| `deprecation-and-migration` | Remoção de sistemas legados, migrações |
| `documentation-and-adrs` | ADRs — documentar o *porquê*, não o *o quê* |
| `observability-and-instrumentation` | Logs estruturados, métricas RED, tracing e alertas por sintoma (Go/AWS) |
| `shipping-and-launch` | Checklist completo pré-deploy |

### Maintenance
| Skill | Uso |
|---|---|
| `go-runtime-and-dependency-upgrades` | Workflow de manutenção para upgrade de runtime Go, módulos e superfícies associadas como CI, Docker e runtime |

---

## Agentes especialistas

Invocados explicitamente quando você quer uma perspectiva mais focada:

| Agente | Quando usar |
|---|---|
| `code-reviewer` | Revisão profunda como Staff Engineer |
| `test-engineer` | Estratégia de testes e análise de cobertura |
| `security-auditor` | Auditoria de segurança, modelagem de ameaças (inclui funcionalidades de IA/LLM) |
| `web-performance-auditor` | Auditoria de Core Web Vitals e antipadrões de performance em web apps |
| `serverless-backend` | Especialista em Go + AWS + Terraform para componentes serverless |
| `frontend-react` | Especialista em React 18 + TypeScript + Vite + TanStack Query para UI |
| `codebase-analyst` | Levantamento read-only do código-base antes de planejar (fase ANALYZE do `/workflow`) |
| `developer` | Fallback generalista para tasks fora dos domínios especializados |

```
use code-reviewer to review my last commit
use security-auditor to audit src/auth/
```

Como personas, skills e comandos se compõem — e os padrões de orquestração endossados — está documentado em `docs/agents.md` e `references/orchestration-patterns.md`.

---

## Hooks (Claude Code)

| Hook | O que faz |
|---|---|
| `session-start` | Injeta a meta-skill `using-agent-skills` automaticamente no início de cada sessão |
| `sdd-cache` | Cache HTTP com revalidação ETag para `source-driven-development` — evita fetches redundantes |
| `simplify-ignore` | Protege blocos marcados com `/* simplify-ignore-start */` durante o `/simplify` |

---

## Validação

```bash
node scripts/validate-skills.js      # valida frontmatter, seções e referências cruzadas de todas as skills
bash hooks/session-start-test.sh     # valida o payload JSON do hook de início de sessão
bash hooks/simplify-ignore-test.sh   # valida o hook de proteção de blocos
```

---

## Referências rápidas

- `references/accessibility-checklist.md`
- `references/definition-of-done.md`
- `references/observability-checklist.md`
- `references/orchestration-patterns.md`
- `references/performance-checklist.md`
- `references/security-checklist.md`
- `references/testing-patterns.md`