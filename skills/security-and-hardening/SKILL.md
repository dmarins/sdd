---
name: security-and-hardening
description: Fortalece o código contra vulnerabilidades. Use ao lidar com entrada de usuário, autenticação, armazenamento de dados ou integrações externas. Use ao construir qualquer funcionalidade que aceite dados não confiáveis, gerencie sessões de usuário ou interaja com serviços de terceiros.
---

# Segurança e Hardening

## Visão Geral

Desenvolva com segurança em primeiro lugar. Em backends serverless com Go, AWS e Terraform, trate toda entrada externa como hostil, todo segredo como material crítico e toda verificação de autorizacao como obrigatoria. Segurança não e uma fase isolada; e uma restrição aplicada a cada linha que toca dados, identidade, infraestrutura, eventos ou integrações externas.

## Quando Usar

- Ao construir qualquer coisa que receba entrada externa
- Ao implementar autenticacao ou autorizacao
- Ao armazenar ou transmitir dados sensiveis
- Ao integrar com APIs, filas, webhooks ou servicos externos
- Ao definir IAM, KMS, Secrets Manager, Parameter Store ou politicas de rede
- Ao criar uploads, callbacks, funcoes assicronas ou jobs

## O Sistema de Limites em Tres Niveis

### Sempre Fazer

- **Validar toda entrada externa** na fronteira do sistema: API Gateway, Lambda handler, consumidor de fila, webhook
- **Parametrizar todas as queries**: nunca concatenar dados de usuário em SQL ou comandos
- **Aplicar menor privilegio em IAM**: funcoes e roles devem ter apenas as permissoes estritamente necessarias
- **Usar TLS/HTTPS** em toda comunicacao externa
- **Armazenar segredos em Secrets Manager ou SSM Parameter Store**, com criptografia KMS quando aplicavel
- **Redigir logs e traces** para não vazar PII, tokens ou payloads completos
- **Executar verificacoes de vulnerabilidade** antes de cada release: `govulncheck ./...`, `trivy fs .`, `terraform validate`

### Perguntar Primeiro

- Adicionar um novo fluxo de autenticacao ou mudar logica de autorizacao
- Armazenar nova categoria de dado sensivel
- Adicionar integração externa ou webhook com privilegios ampliados
- Alterar politica de CORS, WAF, VPC, Security Groups ou trust policy
- Modificar rate limiting, throttling ou retries em fluxos sensiveis
- Conceder permissoes elevadas ou cross-account

### Nunca Fazer

- **Nunca commitar segredos** no repositorio
- **Nunca logar dados sensiveis**: senhas, tokens, segredos, documentos completos, payloads com PII
- **Nunca confiar em validacao do cliente** como fronteira de segurança
- **Nunca usar `*` em politicas IAM ou principals** sem justificativa formal e revisão humana
- **Nunca expor stack trace ou detalhe interno** ao consumidor da API
- **Nunca deixar bucket, fila ou topico públicos por conveniencia**
- **Nunca desabilitar criptografia, rotacao ou auditoria** para "destravar rapido"

## Prevencao das Principais Classes de Risco

### 1. Injecao

```go
// RUIM: SQL montado por concatenacao
query := "SELECT id, status FROM orders WHERE customer_id = '" + customerID + "'"

// BOM: query parametrizada
row := db.QueryRowContext(ctx, `
	SELECT id, status
	FROM orders
	WHERE customer_id = $1
`, customerID)
```

Evite tambem montar comandos de shell, expressoes dinamicas ou filtros de banco a partir de entrada não validada.

### 2. Autenticacao e Autorizacao Quebradas

```go
func UpdateOrder(ctx context.Context, claims AuthClaims, input UpdateOrderInput) error {
	if !claims.HasScope("orders:write") {
		return ErrForbidden
	}

	if claims.AccountID != input.AccountID {
		return ErrForbidden
	}

	return nil
}
```

Autenticacao valida identidade. Autorizacao valida permissao sobre o recurso. Não confunda as duas coisas.

### 3. Exposicao de Dados Sensiveis

```go
type CustomerRecord struct {
	ID            string
	Email         string
	PasswordHash  string
	AccessToken   string
	DocumentValue string
}

type CustomerResponse struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}

func sanitizeCustomer(record CustomerRecord) CustomerResponse {
	return CustomerResponse{
		ID:    record.ID,
		Email: record.Email,
	}
}
```

Dados sensiveis devem ser minimizados em resposta, log, trace e storage.

### 4. Misconfiguracao de Infraestrutura

```hcl
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role_policy" "orders_lambda" {
  role = aws_iam_role.orders_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource = aws_dynamodb_table.orders.arn
      }
    ]
  })
}
```

Infraestrutura segura deve ser declarada, revisavel e automatizada.

### 5. Integrações Externas e SSRF

- Não aceite URL arbitraria do usuário para callbacks internos
- Mantenha allowlist de destinos quando o sistema fizer chamadas de saida
- Valide assinatura de webhook antes de processar o payload
- Aplique timeouts curtos, retries com backoff e isolamento de falha

