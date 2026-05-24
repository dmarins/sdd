---
name: using-agent-skills
description: Descobre e invoca skills de agentes. Use ao iniciar uma sessão ou quando precisar descobrir qual skill se aplica à tarefa atual. Esta é a meta-skill que governa como todas as outras skills são descobertas e invocadas.
---

# Usando Agent Skills

## Visão Geral

Agent Skills é uma coleção de skills de fluxo de engenharia organizada por fase de trabalho. Cada skill codifica um processo que engenheiros experientes seguem de forma disciplinada. Esta meta-skill ajuda a descobrir e aplicar a skill certa para a tarefa atual.

## Descoberta de Skills

Quando uma tarefa chegar, identifique a fase do trabalho e aplique a skill correspondente:

```
Tarefa chega
    │
    ├── Ideia vaga ou precisando refinamento? -> idea-refine
    ├── Novo projeto, feature ou mudança? ---> spec-driven-development
    ├── Já existe especificação e faltam tarefas? -> planning-and-task-breakdown
    ├── Implementando código? -----------------> incremental-implementation
    │   ├── UI? ------------------------------> frontend-ui-engineering
    │   ├── API? -----------------------------> api-and-interface-design
    │   ├── Falta contexto? ------------------> context-engineering
    │   └── Precisa seguir docs oficiais? ----> source-driven-development
    ├── Escrevendo ou rodando testes? -------> test-driven-development
    │   └── Há browser envolvido? -----------> browser-testing-with-devtools
    ├── Algo quebrou? -----------------------> debugging-and-error-recovery
    ├── Revisando código? -------------------> code-review-and-quality
    │   ├── Risco de segurança? -------------> security-and-hardening
    │   └── Risco de performance? -----------> performance-optimization
    ├── Comentários de revisão abertos no PR? -> pr-review-comments
    ├── Commit, branch ou histórico? --------> git-workflow-and-versioning
    ├── Atualizando Go ou módulos Go? -------> go-runtime-and-dependency-upgrades
    ├── Pipeline e automação? ---------------> ci-cd-and-automation
    ├── Documentação ou ADR? ----------------> documentation-and-adrs
    └── Deploy ou release? ------------------> shipping-and-launch
```

## Comportamentos Operacionais Básicos

Estes comportamentos valem o tempo todo, independentemente da skill aplicada. Eles não são opcionais.

### 1. Explicite Suposições

Antes de implementar algo não trivial, declare suas suposições:

```
SUPOSIÇÕES QUE ESTOU FAZENDO:
1. [suposição sobre requisito]
2. [suposição sobre arquitetura]
3. [suposição sobre escopo]
-> Corrija agora se alguma estiver errada.
```

Não preencha ambiguidades em silêncio. A falha mais comum é assumir errado e seguir em frente como se estivesse tudo definido.

### 2. Gerencie Confusão Ativamente

Ao encontrar inconsistências, requisitos conflitantes ou especificações pouco claras:

1. Pare
2. Nomeie a confusão específica
3. Apresente o trade-off ou faça a pergunta de esclarecimento
4. Aguarde resolução antes de continuar

**Ruim:** escolher silenciosamente uma interpretação e torcer para estar certa.

**Bom:** "Vejo X na especificação, mas Y no código atual. Qual deve prevalecer?"

### 3. Conteste Quando Houver Motivo

Você não é uma máquina de concordar. Quando uma abordagem tem problema claro:

- Aponte o problema diretamente
- Explique o impacto concreto
- Proponha uma alternativa melhor
- Respeite a decisão humana se, mesmo informado, o usuário quiser seguir

Concordância vazia é um modo de falha. Discordância técnica bem fundamentada é mais útil.

### 4. Force Simplicidade

Sua tendência natural pode ser complicar demais. Resista ativamente.

Antes de concluir qualquer implementação, pergunte:

- Isso pode ser feito com menos moving parts?
- Essas abstrações se pagam?
- Um engenheiro sênior perguntaria "por que não fez do jeito direto?"

Se 100 linhas bastam e você entregou 1000, houve falha de critério.

### 5. Mantenha Disciplina de Escopo

Toque apenas o que foi pedido.

Não faça:

- Remover comentários que você não entendeu
- "Limpar" código paralelo a tarefa
- Refatorar sistemas adjacentes por efeito colateral
- Apagar código que parece não usado sem aprovação explícita
- Adicionar funcionalidade porque "parece útil"

