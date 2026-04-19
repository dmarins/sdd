---
description: Execute a lista de verificação pré-lançamento para projetos Go com infraestrutura em AWS e Terraform
---

Invoque a skill `shipping-and-launch`.

Execute a lista de verificação pré-lançamento completa:

1. **Qualidade do Código** — `go test ./...` aprovando, build limpa, `gofmt` e `go vet` sem problemas, lint limpo, sem TODOs críticos, logs de debug e código morto removidos
2. **Segurança** — Dependências Go e imagens base revisadas, sem segredos no repositório nem em variáveis versionadas, IAM com menor privilégio, criptografia e autenticação configuradas, políticas e buckets sem exposição pública indevida
3. **Desempenho e Confiabilidade** — Perfis e benchmarks revisados quando aplicável, sem gargalos conhecidos, timeouts e retries configurados, limites de CPU e memória definidos, health checks, readiness checks e auto scaling validados na AWS
4. **Infraestrutura como Código** — `terraform fmt`, `terraform validate` e `terraform plan` limpos, mudanças destrutivas revisadas, estado remoto e locking configurados, módulos versionados, drift avaliado e plano aprovado antes do apply
5. **Operação em AWS** — Variáveis e segredos definidos em Parameter Store ou Secrets Manager, políticas de deploy prontas, migrações e jobs operacionais revisados, observabilidade configurada com logs, métricas e alarmes, dashboards e runbooks disponíveis
6. **Documentação e Lançamento** — README atualizado, changelog e ADRs revisados, procedimento de deploy documentado, checklist de rollback definido, impacto da mudança comunicado e critérios de verificação pós-deploy estabelecidos

Relate quaisquer verificações com falha e ajude a resolvê-las antes da implantação. Antes de prosseguir, defina explicitamente o plano de reversão, incluindo versão anterior, comando ou pipeline de rollback, estratégia para reverter recursos Terraform, tratamento de migrações e validações pós-rollback.