### 6. Dependencias e IaC Vulneraveis

- Rode `govulncheck ./...` para o código Go
- Rode `trivy fs .` ou ferramenta equivalente para dependencias, containers e arquivos de IaC
- Rode `terraform validate` e um scanner como `tfsec` ou `checkov` quando disponivel
- Documente toda excecao de risco e defina data de revisão

## Padroes de Validacao de Entrada

### Validacao na Fronteira do Sistema

```go
type CreateOrderRequest struct {
	CustomerID string `json:"customerId"`
	AmountCents int64 `json:"amountCents"`
}

func (r CreateOrderRequest) Validate() error {
	if strings.TrimSpace(r.CustomerID) == "" {
		return errors.New("customerId is required")
	}
	if r.AmountCents <= 0 {
		return errors.New("amountCents must be greater than zero")
	}
	return nil
}
```

Valide cedo, responda com erro estruturado e não deixe dados malformados atravessarem a fronteira.

### Webhooks e Mensageria

```go
func verifyWebhookSignature(body []byte, signature string, secret string) error {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))

	if !hmac.Equal([]byte(expected), []byte(signature)) {
		return ErrUnauthorized
	}

	return nil
}
```

Não processe webhook sem autenticidade, idempotencia e trilha de auditoria.

## Rate Limiting e Abuse Protection

- Use **AWS WAF rate-based rules** para borda publica quando aplicavel
- Configure throttling em API Gateway
- Proteja endpoints sensiveis com limites mais restritos
- Em mensageria, limite concorrencia e dimensione retries para evitar avalanche

## Gerenciamento de Segredos

```
Preferencia de armazenamento:
1. AWS Secrets Manager para segredos rotacionaveis
2. SSM Parameter Store para configuracoes sensiveis simples
3. Variaveis de ambiente apenas como ponte de leitura segura
```

**Checklist minimo de segredos:**

- Segredos nunca versionados no repositorio
- Rotacao definida quando aplicavel
- Politicas IAM restringem leitura ao minimo necessário
- CloudTrail e logs de acesso habilitados para recursos críticos

## Checklist de Revisão de Segurança

```markdown
### Autenticacao e Autorizacao
- [ ] Toda rota protegida valida identidade e permissao
- [ ] Claims, tenants e ownership sao verificados no servidor
- [ ] Roles IAM seguem menor privilegio

### Entrada e Integrações
- [ ] Toda entrada externa e validada na fronteira
- [ ] Queries sao parametrizadas
- [ ] Webhooks validam assinatura, origem e idempotencia

### Dados e Segredos
- [ ] Nenhum segredo esta no código ou no histórico git
- [ ] Campos sensiveis não aparecem em respostas e logs
- [ ] Criptografia em repouso e em transito esta habilitada quando aplicavel

### Infraestrutura
- [ ] Buckets, filas e topicos não estao públicos sem necessidade explicitada
- [ ] Alarmes, CloudTrail e logs de auditoria estao configurados
- [ ] Ferramentas de scan de dependência e IaC foram executadas
```

## Veja Tambem

Para checklists detalhados e etapas pre-release, consulte `references/security-checklist.md`.

## Justificativas Comuns

| Justificativa | Realidade |
|---|---|
| "E ferramenta interna, segurança não importa tanto" | Ferramenta interna comprometida tambem vira vetor de ataque. |
| "Depois a gente endurece" | Retrofit de segurança custa muito mais do que fazer certo desde o inicio. |
| "Ninguem vai explorar isso" | Scanners automatizados tentam o tempo todo. |
| "AWS ja cuida da segurança" | A AWS protege a plataforma; a configuracao da sua conta e responsabilidade sua. |
| "E so um prototipo" | Prototipos sobrevivem mais do que deveriam. Habitos inseguros viram produção. |

## Sinais de Alerta

- Entrada de usuário indo direto para query, shell, URL ou renderizacao
- Segredos em código, Terraform, exemplos ou histórico de commit
- IAM com curingas amplos sem justificativa documentada
- Buckets ou filas públicos por conveniencia
- Ausencia de rate limiting ou throttling em rotas sensiveis
- Stack traces ou erros internos vazando para clientes
- Dependencias ou infraestrutura com vulnerabilidades conhecidas e sem tratamento

## Verificação

Depois de implementar código sensivel a segurança:

- [ ] `govulncheck ./...` não aponta vulnerabilidades criticas sem tratamento
- [ ] Nenhum segredo esta no código-fonte ou diff atual
- [ ] Toda entrada externa e validada nas fronteiras
- [ ] Autenticacao e autorizacao foram verificadas em todo endpoint protegido
- [ ] Logs e respostas não expõem detalhes internos
- [ ] Rate limiting, WAF ou throttling estao ativos quando aplicavel
- [ ] Terraform e politicas IAM foram revisados com foco em menor privilegio

