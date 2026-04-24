# sdd

Skills de engenharia para agentes de IA — uso pessoal.

Fork de [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), traduzido e adaptado para o fluxo de trabalho diário.

---

## Setup do path global do Claude Code

Para adicionar os itens deste repositório dentro da estrutura global do Claude Code, rode:

```bash
bash scripts/setup-claude-links.sh
```

O script cria links simbólicos para os filhos diretos de `agents`, `commands` e `skills` em:

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
```

| Comando | Quando usar |
|---|---|
| `/spec` | Antes de codar qualquer feature nova — define objetivo, estrutura, testes e limites |
| `/plan` | Com a spec em mãos — quebra o trabalho em tasks com critérios de aceite |
| `/build` | Implementa a próxima task (TDD embutido: RED → GREEN → commit; pode compor uma skill de perfil por stack) |
| `/learn` | Registra uma lição aprendida a partir de erro identificado manualmente ou por review, com promoção explícita quando a regra for global |
| `/resume` | Retoma uma implementação interrompida reconciliando `/docs` com o estado atual do Git |
| `/test` | Código legado sem cobertura, ou para isolar e reproduzir um bug |
| `/code-simplify` | Após o build — limpa sem mudar comportamento |
| `/review` | Antes de abrir o PR — revisão em 5 eixos (corretude, legibilidade, arquitetura, segurança, performance) |
| `/ship` | Antes de abrir o PR — checklist pré-deploy (seg, infra, monitoramento, rollback) |

> **CI/CD automático após merge:** `/review` e `/ship` são pré-requisitos do PR, não pós-merge.

---

## Workflow típico de uso

### 1. Nova feature do zero

Use este caminho quando a feature ainda não tem spec nem plano:

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
| `idea-refine` | Refinar uma ideia vaga antes de escrever a spec |
| `spec-driven-development` | Escrever spec antes de qualquer código |

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

### Ship
| Skill | Uso |
|---|---|
| `git-workflow-and-versioning` | Trunk-based, commits atômicos, change sizing |
| `ci-cd-and-automation` | Pipelines, quality gates, feature flags |
| `deprecation-and-migration` | Remoção de sistemas legados, migrações |
| `documentation-and-adrs` | ADRs — documentar o *porquê*, não o *o quê* |
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
| `security-auditor` | Auditoria de segurança, modelagem de ameaças |

```
use code-reviewer to review my last commit
use security-auditor to audit src/auth/
```

---

## Hooks (Claude Code)

| Hook | O que faz |
|---|---|
| `session-start` | Injeta a meta-skill `using-agent-skills` automaticamente no início de cada sessão |
| `sdd-cache` | Cache HTTP com revalidação ETag para `source-driven-development` — evita fetches redundantes |
| `simplify-ignore` | Protege blocos marcados com `/* simplify-ignore-start */` durante o `/code-simplify` |

---

## Referências rápidas

- `references/accessibility-checklist.md`
- `references/performance-checklist.md`
- `references/security-checklist.md`
- `references/testing-patterns.md`