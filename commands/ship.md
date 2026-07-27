---
description: Execute a lista de verificação pré-lançamento via fan-out paralelo para personas especialistas e sintetize uma decisão go/no-go
---

Invoque a skill `shipping-and-launch`.

O `/ship` é um **orquestrador fan-out**. Ele roda três personas especialistas em paralelo contra a mudança atual e depois mescla os relatórios em uma única decisão go/no-go com plano de rollback. As personas operam de forma independente — sem estado compartilhado, sem ordem — e é isso que torna a execução paralela segura e útil aqui.

## Fase A — Fan-out paralelo

Inicie três subagentes concorrentes usando a ferramenta Agent. **Emita as três chamadas da ferramenta Agent em um único turno do assistente para que executem em paralelo** — chamadas sequenciais anulam o propósito deste comando.

No Claude Code, cada chamada passa `subagent_type` correspondente ao campo `name` da persona:

1. **`code-reviewer`** — Rode uma revisão em cinco eixos (correção, legibilidade, arquitetura, segurança, performance) sobre as mudanças em stage ou commits recentes. Produza o template padrão de review.
2. **`security-auditor`** — Rode uma passada de vulnerabilidades e threat model. Cheque OWASP Top 10, manejo de segredos, auth/authz, CVEs de dependências, IAM e exposição de recursos AWS. Produza o relatório padrão de auditoria.
3. **`test-engineer`** — Analise a cobertura de testes da mudança. Identifique lacunas em caminho feliz, casos de borda, caminhos de erro e cenários de concorrência. Produza a análise padrão de cobertura.

Em outros harnesses sem ferramenta Agent, invoque o system prompt de cada persona sequencialmente e trate as saídas como se retornadas em paralelo — a fase de merge continua funcionando.

Restrições (do modelo de subagentes do Claude Code):
- Subagentes não podem iniciar outros subagentes — não deixe uma persona delegar a outra.
- Cada subagente tem a própria janela de contexto e retorna apenas o relatório a esta sessão principal.
- Se você precisar de colegas que conversem entre si em vez de só reportar, use Agent Teams do Claude Code referenciando estas personas como tipos de colega (veja `references/orchestration-patterns.md`).

**Resolução de personas.** Se você definiu os próprios `code-reviewer`, `security-auditor` ou `test-engineer` em `.claude/agents/` ou `~/.claude/agents/`, eles têm precedência — o `/ship` capta as suas customizações automaticamente.

## Fase B — Merge no contexto principal

Quando os três relatórios voltarem, o agente principal (não uma sub-persona) os sintetiza nas seis dimensões abaixo. As dimensões 5 e 6 usam a lista de verificação local Go/AWS/Terraform como conteúdo:

1. **Qualidade do Código** — Agregue achados Critical/Important do `code-reviewer` e qualquer teste, lint ou build falhando: `go test ./...` aprovando, build limpa, `gofmt` e `go vet` sem problemas, sem TODOs críticos, logs de debug e código morto removidos. Resolva duplicatas entre revisores.
2. **Segurança** — Promova achados Critical/High do `security-auditor` a blockers de lançamento. Cruze com o eixo de segurança do `code-reviewer`: dependências e imagens base revisadas, sem segredos no repositório nem em variáveis versionadas, IAM com menor privilégio, criptografia e autenticação configuradas, buckets e políticas sem exposição pública indevida.
3. **Performance e Confiabilidade** — Puxe do eixo de performance do `code-reviewer`; perfis e benchmarks revisados quando aplicável, sem gargalos conhecidos, timeouts e retries configurados, limites de CPU e memória definidos, health checks e auto scaling validados na AWS. Cruze Core Web Vitals se houver frontend.
4. **Acessibilidade** — Verifique navegação por teclado, suporte a leitor de tela e contraste quando a release incluir frontend (não coberto pelas três personas — trate diretamente aqui, ou invoque `references/accessibility-checklist.md`).
5. **Infraestrutura como Código** — Verifique diretamente: `terraform fmt`, `terraform validate` e `terraform plan` limpos, mudanças destrutivas revisadas, estado remoto e locking configurados, módulos versionados, drift avaliado e plano aprovado antes do apply.
6. **Operação e Documentação** — Verifique diretamente: variáveis e segredos em Parameter Store ou Secrets Manager, políticas de deploy prontas, migrações e jobs operacionais revisados, observabilidade com logs, métricas e alarmes, dashboards e runbooks disponíveis; README atualizado, changelog e ADRs revisados, procedimento de deploy documentado e critérios de verificação pós-deploy estabelecidos.

## Fase C — Decisão e rollback

Produza uma única saída:

```markdown
## Decisão de Ship: GO | NO-GO

### Blockers (corrigir antes de entregar)
- [Persona de origem: achado Critical + arquivo:linha]

### Correções recomendadas (deveriam sair antes de entregar)
- [Persona de origem: achado Important + arquivo:linha]

### Riscos reconhecidos (entregando mesmo assim)
- [Risco + mitigação]

### Plano de rollback
- Gatilhos: [quais sinais motivariam o rollback]
- Procedimento: [passos exatos — versão anterior, comando ou pipeline de rollback, estratégia para reverter recursos Terraform, tratamento de migrações]
- Objetivo de tempo de recuperação: [alvo]
- Validações pós-rollback: [o que confirmar depois de reverter]

### Relatórios dos especialistas (completos)
- [relatório do code-reviewer]
- [relatório do security-auditor]
- [relatório do test-engineer]
```

## Regras

1. As três personas da Fase A rodam em paralelo — nunca sequencialmente.
2. Personas não chamam umas às outras. O agente principal mescla na Fase B.
3. O plano de rollback é obrigatório antes de qualquer decisão GO.
4. Se qualquer persona retornar um achado Critical, o veredito padrão é NO-GO, a menos que o usuário aceite o risco explicitamente.
5. **Pule o fan-out apenas se tudo isto for verdade:** a mudança toca 2 arquivos ou menos, o diff tem menos de 50 linhas e não toca auth, pagamentos, acesso a dados nem config/env. Caso contrário, o padrão é o fan-out. O `/ship` foi projetado para mudanças rumo a produção — quando o raio de dano não é trivial, rode a revisão paralela mesmo que o diff pareça pequeno.