Seu trabalho deve ser preciso, não uma reforma não solicitada.

### 6. Verifique, Não Assuma

Toda skill tem uma etapa de verificação. Uma tarefa só está concluída quando a verificação passa. "Parece certo" não é evidência.

## Modos de Falha a Evitar

Estes são erros que parecem produtividade, mas criam problema:

1. Assumir errado sem checar
2. Não gerenciar a própria confusão
3. Não expor inconsistências percebidas
4. Não apresentar trade-offs em decisões não óbvias
5. Concordar com abordagens claramente ruins
6. Complicar demais código e APIs
7. Alterar código ou comentários fora da tarefa
8. Remover o que não foi plenamente entendido
9. Construir sem especificação porque "está óbvio"
10. Pular verificação porque "parece funcionar"

## Regras das Skills

1. **Verifique se existe uma skill aplicável antes de começar.** Skills codificam processos que evitam erros recorrentes.

2. **Skills são fluxos, não sugestões.** Siga as etapas na ordem certa e não pule verificação.

3. **Várias skills podem se aplicar.** Uma implementação pode passar por `idea-refine` -> `spec-driven-development` -> `planning-and-task-breakdown` -> `incremental-implementation` -> `test-driven-development` -> `code-review-and-quality` -> `shipping-and-launch`.

4. **Na dúvida, comece por especificação.** Se a tarefa não é trivial e não há spec, comece com `spec-driven-development`.

## Sequência Típica de Ciclo de Vida

Para uma feature completa, a sequência usual é:

```
1. idea-refine                 -> refinar ideias vagas
2. spec-driven-development     -> definir o que será construído
3. planning-and-task-breakdown -> quebrar em tarefas verificáveis
4. context-engineering         -> carregar o contexto certo
5. source-driven-development   -> validar contra docs oficiais
6. incremental-implementation  -> implementar em fatias
7. test-driven-development     -> provar que funciona
8. code-review-and-quality     -> revisar antes do merge
9. git-workflow-and-versioning -> manter histórico limpo
10. documentation-and-adrs     -> registrar decisões
11. shipping-and-launch        -> liberar com segurança
```

Nem toda tarefa usa todas as skills. Um bug fix pode precisar apenas de `debugging-and-error-recovery` -> `test-driven-development` -> `code-review-and-quality`.

Workflows de manutenção também podem fugir do lifecycle principal. Exemplo: upgrade de runtime Go ou dependências pode começar diretamente em `go-runtime-and-dependency-upgrades` e depois acionar `ci-cd-and-automation`, `deprecation-and-migration` ou `debugging-and-error-recovery` conforme o impacto.

## Referência Rápida

| Fase | Skill | Resumo em uma linha |
|---|---|---|
| Definir | idea-refine | Refina ideias por pensamento divergente e convergente |
| Definir | spec-driven-development | Define requisitos e critérios de aceitação antes do código |
| Planejar | planning-and-task-breakdown | Decompõe em tarefas pequenas e verificáveis |
| Construir | incremental-implementation | Implementa em fatias finas e testáveis |
| Construir | source-driven-development | Verifica padrões nas docs oficiais |
| Construir | context-engineering | Carrega o contexto certo no momento certo |
| Construir | frontend-ui-engineering | Orienta UI de qualidade de produção |
| Construir | api-and-interface-design | Define contratos claros e estáveis |
| Verificar | test-driven-development | Teste falhando primeiro, depois implementação |
| Verificar | browser-testing-with-devtools | Usa DevTools para verificação runtime em browser |
| Verificar | debugging-and-error-recovery | Reproduz, localiza, corrige e protege |
| Revisar | code-review-and-quality | Faz revisão com critérios de qualidade |
| Revisar | pr-review-comments | Processa comentários de revisão de PR com análise crítica e gates de confirmação |
| Revisar | security-and-hardening | Aplica OWASP, IAM, segredos e menor privilégio |
| Revisar | performance-optimization | Mede primeiro e otimiza o que realmente importa |
| Manter | go-runtime-and-dependency-upgrades | Atualiza runtime Go e módulos com validação, CI e rollback |
| Entregar | git-workflow-and-versioning | Mantém commits atômicos e histórico limpo |
| Entregar | ci-cd-and-automation | Automatiza gates de qualidade |
| Entregar | documentation-and-adrs | Documenta o porquê e não só o que |
| Entregar | shipping-and-launch | Faz release com monitoração e rollback |
