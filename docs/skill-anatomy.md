# Anatomia de uma Skill

Este documento descreve o que torna um `SKILL.md` válido neste repositório. As regras aqui espelham o que o linter implementa — **a fonte da verdade é o código em [`scripts/lib/skill-lint.js`](../scripts/lib/skill-lint.js)**; se este documento e o linter divergirem, o linter vence e este documento deve ser atualizado.

Execute a validação com:

```bash
node scripts/validate-skills.js
```

## Estrutura de diretório

Cada skill vive em seu próprio diretório sob `skills/`, contendo um `SKILL.md`:

```
skills/
└── nome-da-skill/
    └── SKILL.md
```

Arquivos auxiliares (referências, exemplos, scripts) podem coexistir no diretório — apenas `SKILL.md` é validado.

## Convenções de nomenclatura

- O nome do diretório deve ser **lowercase-hyphen-separated** (kebab-case): `^[a-z0-9]+(-[a-z0-9]+)*$`.
- O campo `name` do frontmatter deve ser **idêntico** ao nome do diretório.

## Frontmatter (obrigatório)

Bloco YAML no topo do arquivo, delimitado por `---` (sem espaços à direita no delimitador):

```yaml
---
name: nome-da-skill
description: Faz X. Use quando Y acontecer ou ao fazer Z.
---
```

Regras:

| Campo | Regra |
|---|---|
| `name` | Obrigatório; igual ao nome do diretório |
| `description` | Obrigatória; máximo de **1024 caracteres** (agentes injetam esse texto no system prompt) |

### Gatilho de uso na description

A description deve dizer **o que a skill faz e quando usá-la**. O linter exige um gatilho explícito, aceitando as formas:

- `Use quando …` / `Use esta skill quando …`
- `Use ao …` / `Use antes …` / `Use durante …` / `Use depois …`

Formas **negadas** ("Não use quando…", "Nunca use ao…") descrevem exclusões, não gatilhos — não satisfazem a regra sozinhas.

## Seções obrigatórias

Todo `SKILL.md` padrão deve conter estes cinco headings de nível 2, no início de linha e fora de blocos de código (o linter remove fenced code blocks antes de verificar):

1. `## Visão Geral`
2. `## Quando Usar`
3. `## Racionalizações Comuns` (alias aceito: `## Justificativas Comuns`)
4. `## Sinais de Alerta`
5. `## Verificação`

## Isenções

Skills isentas das seções obrigatórias são listadas em `SECTION_EXEMPT_SKILLS` dentro de `scripts/lib/skill-lint.js` — **nunca no frontmatter da própria skill**. Declarar `type: meta` ou `exempt: sections` no frontmatter sem estar na allowlist do validador é erro (guarda anti-bypass: contribuidores não podem se auto-isentar).

Isenções vigentes (cada uma com motivo documentado no código):

| Skill | Motivo |
|---|---|
| `using-agent-skills` | Meta-skill de roteamento — "Quando Usar"/"Verificação" não se aplicam a um documento de descoberta |
| `idea-refine` | Estrutura legada anterior a este documento (How-It-Works/Usage/Anti-patterns) |
| `go-aws-serverless-development` | Skill local do fork — perfil de execução em camadas, sem anatomia Racionalizações/Sinais |
| `go-runtime-and-dependency-upgrades` | Skill local do fork — runbook de upgrade por fases, sem anatomia Racionalizações/Sinais |

## Referências cruzadas

Referências explícitas a outras skills (ex.: ``invoke the `nome-da-skill` skill``, ```nome` persona``, setas de diagramas `──→ nome`) são verificadas contra a lista de skills conhecidas. Referência morta gera **warning** (não bloqueia CI) — corrija o nome ou remova a referência.

## Resumo: erros vs warnings

| Tipo | Bloqueia CI | Exemplos |
|---|---|---|
| Erro | Sim | Frontmatter ausente/malformado, `name` divergente, description sem gatilho ou >1024 chars, seção obrigatória ausente, auto-isenção no frontmatter |
| Warning | Não | Referência cruzada para skill inexistente |
