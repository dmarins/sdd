# Checklist de Segurança

Referência rápida para segurança de aplicações. Use em conjunto com a skill `security-and-hardening`.

## Sumário

- [Threat Modeling (Comece Aqui)](#threat-modeling-comece-aqui)
- [Verificações Antes do Commit](#verificações-antes-do-commit)
- [Autenticação](#autenticação)
- [Autorização](#autorização)
- [Validação de Entrada](#validação-de-entrada)
- [Cabeçalhos de Segurança](#cabeçalhos-de-segurança)
- [Configuração de CORS](#configuração-de-cors)
- [Proteção de Dados](#proteção-de-dados)
- [Segurança de Dependências](#segurança-de-dependências)
- [Segurança de IA / LLM](#segurança-de-ia--llm)
- [Tratamento de Erros](#tratamento-de-erros)
- [Referência Rápida do OWASP Top 10](#referência-rápida-do-owasp-top-10)
- [Referência Rápida do OWASP Top 10 para LLMs](#referência-rápida-do-owasp-top-10-para-llms)

## Threat Modeling (Comece Aqui)

Antes de recorrer a controles, gaste cinco minutos pensando como um atacante:

- [ ] Fronteiras de confiança mapeadas (requisições, uploads, webhooks, APIs de terceiros, saída de LLM)
- [ ] Ativos nomeados (credenciais, PII, dados de pagamento, ações administrativas, movimentação de dinheiro)
- [ ] STRIDE rodado por fronteira (Spoofing, Tampering, Repudiation, Info disclosure, DoS, Elevation)
- [ ] Casos de abuso escritos ao lado dos casos de uso ("como eu abusaria disto?")

## Verificações Antes do Commit

- [ ] Não há segredos no código, por exemplo com `git diff --cached | grep -Ei "password|secret|api_key|token|aws_access_key_id|aws_secret_access_key"`
- [ ] O `.gitignore` cobre `.env`, `.env.local`, `*.pem`, `*.key`, `.terraform/` e `terraform.tfstate*`
- [ ] `.env.example` usa apenas placeholders, nunca segredos reais

## Autenticação

- [ ] Senhas usam hash forte com `bcrypt`, `scrypt` ou `argon2`
- [ ] Cookies de sessão usam `httpOnly`, `secure` e `sameSite: 'lax'` quando o sistema usar sessão baseada em cookie
- [ ] Expiração de sessão ou token está configurada com janela razoável
- [ ] Há rate limiting em endpoint de login, por exemplo ≤10 tentativas em 15 minutos
- [ ] Tokens de reset de senha expiram e são de uso único
- [ ] Bloqueio após falhas repetidas foi avaliado para fluxos sensíveis
- [ ] MFA existe ou foi considerada para operações críticas

## Autorização

- [ ] Todo endpoint protegido verifica autenticação
- [ ] Todo acesso a recurso verifica ownership ou role, prevenindo IDOR
- [ ] Endpoints administrativos exigem verificação de role administrativa
- [ ] API keys têm escopo mínimo necessário
- [ ] Tokens JWT são validados em assinatura, expiração, issuer e audience quando aplicável
- [ ] Policies IAM seguem menor privilégio para roles, Lambdas e integrações

## Validação de Entrada

- [ ] Toda entrada externa é validada nas fronteiras do sistema, como handlers HTTP, eventos SQS/SNS/EventBridge e webhooks
- [ ] Validação usa allowlists em vez de denylists
- [ ] Strings têm limites de tamanho
- [ ] Faixas numéricas são validadas
- [ ] E-mail, URL e datas são validados com bibliotecas apropriadas
- [ ] Uploads restringem tipo, tamanho e conteúdo
- [ ] Queries SQL são parametrizadas, sem concatenação de string
- [ ] URLs são validadas antes de redirecionar, evitando open redirect
- [ ] Payloads de eventos têm schema e versionamento explícito

## Cabeçalhos de Segurança

```
Content-Security-Policy: default-src 'self'; script-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0  (disabled, rely on CSP)
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## Configuração de CORS

```typescript
// Restritivo, recomendado
cors({
  origin: ['https://yourdomain.com', 'https://app.yourdomain.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
})

// NUNCA use em produção:
cors({ origin: '*' })  // Permite qualquer origem
```

## Proteção de Dados

- [ ] Campos sensíveis são removidos de respostas de API, por exemplo `passwordHash`, `resetToken`, segredos e tokens internos
- [ ] Dados sensíveis não são logados, como senhas, tokens e números completos de cartão
- [ ] PII em repouso é criptografada quando exigido por regulação ou política interna
- [ ] Toda comunicação externa usa HTTPS
- [ ] Backups de banco são criptografados
- [ ] Segredos ficam em AWS Secrets Manager, SSM Parameter Store ou equivalente, nunca hardcoded

## Segurança de Dependências

```bash
# Verificar vulnerabilidades em Go
govulncheck ./...

# Escanear dependências, containers e IaC
trivy fs .

# Validar dependências Terraform e lockfile
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate

# Revisar módulos e versões desatualizadas
go list -m -u all
```

Para projetos com frontend npm, localize primeiro a **fronteira de instalação**: se o pacote é coberto por uma declaração `workspaces` de um pai, use a raiz desse workspace; caso contrário, use a raiz de projeto mais próxima que possua manifesto e grafo de dependências próprios. Nessa fronteira, corrobore `packageManager` (quando presente), o lockfile e os comandos de CI. Pare se discordarem ou se houver lockfiles concorrentes de gerenciadores diferentes.

| Sinal de gerenciador/versão | Instalação frozen/imutável na CI | Auditoria de advisories |
|---|---|---|
| npm (`package-lock.json` ou `npm-shrinkwrap.json`) | `npm ci` | `npm audit` |
| pnpm | `pnpm install --frozen-lockfile` | `pnpm audit` |
| Yarn 2+ | `yarn install --immutable` | `yarn npm audit -A -R` |
| Yarn 1 | `yarn install --frozen-lockfile` | `yarn audit` |

Para um gerenciador ou versão não listado, consulte a documentação oficial dele; não substitua pelos comandos de outro gerenciador.

### Gate de Install Scripts

Nunca descubra scripts de ciclo de vida de dependências executando primeiro uma instalação comum em um cliente cujos defaults não foram verificados.

1. Faça o bootstrap com scripts de dependência desabilitados (`npm ci --ignore-scripts` ou equivalente), ou com uma política default-deny documentada e fail-closed.
2. Inspecione a fonte exata do script e a versão do pacote antes de aprovar.
3. Registre a política nativa de allow/deny mais estreita na fronteira de instalação e commite-a.
4. Rode uma instalação limpa frozen/imutável com essa política e verifique que os pacotes necessários ainda constroem.

Os defaults e nomes de comando dos gerenciadores mudam rápido — verifique a política nativa do cliente fixado na documentação oficial (`npm install-scripts`, `pnpm approve-builds`/`allowBuilds`, `enableScripts`/`dependenciesMeta.built` do Yarn) antes de confiar nela. Go não executa scripts de instalação; o `GOSUMDB` verifica a integridade dos módulos por padrão — não o desabilite.

**Higiene de supply chain** (auditorias de advisories não capturam pacotes recém-maliciosos):
- [ ] Exatamente um lockfile autoritativo por raiz de projeto/workspace está commitado e a CI nunca o reescreve
- [ ] Achados críticos/altos são triados por alcançabilidade; adiamentos têm razão e data de revisão
- [ ] Remediação forçada de auditoria (`npm audit fix --force` ou equivalente) nunca é automática; diffs e changelogs de remediação são revisados
- [ ] Assinaturas/proveniência de registry são verificadas onde o gerenciador suportar
- [ ] Scripts de ciclo de vida de dependências são bloqueados antes da primeira execução e aprovados apenas pela política nativa do gerenciador fixado
- [ ] Dependências novas são revisadas quanto a propriedade, manutenção, idade da release, proveniência, grafo transitivo e typosquatting

## Segurança de IA / LLM

Para qualquer funcionalidade que chame um LLM (chatbots, sumarizadores, agentes, RAG):

- [ ] Saída do modelo tratada como não confiável — nunca vai para `eval`/SQL/shell/`innerHTML`/caminhos de arquivo
- [ ] Prompt injection assumida; permissões impostas em código, não no system prompt
- [ ] Segredos, dados cross-tenant e o system prompt completo mantidos fora da janela de contexto
- [ ] Permissões de ferramentas/agentes restritas; ações destrutivas ou irreversíveis exigem confirmação
- [ ] Limites de tokens, taxa e profundidade de loop/recursão definidos (consumo limitado)

## Tratamento de Erros

```go
// Produção: erro genérico, sem detalhes internos
writeJSON(w, http.StatusInternalServerError, APIErrorResponse{
	Code:    "INTERNAL_ERROR",
	Message: "algo deu errado",
})

// NUNCA em produção:
writeJSON(w, http.StatusInternalServerError, map[string]any{
	"error": err.Error(), // expõe detalhes internos
	"sql":   query,       // expõe detalhes de banco
})
```

## Referência Rápida do OWASP Top 10

| # | Vulnerabilidade | Prevenção |
|---|---|---|
| 1 | Broken Access Control | Checks de auth em todo endpoint e verificação de ownership |
| 2 | Cryptographic Failures | HTTPS, hash forte e sem segredos no código |
| 3 | Injection | Queries parametrizadas e validação de entrada |
| 4 | Insecure Design | Threat modeling e desenvolvimento guiado por spec |
| 5 | Security Misconfiguration | Cabeçalhos, menor privilégio e auditoria de dependências |
| 6 | Vulnerable Components | `govulncheck`, `trivy`, dependências mínimas e atualizadas |
| 7 | Auth Failures | Senhas fortes, rate limiting e gestão correta de sessão ou token |
| 8 | Data Integrity Failures | Verificar artefatos, dependências e pipelines de entrega |
| 9 | Logging Failures | Registrar eventos de segurança sem vazar segredos |
| 10 | SSRF | Validar URLs, usar allowlist e restringir saída de rede |

## Referência Rápida do OWASP Top 10 para LLMs

Para aplicações com funcionalidades de LLM. Veja o [OWASP GenAI Security Project](https://genai.owasp.org/llm-top-10/).

| ID | Risco | Prevenção |
|---|---|---|
| LLM01 | Prompt Injection | Não confie no system prompt como fronteira; imponha permissões em código |
| LLM02 | Sensitive Information Disclosure | Mantenha segredos/PII fora dos prompts; filtre saídas |
| LLM03 | Supply Chain | Avalie modelos, datasets e plugins como qualquer dependência |
| LLM04 | Data and Model Poisoning | Use fontes de modelo confiáveis, verifique integridade; avalie dados de fine-tuning e RAG |
| LLM05 | Improper Output Handling | Trate saída do modelo como não confiável; valide, parametrize, codifique |
| LLM06 | Excessive Agency | Restrinja permissões de ferramentas; confirme ações destrutivas |
| LLM07 | System Prompt Leakage | Assuma que o system prompt pode vazar; não coloque segredos nele |
| LLM08 | Vector and Embedding Weaknesses | Particione embeddings de RAG por tenant; valide documentos antes de indexar |
| LLM09 | Misinformation | Ancore respostas com citações; valide afirmações críticas; mantenha um humano no circuito |
| LLM10 | Unbounded Consumption | Limite tokens, taxa de requisições e profundidade de loop/recursão |
