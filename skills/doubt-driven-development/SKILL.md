---
name: doubt-driven-development
description: Submete toda decisão não trivial a uma revisão adversarial com contexto limpo antes de ela valer. Use quando correção importar mais que velocidade, ao trabalhar em código desconhecido, quando os riscos forem altos (produção, lógica sensível a segurança, operações irreversíveis) ou sempre que verificar uma saída confiante agora for mais barato do que depurá-la depois.
---

# Desenvolvimento Guiado por Dúvida

## Visão Geral

Uma resposta confiante não é uma resposta correta. Sessões longas acumulam contexto que silenciosamente transforma premissas em "fatos" sem que ninguém perceba. O desenvolvimento guiado por dúvida é a disciplina de materializar um revisor com contexto limpo — enviesado para **refutar**, não para aprovar — antes que qualquer saída não trivial passe a valer.

Isto não é o `/review`. O `/review` é um veredito sobre um artefato pronto. Isto é uma postura em voo: decisões não triviais são interrogadas enquanto corrigir o rumo ainda é barato.

## Quando Usar

Uma decisão é **não trivial** quando pelo menos uma destas condições vale:

- Introduz ou modifica lógica de ramificação
- Cruza um limite de módulo ou serviço
- Afirma uma propriedade que o sistema de tipos ou o compilador não consegue verificar (thread safety, idempotência, ordenação, invariantes)
- Sua correção depende de contexto que o leitor futuro não consegue ver
- Seu raio de dano é irreversível (deploy em produção, migração de dados, mudança de API pública)

Aplique a skill quando:

- Estiver prestes a tomar uma decisão arquitetural sob incerteza
- Estiver prestes a commitar código não trivial
- Estiver prestes a afirmar um fato não óbvio ("isso é seguro", "isso escala", "isso atende a spec")
- Estiver trabalhando em código que você não entende por completo

**Quando NÃO usar:**

- Operações mecânicas (renomear, formatar, mover arquivos)
- Seguir uma instrução clara e inequívoca do usuário
- Ler ou resumir código existente
- Mudanças de uma linha com correção óbvia
- Operações puras de tooling (rodar testes, listar arquivos)
- O usuário pediu explicitamente velocidade acima de verificação

Se você duvidar de cada tecla, não entrega nada. A skill se aplica apenas a decisões não triviais conforme definido acima.

## Restrições de Carregamento

Esta skill foi projetada para o **orquestrador da sessão principal**, onde o Passo 3 (DUVIDAR, detalhado abaixo) pode iniciar um revisor com contexto limpo.

- **NÃO adicione esta skill ao frontmatter `skills:` de uma persona.** Uma persona que seguisse o Passo 3 iniciaria outra persona — o antipadrão de orquestração explicitamente proibido por `references/orchestration-patterns.md` ("personas não invocam outras personas").
- **Se você se pegar aplicando esta skill de dentro de um contexto de subagente** (onde o Claude Code impede o spawn aninhado de subagentes): o caminho preferido é avisar ao usuário que o ciclo de dúvida não roda aninhado e deixar a sessão principal cuidar disso. Apenas como último recurso existe um fallback degradado de autoquestionamento — reescreva ARTEFATO + CONTRATO como um autoprompt limpo, com um separador mental rígido do seu raciocínio anterior, e percorra os Passos 1–5. Isso **não é revisão com contexto limpo** (você carrega seu próprio contexto consigo), então marque o resultado como degradado e prefira escalar sempre que o usuário estiver acessível.

## O Processo

Copie esta checklist ao aplicar a skill:

```
Ciclo de dúvida:
- [ ] Passo 1: AFIRMAR — escrevi a afirmação + por que importa
- [ ] Passo 2: EXTRAIR — isolei artefato + contrato, removi o raciocínio
- [ ] Passo 3: DUVIDAR — invoquei revisor de contexto limpo com prompt adversarial
- [ ] Passo 4: RECONCILIAR — classifiquei cada achado contra o texto do artefato
- [ ] Passo 5: PARAR — atingi condição de parada (achados triviais, 3 ciclos ou override do usuário)
```

### Passo 1: AFIRMAR — Exponha o que está em jogo

Nomeie a decisão em duas ou três linhas:

```
AFIRMAÇÃO: "A nova camada de cache é thread-safe sob a carga
            de leitura intensa descrita na spec."
POR QUE IMPORTA: uma race condition aqui corrompe dados de
                 usuário e é difícil de detectar em QA.
```

Se você não consegue escrever a afirmação de forma tão compacta, você tem uma sensação, não uma decisão. Exponha-a antes de escrutiná-la.

