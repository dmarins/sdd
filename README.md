# sdd

Skills de engenharia para agentes de IA — uso pessoal.

Fork de [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), traduzido e adaptado para o fluxo de trabalho diário.

---

## Fluxo de desenvolvimento

```
DEFINE        PLAN          BUILD         VERIFY        REVIEW        SHIP
/spec   →    /plan   →    /build   →    /test    →    /review  →    /ship
```

| Comando | Quando usar |
|---|---|
| `/spec` | Antes de codar qualquer feature nova — define objetivo, estrutura, testes e limites |
| `/plan` | Com a spec em mãos — quebra o trabalho em tasks com critérios de aceite |
| `/build` | Implementa a próxima task (TDD embutido: RED → GREEN → commit) |
| `/test` | Código legado sem cobertura, ou para isolar e reproduzir um bug |
| `/code-simplify` | Após o build — limpa sem mudar comportamento |
| `/review` | Antes de abrir o PR — revisão em 5 eixos (corretude, legibilidade, arquitetura, segurança, performance) |
| `/ship` | Antes de abrir o PR — checklist pré-deploy (seg, infra, monitoramento, rollback) |

> **CI/CD automático após merge:** `/review` e `/ship` são pré-requisitos do PR, não pós-merge.

---

## Entrando no meio do projeto

Se já existe uma spec informal ou tarefas planejadas:

1. Peça ao agente para converter o material existente em `SPEC.md` (formato da skill `spec-driven-development`)
2. Crie `tasks/todo.md` apenas para o escopo atual — não é necessário migrar tudo
3. A partir daí, `/build` funciona normalmente

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