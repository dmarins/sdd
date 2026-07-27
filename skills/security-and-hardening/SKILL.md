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
- Ao adicionar funcionalidades que chamam um LLM (chatbots, sumarizadores, agentes, RAG)

## Processo: Threat Model Primeiro

Controles aparafusados sem um modelo de ameaças são chutes. Antes de endurecer, gaste cinco minutos pensando como um atacante:

1. **Mapeie as fronteiras de confiança.** Onde dados não confiáveis cruzam para dentro do sistema? Requisições HTTP, campos de formulário, uploads de arquivo, webhooks, APIs de terceiros, filas de mensagem e **saída de LLM**. Toda fronteira é superfície de ataque.
2. **Nomeie os ativos.** O que vale roubar ou quebrar? Credenciais, PII, dados de pagamento, ações administrativas, movimentação de dinheiro.
3. **Rode STRIDE sobre cada fronteira** — uma lente rápida, não uma cerimônia:

| Ameaça | Pergunte | Mitigação típica |
|---|---|---|
| **S**poofing | Alguém pode se passar por um usuário/serviço? | Autenticação, verificação de assinatura |
| **T**ampering | Dados podem ser alterados em trânsito ou em repouso? | Checagens de integridade, queries parametrizadas, HTTPS |
| **R**epudiation | Uma ação pode ser negada depois? | Log de auditoria de eventos de segurança |
| **I**nformation disclosure | Dados podem vazar? | Criptografia, allowlist de campos, erros genéricos |
| **D**enial of service | Pode ser sobrecarregado? | Rate limiting, limites de tamanho de entrada, timeouts |
| **E**levation of privilege | Um usuário pode ganhar direitos indevidos? | Checagens de autorização, menor privilégio |

4. **Escreva casos de abuso ao lado dos casos de uso.** Para cada funcionalidade, pergunte "como eu abusaria disto?" — e faça disso o seu primeiro teste.

Se você não consegue nomear as fronteiras de confiança de uma funcionalidade, não está pronto para protegê-la. Isto é o OWASP **A04: Insecure Design** — a maioria das brechas começa no design, não no código.

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

### 7. Cross-Site Scripting (XSS) no Frontend

```tsx
// RUIM: renderizar entrada do usuário como HTML
element.innerHTML = userInput;

// BOM: usar o auto-escaping do framework (o React faz por padrão)
return <div>{userInput}</div>;

// Se você PRECISA renderizar HTML, sanitize antes
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);
```

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

### Upload de Arquivos Seguro

```go
var allowedTypes = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
	"image/webp": true,
}

const maxSize = 5 << 20 // 5MB

func validateUpload(contentType string, size int64, head []byte) error {
	if !allowedTypes[contentType] {
		return ErrFileTypeNotAllowed
	}
	if size > maxSize {
		return ErrFileTooLarge
	}
	// Não confie na extensão nem no Content-Type declarado —
	// confira os magic bytes com http.DetectContentType(head) quando for crítico
	return nil
}
```

## Triagem de Resultados de Auditoria de Dependências

Auditorias de gerenciador de pacotes (`govulncheck`, `npm audit`) reportam advisories conhecidos; elas não provam que um pacote é confiável nem que o código vulnerável é alcançável. Use esta árvore de decisão:

```
A auditoria nativa reporta uma vulnerabilidade
├── Severidade: crítica ou alta
│   ├── O código vulnerável é alcançável em runtime, build, teste ou deploy?
│   │   ├── SIM --> Corrija imediatamente (atualize, aplique patch ou substitua a dependência)
│   │   └── NÃO (confirmado sem uso nesses caminhos) --> Corrija em breve, mas não é blocker
│   └── Existe correção disponível?
│       ├── SIM --> Atualize para a versão corrigida
│       └── NÃO --> Busque workarounds, considere substituir a dependência, ou registre exceção com data de revisão
├── Severidade: moderada
│   ├── Alcançável em produção? --> Corrija no próximo ciclo de release
│   └── Só em dev? --> Corrija quando conveniente, acompanhe no backlog
└── Severidade: baixa
    └── Acompanhe e corrija nas atualizações regulares de dependências
```

**Perguntas-chave:**
- A função vulnerável é de fato chamada no seu caminho de código? (o `govulncheck` já responde isso para Go)
- A dependência é de runtime ou só de desenvolvimento?
- A vulnerabilidade é explorável no seu contexto de deploy (ex.: vulnerabilidade server-side em um app client-only)?

Quando adiar uma correção, documente a razão e defina uma data de revisão.

### Higiene de Supply Chain

Não presuma o gerenciador nem trate o manifesto mais próximo como raiz de instalação. Aplique esta ordem:

