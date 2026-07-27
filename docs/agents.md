# Personas de Agente

Personas especialistas que exercem um único papel com uma única perspectiva. Cada persona é um arquivo Markdown consumido como system prompt pelo seu harness (Claude Code, Cursor, Copilot, etc.).

| Persona | Papel | Melhor para |
|---------|------|----------|
| [code-reviewer](../agents/code-reviewer.md) | Engenheiro Staff Sênior | Revisão em cinco eixos antes do merge |
| [security-auditor](../agents/security-auditor.md) | Engenheiro de Segurança | Detecção de vulnerabilidades, auditoria estilo OWASP |
| [test-engineer](../agents/test-engineer.md) | Engenheiro de QA | Estratégia de testes, análise de cobertura, padrão Prove-It |
| [web-performance-auditor](../agents/web-performance-auditor.md) | Engenheiro de Web Performance | Auditoria de Core Web Vitals, análise de loading/rendering/rede |
| [serverless-backend](../agents/serverless-backend.md) | Especialista Serverless AWS (local do fork) | Projetar, implementar e depurar componentes serverless em Go/AWS/Terraform |

## Como personas se relacionam com skills e comandos

Três camadas, cada uma com um trabalho distinto:

| Camada | O que é | Exemplo | Papel na composição |
|-------|-----------|---------|------------------|
| **Skill** | Um workflow com passos e critérios de saída | `code-review-and-quality` | O *como* — invocada de dentro de uma persona ou comando |
| **Persona** | Um papel com uma perspectiva e um formato de saída | `code-reviewer` | O *quem* — adota um ponto de vista, produz um relatório |
| **Comando** | Um ponto de entrada voltado ao usuário | `/review`, `/ship` | O *quando* — compõe personas e skills |

O usuário (ou um slash command) é o orquestrador. **Personas não chamam outras personas.** Skills são paradas obrigatórias dentro do workflow de uma persona.

## Quando usar cada um

### Invocação direta de persona
Escolha quando quiser uma perspectiva sobre a mudança atual e o usuário estiver no circuito.

- "Revise este PR" → invoque `code-reviewer` diretamente
- "Há problemas de segurança em `auth.go`?" → invoque `security-auditor` diretamente
- "Quais testes faltam no fluxo de checkout?" → invoque `test-engineer` diretamente
- "Audite os Core Web Vitals da página de produto" → invoque `web-performance-auditor` diretamente

### Slash command (uma persona por trás)
Escolha quando existe um workflow repetível que você reexplicaria toda vez.

- `/review` → embrulha `code-reviewer` com a skill de revisão do projeto
- `/test` → embrulha `test-engineer` com a skill de TDD
- `/webperf` → embrulha `web-performance-auditor` para auditorias de performance em web apps

### Slash command (orquestrador — fan-out)
Escolha apenas quando investigações **independentes** podem rodar em paralelo e produzir relatórios que um único agente então mescla.

- `/ship` → faz fan-out para `code-reviewer` + `security-auditor` + `test-engineer` em paralelo, depois sintetiza os relatórios em uma decisão go/no-go

Este é o único padrão de orquestração que este repositório endossa. Veja [references/orchestration-patterns.md](../references/orchestration-patterns.md) para o catálogo completo de padrões e antipadrões.

## Matriz de decisão

```
O trabalho é uma perspectiva sobre um artefato?
├── Sim → Invocação direta de persona
└── Não → As subtarefas são independentes (sem estado mutável compartilhado, sem ordem)?
         ├── Sim → Slash command com fan-out paralelo (ex.: /ship)
         └── Não → Slash commands sequenciais rodados pelo usuário (/spec → /plan → /build → /test → /review)
```

## Exemplo trabalhado: orquestração válida

O `/ship` é o orquestrador fan-out canônico deste repositório:

```
/ship
  ├── (paralelo) code-reviewer    → relatório de revisão
  ├── (paralelo) security-auditor → relatório de auditoria
  └── (paralelo) test-engineer    → relatório de cobertura
                  ↓
        fase de merge (agente principal)
                  ↓
        decisão go/no-go + plano de rollback
```

Por que funciona:
- Cada subagente opera sobre o mesmo diff mas produz uma **perspectiva diferente**
- Não têm dependências entre si → paralelismo genuíno, ganho real de tempo de relógio
- Cada um roda em uma janela de contexto limpa → a sessão principal permanece organizada
- O passo de merge é pequeno e se beneficia do contexto completo, então fica no agente principal

## Exemplo trabalhado: orquestração inválida (não construa isto)

Uma persona `meta-orchestrator` cujo trabalho é "decidir qual outra persona chamar":

```
/work-on-pr → meta-orchestrator
                  ↓ (decide "isto precisa de review")
              code-reviewer
                  ↓ (retorna)
              meta-orchestrator (parafraseia o resultado)
                  ↓
              usuário
```

Por que falha:
- Camada de roteamento pura, sem valor de domínio
- Adiciona dois saltos de paráfrase → perda de informação + 2× o custo de tokens
- O usuário já sabe que quer um review; deixe-o chamar `/review` diretamente
- Replica o trabalho que os slash commands e o mapeamento de intenção do README já fazem

## Regras para personas

1. Uma persona é um único papel com um único formato de saída. Se você se pegar adicionando um segundo papel, crie uma segunda persona.
2. **Personas não invocam outras personas.** Composição é trabalho dos slash commands ou do usuário. No Claude Code isso também é uma restrição rígida da plataforma — *"subagentes não podem iniciar outros subagentes"* — então a regra é imposta por você.
3. Uma persona pode invocar skills (o *como*).
4. Todo arquivo de persona termina com um bloco "Composição" declarando onde ela se encaixa.

## Interoperabilidade com o Claude Code

As personas deste repositório foram projetadas para funcionar como subagentes do Claude Code e como colegas de Agent Teams sem modificação:

- **Como subagentes:** disponíveis após rodar `scripts/setup-claude-links.sh` (que cria os symlinks em `~/.claude/agents/`). Use a ferramenta Agent com `subagent_type: code-reviewer` (ou `security-auditor`, `test-engineer`). O `/ship` é o exemplo canônico.
- **Como colegas de Agent Teams** (experimental, requer `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`): referencie o mesmo nome de persona ao iniciar um colega. O corpo da persona é **anexado ao** system prompt do colega como instruções adicionais (não uma substituição), então o texto da persona fica por cima das instruções de coordenação de time que o líder instala (SendMessage, ferramentas de lista de tarefas, etc.).

Subagentes apenas reportam resultados de volta ao agente principal. Agent Teams permitem que colegas troquem mensagens diretamente. Use subagentes quando relatórios bastam; use Agent Teams quando os subagentes precisam contestar os achados uns dos outros (ex.: depuração com hipóteses concorrentes). Veja [references/orchestration-patterns.md](../references/orchestration-patterns.md) para o mapeamento completo.

Agents de plugin não suportam frontmatter `hooks`, `mcpServers` ou `permissionMode` — esses campos são silenciosamente ignorados. Evite depender deles ao criar personas novas aqui.

## Adicionando uma nova persona

1. Crie `agents/<papel>.md` com o mesmo formato de frontmatter das personas existentes.
2. Defina o papel, o escopo, o formato de saída e as regras.
3. Adicione um bloco **Composição** ao final (Invoque diretamente quando / Invoque via / Não invoque a partir de outra persona).
4. Adicione a persona à tabela no topo deste arquivo.
5. Se a persona habilitar um novo padrão de orquestração, documente-o em `references/orchestration-patterns.md` em vez de inventar o padrão no próprio arquivo da persona.