### Passo 2: EXTRAIR — A menor unidade revisável

Um revisor com contexto limpo precisa do **artefato** e do **contrato**, não da jornada.

- Código: o diff ou a função — não o arquivo inteiro
- Decisão: a proposta em 3–5 frases mais as restrições que ela precisa satisfazer
- Asserção: a afirmação mais a evidência que supostamente a sustenta (mantida distinta do bloco AFIRMAÇÃO do Passo 1, que é a hipótese do orquestrador sob escrutínio)

Remova o seu raciocínio. Se você entregar conclusões, receberá de volta a validação das suas conclusões. A unidade precisa ser pequena o suficiente para o revisor segurar na mente em uma leitura — se for um PR de 500 linhas, decomponha primeiro.

### Passo 3: DUVIDAR — Invoque o revisor de contexto limpo

O prompt do revisor **precisa ser adversarial**. O enquadramento decide a resposta.

```
Revisão adversarial. Encontre o que está errado neste artefato.
Assuma que o autor está confiante demais. Procure por:
- Premissas não declaradas
- Casos de borda não tratados
- Acoplamento oculto ou estado compartilhado
- Formas de violar o contrato
- Convenções existentes que isto pode quebrar
- Modos de falha sob entrada inesperada

NÃO valide. NÃO resuma. Encontre problemas, ou declare
explicitamente que não encontrou nenhum após exame minucioso.

ARTEFATO: <cole o artefato>
CONTRATO: <cole o contrato>
```

**Passe apenas ARTEFATO + CONTRATO. NÃO passe a AFIRMAÇÃO.** Entregar sua conclusão ao revisor o enviesa para a concordância. O revisor deve determinar de forma independente se o artefato satisfaz o contrato.

No Claude Code, os revisores baseados em papéis em `agents/` já começam com contexto isolado por design e são utilizáveis aqui — veja `agents/` para o elenco e a correspondência por domínio.

**O prompt adversarial acima tem precedência sobre o formato de resposta padrão da persona.** Personas como `code-reviewer` são escritas para produzir vereditos equilibrados com pontos fortes e fracos; o guiado por dúvida precisa de saída apenas com problemas. Cole o prompt adversarial na íntegra na invocação para que ele sobreponha o padrão da persona. Se o formato de resposta de uma persona não puder ser sobreposto de forma limpa, recorra a um subagente genérico com o prompt adversarial.

#### Escalação cross-model

Um revisor do mesmo modelo compartilha pontos cegos com o autor original — um modelo mais frio, de arquitetura diferente, os captura. O guiado por dúvida já é opt-in para decisões não triviais, então dentro desse escopo oferecer cross-model é parte do valor da skill, não fricção opcional.

**Sessões interativas: sempre ofereça. Nunca pule em silêncio.**

**Passo 1: Pergunte ao usuário**

Depois da revisão single-model no Passo 3 acima, mas antes de RECONCILIAR, pause e pergunte:

> *"Revisão single-model concluída. Quer uma segunda opinião cross-model? Opções: Gemini CLI, Codex CLI, revisão externa manual (você cola em outro lugar) ou pular."*

Essa pergunta é obrigatória em todo ciclo interativo de dúvida — mesmo em artefatos que pareçam de baixo risco. O usuário — não o agente — decide se o custo vale a pena. O trabalho do agente é apresentar a escolha.

**Passo 2: Se o usuário escolher uma CLI — verifique, depois invoque**

1. Cheque se a ferramenta está no PATH (`which gemini`, `which codex`).
2. Teste se ela funciona (`gemini --version` ou equivalente) antes de passar o prompt completo — um binário quebrado ou desatualizado pode passar no `which` e falhar em entrada real.
3. Confirme a invocação exata com o usuário, incluindo flags, autenticação e variáveis de ambiente necessárias (ex.: API keys). Implementações variam; nunca assuma.
4. Passe **apenas** ARTEFATO + CONTRATO + o prompt adversarial. Sem contexto da sessão, sem AFIRMAÇÃO.
5. Cuidado com escaping de shell. Se o artefato contiver aspas, `$(...)` ou crases, prefira stdin (`echo … | gemini`) ou heredoc em vez de `-p "…"` inline. Na dúvida, peça ao usuário para confirmar a invocação antes de executar.
6. Leve a saída para o Passo 4 (RECONCILIAR).

**Nunca interpole o artefato em um argumento entre aspas de shell.** Código, markdown e prompts de revisão rotineiramente contêm crases, `$(...)` e aspas que vão truncar o prompt ou executar shell embutido. Escreva o prompt completo em um arquivo e envie via stdin.

