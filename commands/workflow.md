---
description: Execute o pipeline completo DEFINE → PLAN → BUILD → REVIEW → DOCUMENT com roteamento a especialistas e gates de aprovação humana. Adicione "auto" para não parar entre tasks após a aprovação do plano.
---

Você é o orquestrador de um pipeline de especialistas. Você roteia, mantém o estado, verifica e conversa com o usuário; os subagentes analisam e implementam. Regras invioláveis:

- Subagentes não iniciam subagentes e não conversam com o usuário — **todo gate humano acontece aqui**, entre invocações.
- O contexto flui por `/docs/*.md` e pelo prompt de cada subagente — nunca por paráfrase de um resultado de subagente para outro.
- Você é o **único escritor** de `/docs` e o único que commita.

`$ARGUMENTS`: `auto` (ou `all`) remove a parada entre tasks na fase BUILD — os demais gates permanecem. Qualquer outro valor (ou vazio) é o modo padrão.

## Determinação de fase (sempre execute primeiro)

Leia `/docs/spec.md`, `/docs/plan.md`, `/docs/tasks.md`, `/docs/handoff.md`, `/docs/lessons.md` e `git status`. Entre na **primeira fase incompleta** — reinvocar `/workflow` sempre retoma de onde parou, pelo estado dos arquivos, nunca de memória:

| Condição em `/docs` | Fase |
|---|---|
| `spec.md` não existe | DEFINE |
| `spec.md` existe, `plan.md` não existe | ROUTE → ANALYZE → PLAN |
| `plan.md` com `> Status: DRAFT` | GATE — reapresente o plano e peça aprovação |
| `plan.md` com `> Status: APPROVED` + tasks `TODO`/`IN_PROGRESS` | BUILD |
| todas as tasks `DONE`, handoff sem `REVIEW_DONE` | REVIEW |
| review limpo (`REVIEW_DONE` no handoff) | DOCUMENT → encerramento |

Se `/docs` e o Git divergirem (ex.: task `DONE` sem commit correspondente), pare e resolva a divergência com o usuário antes de qualquer fase — mesma regra do `/resume`.

## Fase DEFINE

Invoque a skill `spec-driven-development` (comportamento do `/spec`): perguntas de clarificação, spec estruturada nas seis áreas, salvar em `/docs/spec.md` e confirmar com o usuário antes de prosseguir.

## Fase ROUTE

Classifique o trabalho pela tabela de sinais da seção **Delegação por tipo de trabalho** do `/build` (backend → `serverless-backend`, frontend → `frontend-react`, mista → ambas por trecho, geral → inline/`developer`).

Apresente a sugestão ao usuário e **pergunte**: confirma, troca de especialista ou cancela. Não prossiga sem resposta. Registre a decisão na seção `## Roteamento` de `/docs/plan.md` (crie o arquivo se ainda não existir).

## Fase ANALYZE

Inicie o subagente `codebase-analyst` com: o conteúdo de `/docs/spec.md`, a decisão de roteamento e a instrução de devolver o `## Relatório de Análise` no formato padrão da persona.

Persista o relatório como seção `## Contexto do código-base` em `/docs/plan.md` — não crie um sexto arquivo de estado.

## Fase PLAN

Invoque a skill `planning-and-task-breakdown` com a spec e a análise como entrada (mesmo contrato do `/plan`): tasks verticais em `/docs/tasks.md`, cada uma **já classificada** (backend/frontend/mista/geral) com a persona ou execução inline anotada; inicialize `handoff.md` e `lessons.md` se não existirem.

Grave `> Status: DRAFT` na primeira linha após o título de `/docs/plan.md`.

## GATE de aprovação

Apresente o plano completo e aguarde uma afirmativa inequívoca (ex.: "aprovo", "pode ir", "sim"). Trate respostas hesitantes ("parece razoável", "acho que sim") como **não** aprovadas — mesma regra do `/build auto`.

Ao aprovar:
1. Mude o marker para `> Status: APPROVED (AAAA-MM-DD)`.
2. Commite os artefatos de planejamento (`/docs/{spec,plan,tasks,handoff,lessons}.md`) num único commit preparatório, para que não vazem para o commit da primeira task.

Se o usuário pedir mudanças, ajuste o plano, mantenha `DRAFT` e reapresente.

## Fase BUILD

Para cada task, em ordem de dependência, siga o protocolo da seção **Delegação a subagente** do `/build`:

1. Marque `IN_PROGRESS` em `/docs/tasks.md` e atualize o handoff (objetivo, classificação, persona ou inline).
2. **Inline** (task geral, ou ≤2 arquivos com <50 linhas previstas): execute você mesmo o loop padrão do `/build` (RED → GREEN → regressão → build).
3. **Delegada:** inicie o subagente da persona roteada com o bloco da task, o trecho relevante do `## Contexto do código-base`, as lições `OPEN` relevantes e a instrução de seguir `incremental-implementation` + `test-driven-development` (+ skill de domínio), rodar testes e build e reportar — **sem commitar e sem editar `/docs`**.
4. **Verifique de forma independente:** rode a suíte completa e a build você mesmo antes de aceitar o relatório. Divergência entre relatório e verificação → task `BLOCKED`, siga `debugging-and-error-recovery`.
5. Atualize `tasks.md` (`DONE`) e `handoff.md`, registre candidatos a lição (recomendando `/learn`) e commite **apenas os arquivos da task** — nunca `git add -A`.
6. **Modo padrão:** pare após cada task e mostre o resultado. **Modo `auto`:** siga direto, mas pare e pergunte nos mesmos casos obrigatórios do `/build auto`: teste/build quebrado sem correção óbvia, spec ambígua, ou task de alto risco/irreversível → siga `doubt-driven-development` e obtenha aprovação explícita.

## Fase REVIEW

1. Inicie o subagente `code-reviewer` sobre o diff acumulado do pipeline (do commit preparatório ao HEAD), pedindo o relatório em Critical/Important/Sugestão.
2. Achados `Critical` ou `Important` → crie fix-tasks em `/docs/tasks.md` (classificadas como qualquer outra task) e **volte à fase BUILD**.
3. Máximo de **3 ciclos** review→fix. Se o quarto review ainda tiver achados Critical/Important, pare e devolva a decisão ao usuário.
4. Review limpo (ou só Sugestões): registre `REVIEW_DONE` na seção `## Fase do workflow` do handoff.

## Fase DOCUMENT

Execute inline — esta fase precisa do contexto completo da sessão:

1. Invoque a skill `documentation-and-adrs`: se houve decisão arquitetural, escreva o ADR; escreva o resumo de sessão no `handoff.md` (mudanças, decisões técnicas com racional, recursos criados).
2. Invoque a skill `git-workflow-and-versioning` para garantir histórico limpo (commits atômicos já feitos por task).
3. Recomende `/learn` para cada candidato a lição acumulado no handoff — não registre lições silenciosamente.

## Encerramento

1. Arquive `/docs/spec.md`, `/docs/plan.md` e `/docs/tasks.md` em `/docs/archive/AAAA-MM-DD-<slug-da-feature>/` — sem isso, a spec antiga faria o próximo `/workflow` pular a fase DEFINE.
2. Resete `/docs/handoff.md` para o estado vazio (task ativa: Nenhuma). `lessons.md` permanece — é acumulativo.
3. Commite o arquivamento.
4. **Recomende** `/ship` para o gate final de produção — não o execute: GO/NO-GO é decisão do usuário, e o `/ship` é um orquestrador fan-out por conta própria.
5. Resuma: tasks concluídas, testes adicionados, commits, ciclos de review, lições candidatas e qualquer coisa deixada para o usuário.
