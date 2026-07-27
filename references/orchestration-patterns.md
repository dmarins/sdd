# Padrões de Orquestração

Catálogo de referência dos padrões de orquestração de agentes que este repositório endossa, mais os antipadrões a evitar. Leia isto antes de adicionar um novo slash command que coordene múltiplas personas, ou antes de introduzir uma nova persona que "embrulhe" personas existentes.

A regra governante: **o usuário (ou um slash command) é o orquestrador. Personas não invocam outras personas.** Skills são paradas obrigatórias dentro do workflow de uma persona.

---

## Padrões endossados

### 1. Invocação direta (sem orquestração)

Uma persona, uma perspectiva, um artefato. O padrão default e a opção mais barata.

```
usuário → code-reviewer → relatório → usuário
```

**Use quando:** o trabalho é uma perspectiva sobre um artefato e você consegue descrevê-lo em uma frase.

**Exemplos:**
- "Revise este PR" → `code-reviewer`
- "Encontre problemas de segurança em `auth.go`" → `security-auditor`
- "Quais testes faltam no fluxo de checkout?" → `test-engineer`

**Custo:** uma ida e volta. A linha de base contra a qual você deve sempre comparar os padrões orquestrados.

---

### 2. Slash command de persona única

Um slash command que embrulha uma persona com as skills do projeto. Poupa o usuário de reexplicar o workflow toda vez.

```
/review → code-reviewer (com a skill code-review-and-quality) → relatório
```

**Use quando:** a mesma invocação de persona única acontece repetidamente com a mesma configuração.

**Exemplos neste repositório:** `/review`, `/test`, `/simplify`.

**Custo:** igual ao da invocação direta. O slash command é só um prompt salvo.

**Antissinal:** se o corpo do slash command é majoritariamente "decidir qual persona chamar", delete-o e deixe o usuário chamar a persona diretamente.

---

### 3. Fan-out paralelo com merge

Múltiplas personas operam sobre a mesma entrada em paralelo, cada uma produzindo um relatório independente. Um passo de merge (no contexto do agente principal) as sintetiza em uma única decisão.

```
                    ┌─→ code-reviewer    ─┐
/ship → fan out  ───┼─→ security-auditor ─┤→ merge → go/no-go + rollback
                    └─→ test-engineer    ─┘
```

**Use quando:**
- As subtarefas são genuinamente independentes (sem estado mutável compartilhado, sem dependência de ordem)
- Cada subagente se beneficia da própria janela de contexto
- O passo de merge é pequeno o suficiente para caber no contexto principal
- A latência de relógio importa

**Exemplos neste repositório:** `/ship`.

**Custo:** N contextos de subagente em paralelo + um turno de merge. Mais alto que invocação direta, mas mais rápido em relógio e com relatórios melhores, porque cada subagente permanece focado em sua única perspectiva.

**Checklist de validação antes de adotar este padrão:**
- [ ] Consigo rodar todos os subagentes ao mesmo tempo sem problemas de ordem?
- [ ] Cada persona produz um *tipo* diferente de achado, e não o mesmo achado por outro ângulo?
- [ ] O passo de merge caberá no contexto restante do agente principal?
- [ ] O tempo de espera do usuário é longo o suficiente para o paralelismo ser de fato perceptível?

Se qualquer resposta for "não", recue para invocação direta ou para um comando de persona única.

---

### 4. Pipeline sequencial como slash commands dirigidos pelo usuário

O usuário roda slash commands em uma ordem definida, carregando contexto (ou histórico de commits) entre eles. Não há agente orquestrador — o usuário É o orquestrador.

```
usuário roda:  /spec  →  /plan  →  /build  →  /test  →  /review  →  /ship
```

**Use quando:** o workflow tem dependências (cada passo precisa da saída do anterior) e o julgamento humano entre os passos agrega valor.

**Exemplos neste repositório:** o ciclo de vida inteiro DEFINIR → PLANEJAR → CONSTRUIR → VERIFICAR → REVISAR → ENTREGAR.

