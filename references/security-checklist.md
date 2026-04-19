# Checklist de Segurança

Referência rápida para segurança de aplicações. Use em conjunto com a skill `security-and-hardening`.

## Sumário

- [Verificações Antes do Commit](#verificações-antes-do-commit)
- [Autenticação](#autenticação)
- [Autorização](#autorização)
- [Validação de Entrada](#validação-de-entrada)
- [Cabeçalhos de Segurança](#cabeçalhos-de-segurança)
- [Configuração de CORS](#configuração-de-cors)
- [Proteção de Dados](#proteção-de-dados)
- [Segurança de Dependências](#segurança-de-dependências)
- [Tratamento de Erros](#tratamento-de-erros)
- [Referência Rápida do OWASP Top 10](#referência-rápida-do-owasp-top-10)

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