Formatos de exemplo (verifique as flags contra a ferramenta instalada — a sintaxe difere entre implementações e versões):

```bash
# Escreva primeiro o prompt adversarial + ARTEFATO + CONTRATO em um arquivo temporário.
# Depois envie via stdin para que metacaracteres de shell no artefato fiquem inertes.

# Codex (o sandbox read-only impede a CLI de escrever no seu workspace):
codex exec --sandbox read-only -C <repo-path> - < /tmp/doubt-prompt.md

# Gemini ('--approval-mode plan' é read-only; '-p ""' aciona o modo
# não interativo e o prompt é lido do stdin):
gemini --approval-mode plan -p "" < /tmp/doubt-prompt.md
```

O sandbox read-only é o detalhe estrutural: um artefato de dúvida pode ele mesmo conter instruções (prompt injection intencional ou acidental) que a CLI cross-model executaria contra o seu workspace.

**Passo 3: Se a CLI estiver indisponível ou falhar**

Exponha a falha explicitamente. Ofereça: rodar manualmente, tentar outra ferramenta ou pular. Não caia em silêncio para single-model — o usuário precisa saber que o cross-model não aconteceu.

**Passo 4: Se o usuário pular**

Reconheça o pulo na saída (*"Seguindo apenas com os achados single-model"*) e continue para RECONCILIAR. Pular é aceitável; pular em silêncio não é.

**Contextos não interativos** (CI, `/loop`, autonomous-loop, execuções agendadas):

- Cross-model é **pulado**, e o pulo deve ser **anunciado** na saída: *"Cross-model pulado: contexto não interativo."*
- **Nunca invoque uma CLI externa sem autorização explícita do usuário** — esta é uma propriedade de segurança estrutural.

Cross-model adiciona custo, latência e fragilidade de ferramenta. O agente apresenta a escolha a cada ciclo; o usuário decide se este artefato justifica o custo.

### Passo 4: RECONCILIAR — Traga os achados de volta

A saída do revisor é dado, não veredito. **Você continua sendo o orquestrador.** Releia o texto do artefato contra cada achado antes de classificar — carimbar o revisor é o mesmo modo de falha que ignorá-lo.

Para cada achado, classifique nesta **ordem de precedência** (a primeira classe que casar vence):

1. **Contrato mal lido** — o revisor sinalizou algo especificamente porque o CONTRATO que você forneceu estava pouco claro ou incompleto. Corrija o contrato primeiro, reclassifique no próximo ciclo.
2. **Válido + acionável** — problema real que exige mudança no artefato. Mude, repita o ciclo.
3. **Trade-off válido** — o problema é real, mas o custo de corrigir excede o custo de aceitar. Documente o trade-off explicitamente para o usuário ver.
4. **Ruído** — o revisor sinalizou algo que na verdade está correto sob contexto que ele não tinha. Anote, siga em frente e pergunte: adicionar esse contexto ao contrato teria evitado o falso positivo?

Um revisor limpo pode errar porque lhe falta contexto. Não ceda só porque ele é "limpo".

### Passo 5: PARAR — Loop limitado, não recursão

Pare quando:

- A próxima iteração retornar apenas achados triviais ou já considerados, **ou**
- 3 ciclos forem completados (escale ao usuário, não triture um quarto sozinho), **ou**
- O usuário disser explicitamente "pode entregar"

Se após 3 ciclos o revisor ainda apresentar problemas substantivos, o artefato pode não estar pronto. Exponha isso ao usuário — três ciclos sem resolução são informação sobre o artefato, não motivo para continuar iterando.

Se 3 ciclos forem "obviamente insuficientes" porque o artefato é grande: o artefato está grande demais — volte ao Passo 2 e decomponha. Não afrouxe o limite.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Estou confiante, pulo a etapa de dúvida" | Confiança se correlaciona mal com correção em problemas novos. Momentos de certeza são exatamente onde os pontos cegos se escondem. |
| "Iniciar um revisor é caro" | Depurar um commit errado em produção é mais caro. A checagem é limitada; o bug não é. |
| "O revisor só vai apontar minúcias" | Apenas se não tiver escopo. Restrinja o prompt a "problemas que fariam isto falhar sob o contrato". |
| "Deixo a dúvida para o final, com o `/review`" | O `/review` é um gate final. O guiado por dúvida captura direções erradas cedo, quando corrigir o rumo é barato. Na hora do PR já é tarde. |
| "Se eu duvidar de cada passo, nunca entrego" | A skill se aplica a decisões não triviais, não a cada tecla. Releia "Quando NÃO usar". |
| "Duas opiniões são sempre melhores que uma" | Não quando a segunda tem menos contexto e produz ruído. Reconcilie, não ceda. |
| "O revisor discordou, então eu estava errado" | O revisor não tem o seu contexto — discordância é informação, não veredito. Releia o artefato, classifique e então decida. |
| "Cross-model é sempre melhor" | Cross-model captura pontos cegos que um único modelo compartilha consigo mesmo, mas adiciona custo e fragilidade de ferramenta. Ofereça em todo ciclo interativo de dúvida — o usuário decide se o artefato justifica. O trabalho do agente é apresentar a escolha, não guardá-la. |
| "O usuário disse sim uma vez, então posso continuar invocando a CLI" | Cada invocação é sua própria autorização. O artefato, o prompt e as flags mudam entre chamadas — reconfirme o comando exato com o usuário antes de cada execução. |