**Custo:** um contexto de subagente por passo. Gratuito na camada de orquestração porque não há agente orquestrador.

**Por que não automatizar:** um "orquestrador de ciclo de vida" LLM iria (a) perder nuance entre passos porque precisa resumir para o hand-off, (b) pular os checkpoints humanos que capturam trabalho na direção errada cedo, e (c) dobrar o custo de tokens com turnos de paráfrase.

---

### 5. Isolamento de pesquisa (preservação de contexto)

Quando uma tarefa exige ler grandes volumes de material que não deveriam poluir o contexto principal, inicie um subagente de pesquisa que retorna apenas um resumo.

```
agente principal → subagente de pesquisa (lê 50 arquivos) → resumo → agente principal continua
```

**Use quando:**
- A sessão principal precisa permanecer focada em uma tarefa a jusante
- O resultado da investigação é muito menor que a entrada que ela consome
- A qualidade da decisão se beneficia de o agente principal ter espaço para pensar depois

**Exemplos:** "Encontre todos os call sites desta API descontinuada no monorepo", "Resuma o que estes 30 ADRs dizem sobre caching".

**Custo:** um contexto isolado de subagente. Vale a pena sempre que a alternativa é carregar centenas de arquivos no contexto principal.

**No Claude Code, use o subagente embutido `Explore`** em vez de definir uma persona de pesquisa customizada. O `Explore` roda em Haiku, tem ferramentas de escrita/edição negadas e foi construído para este padrão. Defina um subagente de pesquisa customizado apenas quando o `Explore` não servir (ex.: você precisa de um system prompt específico de domínio que o modelo não inferiria).

---

## Compatibilidade com o Claude Code

Este catálogo é agnóstico de harness, mas a maioria dos leitores o rodará no Claude Code. Eis como cada padrão mapeia para as primitivas do Claude Code — e onde a plataforma impõe as nossas regras por nós.

### Onde as personas vivem

Neste repositório, as personas ficam em `agents/` na raiz e são disponibilizadas ao Claude Code via symlinks criados por `scripts/setup-claude-links.sh` (que aponta `~/.claude/agents/` para os arquivos daqui). `agents/code-reviewer.md`, `agents/security-auditor.md` e `agents/test-engineer.md` são descobertos automaticamente após o setup.

### Subagentes vs. Agent Teams

O Claude Code tem duas primitivas de paralelismo. O Padrão 3 (fan-out paralelo com merge) mapeia para **subagentes**. Se você precisa de colegas que conversem entre si, use **Agent Teams**.