1. **Encontre a fronteira de instalação e o gerenciador.** Use a raiz do workspace dona do lockfile, ou um projeto aninhado independente apenas quando estiver fora desse workspace. Ali, corrobore `packageManager` (quando presente), o lockfile e a CI; pare em caso de desacordo ou lockfiles concorrentes. Fixe a versão do gerenciador. Em Go, a fronteira é o `go.mod` + `go.sum` do módulo.
2. **Bloqueie scripts de dependência antes da primeira execução.** Em ecossistemas com install scripts (npm), faça o bootstrap com scripts desabilitados ou uma política fail-closed documentada, inspecione a fonte dos scripts pendentes, aprove apenas o mínimo necessário, commite a política e então verifique com uma instalação limpa frozen/imutável. Nunca aprove scripts em bloco. (Go não executa scripts de instalação — uma razão a mais para preferir a stdlib.)

Auditorias só encontram advisories conhecidos; não capturam um pacote recém-malicioso ou typosquatted. Portanto:

- **Nunca aplique remediação forçada de auditoria automaticamente** (`npm audit fix --force` ou equivalente). Pré-visualize a remediação, leia changelogs e teste cada upgrade resultante; correções forçadas podem cruzar os ranges declarados de dependência.
- **Verifique assinaturas de registry e proveniência onde houver suporte** (`npm audit signatures`) e trate a ausência como sinal para investigar, não como prova automática de comprometimento. Em Go, o `GOSUMDB` (sum database) já verifica a integridade dos módulos por padrão — não o desabilite.
- **Revise juntos dependências novas, diffs de lockfile e mudanças de política de scripts** — propriedade, manutenção, idade da release, proveniência, grafo transitivo e typosquats como `cross-env` vs `crossenv` (OWASP **A06**, **LLM03**).

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

## Protegendo Funcionalidades de IA / LLM

Se a sua aplicação chama um LLM — chatbots, sumarizadores, agentes, RAG — ela herda uma nova superfície de ataque. Mapeie-a para o [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/llm-top-10/):

- **Trate toda saída do modelo como entrada não confiável (LLM05: Improper Output Handling).** Nunca passe saída de LLM direto para `eval`, SQL, um shell, `innerHTML` ou um caminho de arquivo. Valide e codifique exatamente como faria com entrada crua de usuário.
- **Assuma que prompts podem ser sequestrados (LLM01: Prompt Injection).** Texto não confiável na janela de contexto — uma mensagem de usuário, uma página web buscada, um PDF — pode carregar instruções. O system prompt não é uma fronteira de segurança; imponha permissões em código, não no prompt.
- **Mantenha segredos e dados de outros usuários fora dos prompts (LLM02 / LLM07).** Qualquer coisa no contexto pode ser ecoada de volta. Não coloque API keys, dados cross-tenant ou o system prompt completo onde o modelo possa repeti-los.
- **Restrinja permissões de ferramentas e agentes (LLM06: Excessive Agency).** Limite as ferramentas ao mínimo, exija confirmação para ações destrutivas ou irreversíveis e valide todo argumento de ferramenta.
- **Limite o consumo (LLM10: Unbounded Consumption).** Estabeleça tetos de tokens, taxa de requisições e profundidade de loop/recursão para que uma entrada forjada não estoure o custo nem trave o sistema.
- **Isole os dados de retrieval (LLM08: Vector and Embedding Weaknesses).** Em RAG, trate o vector store como fronteira de confiança: particione embeddings por tenant para que um usuário não recupere dados de outro, e valide documentos antes de indexar para que conteúdo envenenado não direcione as respostas.

```go
// RUIM: confiar na saída do modelo como comando
sql, _ := llm.Generate(ctx, "Write SQL for: "+userQuestion)
db.QueryContext(ctx, sql) // execução arbitrária de query

// BOM: saída do modelo é dado — faça parse defensivo, valide e só então aja
raw, err := llm.ReplyJSON(ctx, userMessage)
if err != nil {
	return err
}
var intent CommandIntent
if err := json.Unmarshal([]byte(raw), &intent); err != nil {
	return fmt.Errorf("unexpected model output: %w", err)
}
if err := intent.Validate(); err != nil {
	return err
}
return runAllowlistedAction(ctx, intent.Action, intent.Params)
```

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

### Supply Chain
- [ ] Um lockfile autoritativo commitado (`go.sum`, lockfile do npm); a CI usa instalação frozen/imutável
- [ ] Auditoria nativa triada por alcançabilidade e risco da correção; install scripts bloqueados salvo aprovação explícita
- [ ] Dependências novas revisadas (propriedade, proveniência, idade da release, grafo transitivo)

### IA / LLM (se usado)
- [ ] Saída do modelo tratada como não confiável (sem eval/SQL/innerHTML/shell)
- [ ] Segredos e dados de outros usuários mantidos fora dos prompts
- [ ] Permissões de ferramentas/agentes restritas; ações destrutivas exigem confirmação
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