## Sinais de Alerta

- Iniciar um revisor de contexto limpo para um rename de uma linha ou mudança de formatação
- Tratar a saída do revisor como autoridade sem reler o texto do artefato
- Iterar >3 ciclos sem escalar ao usuário
- Perguntar ao revisor "isso está bom?" em vez de "encontre problemas"
- Pular a dúvida sob pressão de tempo em uma decisão de alto risco
- Reiniciar contexto limpo sobre um artefato inalterado (você receberá os mesmos achados; você está enrolando)
- **Teatro de dúvida (sinal verificável)**: ao longo de 2 ou mais ciclos em que o revisor apresentou achados substantivos, zero achados foram classificados como acionáveis. Você está validando, não duvidando. Pare e escale.
- Duvidar apenas depois de commitar — isso é `/review`, não desenvolvimento guiado por dúvida
- Fixar uma invocação de CLI externa sem confirmar com o usuário que a ferramenta existe, está configurada e aceita exatamente aquela sintaxe
- **Pular o cross-model em silêncio em um ciclo interativo de dúvida.** Mesmo sem recomendá-lo, a oferta precisa ser visível. Pular é aceitável; pular em silêncio não é.
- Cair em fallback silencioso quando uma CLI externa der erro ou estiver ausente — exponha a falha e deixe o usuário redirecionar
- Remover o contrato da entrada do revisor
- Passar a AFIRMAÇÃO ao revisor (enviesa para a concordância)

## Interação com Outras Skills

- **`code-review-and-quality` / `/review`**: complementares. O `/review` é veredito pós-fato sobre o PR; o guiado por dúvida é por decisão, em voo. Use ambos.
- **`source-driven-development`**: SDD verifica *fatos sobre frameworks* contra documentação oficial. O guiado por dúvida verifica *o seu raciocínio sobre o artefato*. SDD checa que a API existe; o guiado por dúvida checa que você a usou corretamente sob o contrato.
- **`test-driven-development`**: o passo RED do TDD é a dúvida tornada concreta — um teste falhando é uma tentativa de refutação. Quando TDD se aplica, esse teste falhando *é* o passo de dúvida para afirmações comportamentais.
- **`debugging-and-error-recovery`**: quando o revisor expõe um modo de falha real, entre na skill de depuração para localizar e corrigir.
- **Regras de orquestração do repositório** (`references/orchestration-patterns.md`): esta skill orquestra a partir da sessão principal. Uma persona chamando outra persona é o antipadrão B — veja Restrições de Carregamento acima.

## Verificação

Depois de aplicar o desenvolvimento guiado por dúvida:

- [ ] Toda decisão não trivial (pela definição acima) foi nomeada explicitamente como AFIRMAÇÃO antes de valer
- [ ] Houve pelo menos uma revisão de contexto limpo por artefato não trivial (um teste falhando produzido pelo passo RED do TDD satisfaz isso para afirmações comportamentais, conforme Interação com Outras Skills)
- [ ] O revisor recebeu ARTEFATO + CONTRATO — NÃO a AFIRMAÇÃO, NÃO o seu raciocínio
- [ ] O prompt do revisor era adversarial ("encontre problemas"), não validador ("está bom?")
- [ ] Os achados foram classificados contra o texto do artefato (não carimbados) usando a precedência: contrato mal lido / acionável / trade-off / ruído
- [ ] Uma condição de parada foi atingida (achados triviais, 3 ciclos ou override do usuário)
- [ ] Em modo interativo, o cross-model foi **explicitamente oferecido** ao usuário (independentemente do risco do artefato) e a resposta foi reconhecida na saída
- [ ] Em modo não interativo, o cross-model foi pulado e o pulo foi anunciado
- [ ] Toda invocação de CLI externa foi precedida de checagem de PATH, teste do binário, confirmação de sintaxe com o usuário e autorização explícita para rodar