| | Subagentes | Agent Teams |
|--|-----------|-------------|
| Coordenação | O agente principal faz o fan-out; subagentes apenas reportam de volta | Colegas trocam mensagens entre si, compartilham uma lista de tarefas |
| Contexto | Janela de contexto própria por subagente | Janela de contexto própria por colega |
| Quando usar | Tarefas independentes que produzem relatórios | Trabalho colaborativo que precisa de discussão |
| Status | Estável | Experimental — requer `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| Custo | Menor | Maior — cada colega é uma instância separada do Claude |

**As personas deste repositório funcionam nos dois modos.** Quando iniciadas como subagentes (ex.: pelo `/ship`), elas reportam achados à sessão principal. Quando iniciadas como colegas (`Spawn a teammate using the security-auditor agent type…`), podem contestar os achados umas das outras diretamente. A definição da persona é a mesma; só o contexto de spawn muda.

Uma sutileza: os campos de frontmatter `skills` e `mcpServers` de uma persona são honrados quando ela roda como subagente, mas **ignorados quando roda como colega** — colegas carregam skills e servidores MCP das configurações do projeto e do usuário, como uma sessão normal. Se uma persona depende de uma skill ou servidor MCP específico, configure no nível da sessão para que esteja disponível nos dois modos.

### Regras impostas pela plataforma

Duas regras deste catálogo não são só convenção — o Claude Code as impõe:

- **"Subagentes não podem iniciar outros subagentes"** (literal da documentação). O antipadrão B (persona-chama-persona) e o antipadrão D (árvores profundas de personas) não podem existir no Claude Code por construção.
- **"Sem times aninhados"** — colegas não podem iniciar os próprios times. Os mesmos antipadrões bloqueados no nível de time.

Isso significa que você pode adotar os padrões deste catálogo sem se preocupar com contribuidores construindo os antipadrões por acidente. Eles simplesmente falharão ao carregar.

### Subagentes embutidos que vale conhecer

Antes de definir um subagente customizado, verifique se um destes cobre o papel:

| Embutido | Propósito |
|----------|-----------|
| `Explore` | Busca e análise de código somente leitura. Use para o Padrão 5 (isolamento de pesquisa). |
| `Plan` | Pesquisa somente leitura durante o modo de planejamento. |
| `general-purpose` | Tarefas multi-etapa que precisam de exploração e modificação. |

Não os redefina. Coloque as suas personas especialistas (code-reviewer, security-auditor, test-engineer) por cima deles.

### Restrições de frontmatter para agents de plugin

Subagentes de plugin **não** suportam os campos de frontmatter `hooks`, `mcpServers` ou `permissionMode` — eles são silenciosamente ignorados. Se uma persona futura precisar de algum deles, o usuário deve copiar o arquivo para `.claude/agents/` ou `~/.claude/agents/`.

Os campos que FUNCIONAM em agents de plugin são: `name`, `description`, `tools`, `disallowedTools`, `model`, `maxTurns`, `skills`, `memory`, `background`, `effort`, `isolation`, `color`, `initialPrompt`. Use `model` por persona se quiser otimizar custo (ex.: Haiku para varreduras de cobertura do `test-engineer`, Sonnet para o `code-reviewer`, Opus para o `security-auditor`).

### Iniciando múltiplos subagentes em paralelo

No Claude Code, o fan-out paralelo (Padrão 3) exige emitir **múltiplas chamadas da ferramenta Agent em um único turno do assistente**. Turnos sequenciais serializam a execução. O `/ship` explicita isso. Qualquer novo comando orquestrador deve fazer o mesmo.

---

## Exemplo trabalhado: Agent Teams para depuração com hipóteses concorrentes

Este exemplo mostra quando recorrer a **Agent Teams** em vez do fan-out de subagentes do `/ship`. Os dois padrões parecem similares de longe — ambos iniciam as mesmas três personas — mas o valor vem de um lugar diferente.

### O cenário

> *O checkout ocasionalmente trava por ~30 segundos antes de completar. Acontece mais ou menos uma vez a cada 50 sessões. Sem erros nos logs. Começou depois da release da semana passada.*

Causas raiz plausíveis (mutuamente exclusivas, todas compatíveis com os sintomas):

1. Uma race condition no novo fluxo de confirmação de pagamento
2. Uma checagem de autenticação que ocasionalmente cai em uma chamada de rede síncrona e lenta
3. Um índice ausente em uma query que escala com o tamanho do carrinho
4. Uma API de terceiro instável em que o SDK faz retries silenciosos antes do timeout

Um agente único vai escolher a primeira teoria plausível e parar de investigar. Um fan-out de subagentes estilo `/ship` faria cada persona reportar de forma independente — mas os relatórios nunca se encontram, então nada elimina as teorias erradas.

Este é exatamente o caso que a documentação de Agent Teams descreve: *"Com múltiplos investigadores independentes tentando ativamente refutar uns aos outros, a teoria que sobrevive tem probabilidade muito maior de ser a causa raiz real."*

### Por que isto *não* é trabalho para o `/ship`

| | `/ship` (subagentes) | Agent Teams |
|--|--------------------|-------------|
| Os subagentes veem | O mesmo diff, lentes diferentes | Uma lista de tarefas compartilhada, as mensagens uns dos outros |
| Saída | Três relatórios independentes → um merge | Debate adversarial → causa raiz por consenso |
| Certo quando | Você quer um veredito sobre um artefato conhecido | Você quer *encontrar* o artefato entre hipóteses |

O `/ship` é um veredito; Agent Teams é uma investigação.

### Setup (uma vez, por ambiente)

Agent Teams é experimental. Em `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Requer Claude Code v2.1.32 ou posterior. As personas deste repositório são detectadas automaticamente — sem arquivos de configuração de time para escrever à mão.

