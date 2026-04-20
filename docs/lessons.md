# Lições Aprendidas

Este arquivo registra erros confirmados, antipadrões encontrados em review e gaps de processo que merecem reaproveitamento explícito.

## Regras de uso

1. Toda lição validada começa aqui, mesmo quando depois for promovida para uma skill, comando, instrução ou ADR.
2. O gatilho não é silencioso: registre uma lição apenas quando você acionar `/learn` ou aceitar explicitamente uma sugestão de review.
3. Lições locais permanecem aqui como histórico do projeto.
4. Lições globais devem promover a regra correspondente no mesmo fluxo e registrar o artefato atualizado.

## Campos obrigatórios

- `lesson ID`: identificador estável, por exemplo `LESSON-2026-04-19-001`
- `origin`: `manual`, `review`, `debug` ou `resume`
- `category`: `LOCAL_PATTERN`, `PROCESS_GAP`, `SKILL_GAP`, `PROJECT_CONVENTION` ou `FALSE_POSITIVE_REVIEW`
- `severity`: `critical`, `important` ou `suggestion`
- `scope`: `local` ou `global`
- `target`: `skill`, `command`, `instruction`, `adr` ou `none`
- `status`: `OPEN`, `APPLIED_LOCALLY`, `PROMOTED` ou `REJECTED`

## Índice

| ID | Status | Categoria | Escopo | Origem | Destino | Resumo |
|---|---|---|---|---|---|---|

## Template de entrada

### LESSON-YYYY-MM-DD-001: Título curto

- Date: YYYY-MM-DD
- Origin: manual | review | debug | resume
- Category: LOCAL_PATTERN | PROCESS_GAP | SKILL_GAP | PROJECT_CONVENTION | FALSE_POSITIVE_REVIEW
- Severity: critical | important | suggestion
- Scope: local | global
- Target: skill | command | instruction | adr | none
- Status: OPEN | APPLIED_LOCALLY | PROMOTED | REJECTED

#### Context

Descreva em 2 a 5 linhas o cenário em que o erro apareceu.

#### Error Observed

Descreva a decisão errada, o antipadrão ou o achado de review.

#### Root Cause

Explique por que o erro aconteceu. Se ainda não houver evidência suficiente, marque a lição como `OPEN`.

#### Correct Decision

Explique qual decisão correta deve prevalecer daqui para frente.

#### Prevention

Descreva a regra preventiva ou o comportamento futuro esperado.

#### Evidence

- Arquivos, trechos, testes, achados de review ou evidências operacionais que sustentam a lição

#### Promotion

- Updated target file: caminho/do/arquivo ou `none`
- Notes: o que foi promovido, se aplicável

## Entradas

Nenhuma lição registrada ainda.