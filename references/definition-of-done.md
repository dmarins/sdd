# Definition of Done

Uma barra permanente, válida para o projeto inteiro, que toda mudança precisa cruzar antes de contar como pronta. Diferente dos critérios de aceitação, que variam por tarefa e respondem "construímos a coisa certa?", a Definition of Done é a mesma todas as vezes e responde "isto está terminado no nosso padrão?". Use-a como gate final em `planning-and-task-breakdown`, `incremental-implementation` e `shipping-and-launch`.

## Definition of Done vs. Critérios de Aceitação

| | Critérios de Aceitação | Definition of Done |
|---|---|---|
| Escopo | Específicos de uma tarefa ou spec | Aplica-se a todo incremento |
| Mudança | Diferentes para cada item | Fixa e reutilizada |
| Responde | "Construímos *esta coisa*?" | "Está *pronta*?" |
| Dono | Definidos ao planejar a tarefa | Definida uma vez para o projeto |
| Exemplo | "Usuário redefine a senha via link por e-mail" | "Testes passam, sem regressões, docs atualizados" |

Os dois são complementares. Uma tarefa só está pronta quando **seus** critérios de aceitação são atendidos **e** a Definition of Done permanente é satisfeita. Pular qualquer um dos dois deixa trabalho que parece terminado, mas não está.

## A Checklist Permanente

Aplique a toda mudança antes de declará-la pronta.

### Correção
- [ ] Todos os critérios de aceitação da tarefa foram atendidos
- [ ] O código roda e se comporta como pretendido, verificado em runtime, não apenas compilado ou typecheckado
- [ ] O comportamento novo é coberto por testes que falham sem a mudança e passam com ela
- [ ] Os testes existentes continuam passando; nenhuma regressão introduzida
- [ ] Casos de borda e caminhos de erro estão tratados, não só o caminho feliz

### Qualidade
- [ ] O código revela a intenção por nomes e estrutura; nenhum comentário é necessário para explicar *o que* ele faz
- [ ] Nenhuma lógica de negócio duplicada
- [ ] Nenhum código morto, saída de debug ou bloco comentado deixado para trás
- [ ] As mudanças estão restritas à tarefa; nenhum refactor não relacionado entrou de contrabando
- [ ] Lint e formatação passam

A profundidade por trás destes itens vive em `code-review-and-quality` (a revisão em cinco eixos) e `code-simplification` (reduzir complexidade sem mudar comportamento).

### Integração
- [ ] A mudança funciona com o resto do sistema, não só em isolamento
- [ ] Migrações de banco, mudanças de config e feature flags foram consideradas
- [ ] Retrocompatibilidade considerada para qualquer mudança de interface pública ou API

### Documentação
- [ ] Interfaces públicas, APIs e comportamento visível ao usuário estão documentados
- [ ] Decisões arquiteturais que valem preservar foram registradas (veja `documentation-and-adrs`)
- [ ] A documentação descreve o estado atual em linguagem atemporal, não o histórico da mudança

### Prontidão para Entrega
- [ ] Implicações de segurança revisadas para qualquer entrada não confiável, autenticação ou manuseio de dados (veja `security-and-hardening`)
- [ ] Observabilidade no lugar para os novos caminhos críticos (logs, métricas, traces) (veja `observability-and-instrumentation`)
- [ ] Existe caminho de rollback para qualquer coisa arriscada (veja `shipping-and-launch`)
- [ ] O humano revisou e aprovou antes do merge ou deploy

## Como Aplicar

- **Por tarefa**: confirme as seções de Correção e Qualidade antes de marcar a tarefa como concluída.
- **Por funcionalidade**: confirme Integração e Documentação antes de considerar a funcionalidade completa.
- **Por release**: a checklist inteira é o piso; `shipping-and-launch` adiciona os gates específicos de deploy por cima.

Ajuste a lista ao projeto uma vez, depois reutilize sem mudanças. Uma Definition of Done renegociada a cada sprint não é uma Definition of Done.

## Sinais de Alerta

- "Está pronto, só não rodei ainda": trabalho não verificado não está pronto.
- "Os testes passam" usado como sinônimo de pronto enquanto docs, regressões ou verificação em runtime são pulados.
- Uma barra diferente aplicada conforme a pressão de prazo.
- Critérios de aceitação tratados como a barra inteira, sem piso permanente de qualidade.
- "Pronto" declarado antes da revisão humana em mudanças que precisam dela.