### O prompt gatilho

Digite na sessão líder, em linguagem natural:

```
Usuários reportam que o checkout trava por ~30 segundos de forma
intermitente desde a release da semana passada. Sem erros nos logs.

Crie um agent team para depurar isto com hipóteses concorrentes.
Inicie três colegas usando os agent types existentes:

  - code-reviewer  — investigar race conditions e chamadas bloqueantes
                     no caminho de código do checkout
  - security-auditor — investigar checagens de auth, manejo de sessão
                       e qualquer chamada de rede síncrona adicionada
                       recentemente
  - test-engineer  — propor testes que distingam as hipóteses e
                     verificar lacunas de cobertura no checkout

Faça-os trocar mensagens diretamente para contestar as teorias uns
dos outros. Atualizem os achados conforme o consenso emergir. Só
convirjam quando dois colegas concordarem que conseguem refutar as
teorias dos demais.
```

O líder inicia três colegas referenciando os nomes das personas existentes. O corpo da persona é **anexado** ao system prompt de cada colega como instruções adicionais (por cima das instruções de coordenação de time que o líder instala); o prompt gatilho acima vira a tarefa deles.

### O que acontece

1. Cada colega roda na própria janela de contexto, explorando o código-base pela própria lente.
2. Colegas usam `message` para enviar achados diretamente uns aos outros. O líder não precisa retransmitir.
3. A lista de tarefas compartilhada mostra quem investiga o quê — visível a qualquer momento com `Ctrl+T` (modo in-process) ou em um painel tmux (modo split).
4. Quando o `code-reviewer` encontra um fan-out de goroutines que deveria ser sequencial, ele manda mensagem ao `security-auditor` para confirmar que a chamada de auth não faz parte da race. O `security-auditor` verifica e responde — confirmando que a race é o problema real ou produzindo contraevidência.
5. O `test-engineer` propõe um teste de integração focado para a teoria que estiver vencendo, que o time usa para verificar antes de declarar consenso.
6. O líder sintetiza o achado convergido e o apresenta a você.

Você pode interromper qualquer colega ciclando com `Shift+Down` e digitando — útil para redirecionar um investigador que entrou por um caminho errado.

### Quando limpar

Quando a investigação chegar a uma causa raiz, diga ao líder:

```
Clean up the team
```

Sempre limpe pelo líder, não por um colega (conforme a documentação: colegas não têm o contexto completo do time para a limpeza).

### Expectativa de custo

Três colegas Sonnet rodando por ~10–15 minutos de investigação custam perceptivelmente mais do que as mesmas três personas iniciadas como subagentes pelo `/ship`. A justificativa é a *qualidade da conclusão* — para depuração de produção em que a correção errada é cara, os tokens extras são uma barganha. Para uma revisão de PR rotineira, fique com o `/ship`.

### Antipadrão neste cenário

**Não** reconstrua isto como um slash command `/debug` que faz fan-out de subagentes. Subagentes não conseguem trocar mensagens — você perderia o debate adversarial que faz o padrão funcionar. Se um workflow continuar aparecendo, documente o prompt gatilho acima como um snippet em vez de embrulhá-lo em um slash command que usa subagentes do jeito errado.

### Quando *não* usar Agent Teams

- Veredito rumo a produção sobre um diff conhecido → use `/ship` (subagentes).
- Uma perspectiva especialista sobre um artefato → invocação direta da persona.
- Ciclo de vida sequencial (spec → plan → build) → slash commands dirigidos pelo usuário (Padrão 4).
- Pesquisa pesada em leitura com resumo pequeno → subagente embutido `Explore`.

Recorra a Agent Teams apenas quando os colegas **precisam** contestar uns aos outros para produzir a resposta certa.

---

## Antipadrões

### A. Persona roteadora ("meta-orquestrador")

Uma persona cujo trabalho é decidir qual outra persona chamar.

```
/work → persona-roteadora → "isto precisa de review" → code-reviewer → roteadora (parafraseia) → usuário
```

**Por que falha:**
- Camada de roteamento pura, sem valor de domínio
- Adiciona dois saltos de paráfrase → perda de informação + aproximadamente 2× o custo de tokens
- O usuário já sabia que queria um review; poderia ter chamado `/review` diretamente
- Replica o trabalho que os slash commands e o mapeamento de intenção no README já fazem

**Faça em vez disso:** adicione ou refine slash commands. Documente o mapeamento intenção → comando no `README.md`.

---

### B. Persona que chama outra persona

Um `code-reviewer` que invoca internamente o `security-auditor` quando vê código de autenticação.

**Por que falha:**
- Personas foram projetadas para produzir uma única perspectiva; encadeá-las anula isso
- O resumo que a persona chamadora passa perde contexto de que a persona chamada precisa
- Modos de falha se multiplicam (qual formato de saída vence? as regras de quem se aplicam?)
- Esconde o custo do usuário

**Faça em vez disso:** faça a persona chamadora *recomendar* uma auditoria de follow-up no relatório. O usuário ou um slash command roda a segunda passada.

---

### C. Orquestrador sequencial que parafraseia

Um agente que chama `/spec`, depois `/plan`, depois `/build`, etc. em nome do usuário.

**Por que falha:**
- Perde os checkpoints humanos que capturam trabalho na direção errada
- Cada hand-off resume o contexto — deriva acumulada ao longo de um pipeline longo
- Dobra o custo de tokens: turno do orquestrador + turno do subagente a cada passo
- Remove a agência do usuário exatamente nos pontos onde o julgamento mais importa

**Faça em vez disso:** mantenha o usuário como orquestrador. Documente a sequência recomendada no `README.md` e deixe os usuários invocá-la.

---

### D. Árvores profundas de personas

O `/ship` chama um `pre-ship-coordinator` que chama um `quality-coordinator` que chama o `code-reviewer`.

**Por que falha:**
- Cada camada adiciona latência e tokens sem valor de decisão
- A depuração vira uma investigação multi-nível
- As personas folha perdem contexto para múltiplos passos de sumarização

**Faça em vez disso:** mantenha a profundidade de orquestração em no máximo 1 (slash command → personas). O merge acontece no agente principal.

---

## Fluxo de decisão

Ao considerar um novo workflow orquestrado, percorra este fluxo:

```
O trabalho é uma perspectiva sobre um artefato?
├── Sim → Invocação direta. Pare.
└── Não → A mesma composição vai se repetir?
         ├── Não → Invocação direta, ad hoc. Pare.
         └── Sim → As subtarefas são independentes?
                  ├── Não → Slash commands sequenciais rodados pelo usuário (Padrão 4).
                  └── Sim → Fan-out paralelo com merge (Padrão 3).
                           Valide contra a checklist acima.
                           Se qualquer checagem falhar → recue para comando de persona única (Padrão 2).
```

---

## Quando adicionar um novo padrão a este catálogo

Adicione uma nova entrada apenas depois de:

1. Ter usado o padrão pelo menos duas vezes em trabalho real
2. Conseguir nomear um artefato concreto neste repositório que o demonstre
3. Conseguir explicar por que um padrão existente não teria funcionado
4. Conseguir descrever a sombra de antipadrão dele (o que as pessoas construirão por engano no lugar)

Entradas prematuras no catálogo viram documentação aspiracional que ninguém segue.
