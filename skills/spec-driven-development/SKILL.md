---
name: spec-driven-development
description: Fundamenta cada decisão de implementação na documentação oficial. Use quando quiser código confiável, baseado em fontes oficiais e livre de padrões desatualizados. Use ao construir com qualquer framework ou biblioteca em que a correção seja importante.
---

# Desenvolvimento Guiado por Fontes Oficiais

## Visão Geral

Toda decisão específica de framework, serviço ou provider deve ser sustentada por documentação oficial. Não implemente de memória: verifique, cite e deixe o usuário ver a fonte. Dados de treinamento envelhecem, APIs são descontinuadas e boas práticas evoluem. Esta skill garante código confiável porque cada padrão usado remete a uma fonte autoritativa que pode ser verificada.

## Quando Usar

- O usuário quer código aderente às boas práticas atuais de uma stack
- Você está montando boilerplate, arquitetura inicial ou padrões que serão copiados por todo o projeto
- O usuário pediu algo documentado, verificado ou "correto"
- O recurso depende da abordagem recomendada pelo framework ou serviço
- Você está revisando ou modernizando código fortemente acoplado a uma tecnologia específica
- Você está prestes a escrever código específico de framework a partir da memória

**Quando NÃO usar:**

- A tarefa não depende da versão exata da tecnologia
- Trata-se apenas de lógica pura, sem API de framework ou serviço
- O usuário explicitamente quer velocidade acima de verificação

## O Processo

```
DETECTAR -> BUSCAR -> IMPLEMENTAR -> CITAR
   │           │            │           │
   ▼           ▼            ▼           ▼
 Stack?      Docs        Padrão      Fontes
 e versão    oficiais    documentado visíveis
```

### Etapa 1: Detectar Stack e Versões

Leia os arquivos de dependência e configuração para identificar as versões exatas:

```
go.mod                    -> Go e módulos Go
versions.tf / *.tf        -> Terraform e providers
Dockerfile                -> runtime base
package.json              -> tooling auxiliar, se existir
openapi.yaml              -> contratos HTTP
```

Declare explicitamente o que foi detectado:

```
STACK DETECTADA:
- Go 1.24.x (go.mod)
- Terraform 1.9.x (required_version)
- AWS provider 5.x (required_providers)
-> Vou buscar a documentação oficial relevante antes de implementar.
```

Se versões estiverem ausentes ou ambíguas, pergunte ao usuário. Não chute: a versão define quais padrões estão corretos.

### Etapa 2: Buscar Documentação Oficial

Busque a página oficial específica para o recurso que está sendo implementado. Não a homepage nem um portal inteiro: a página exata.

**Hierarquia de fontes, em ordem de autoridade:**

| Prioridade | Fonte | Exemplo |
|---|---|---|
| 1 | Documentação oficial | docs.aws.amazon.com, developer.hashicorp.com, go.dev |
| 2 | Blog oficial, changelog ou guia de migração | AWS What's New, HashiCorp release notes, Go release notes |
| 3 | Referência de runtime ou linguagem | pkg.go.dev, RFCs, docs de HTTP, IAM ou OpenAPI |
| 4 | Compatibilidade e suporte | matrizes oficiais de versão e provider |

**Não use como fonte primária:**

- Stack Overflow
- Blog posts de terceiros
- Tutoriais sem autoridade oficial
- Documentação gerada por IA
- Lembrança do próprio modelo

**Seja específico no que buscar:**

```
RUIM: buscar a home do Terraform
BOM: buscar developer.hashicorp.com/terraform/language/meta-arguments/for_each

RUIM: buscar "best practices lambda"
BOM: buscar docs.aws.amazon.com/lambda/latest/dg/best-practices.html

RUIM: buscar a home do Go
BOM: buscar pkg.go.dev/context ou go.dev/doc/modules/layout
```

Depois de buscar, extraia os padrões relevantes e anote quaisquer avisos de depreciação, migração ou restrições.

Se fontes oficiais entrarem em conflito, exponha isso ao usuário e valide qual padrão realmente se aplica à versão detectada.

### Etapa 3: Implementar Seguindo os Padrões Documentados

Escreva código que siga o que a documentação mostra:

- Use assinaturas e APIs conforme a documentação atual
- Se a documentação trouxer uma abordagem nova, prefira a nova
- Se houver depreciação, não use o padrão antigo
- Se a documentação não cobrir algo, trate aquilo como não verificado

**Quando a documentação conflitar com o código existente:**

```
CONFLITO DETECTADO:
O código atual usa políticas IAM amplas com "*",
mas a documentação oficial da AWS recomenda menor privilégio.

Opcoes:
A) Seguir a prática moderna da documentação
B) Manter o padrão atual para consistência temporária
-> Qual caminho devemos adotar?
```

Não escolha em silêncio quando houver conflito entre modernização e consistência do repositório.

### Etapa 4: Citar as Fontes

Todo padrão específico de framework, provider ou serviço deve vir com citação. O usuário precisa conseguir verificar cada decisão.

**Em comentários de código, quando fizer sentido:**

```go
// AWS Lambda best practices recommend reusing SDK clients across invocations.
// Source: https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html
var ddbClient = dynamodb.NewFromConfig(cfg)
```

**Na conversa com o usuário:**

```
Estou usando `for_each` em vez de `count` para recursos enderecados por chave,
porque a documentação do Terraform recomenda isso quando a identidade do recurso
precisa permanecer estável ao longo do tempo.

Fonte: https://developer.hashicorp.com/terraform/language/meta-arguments/for_each
```

**Regras de citação:**

- Use URLs completas
- Prefira deep links quando houver âncora ou seção específica
- Cite o trecho relevante quando a decisão não for óbvia
- Inclua dados de compatibilidade quando a recomendação depender de versão
- Se você não encontrar documentação oficial, diga isso explicitamente:

```
NÃO VERIFICADO: não encontrei documentação oficial para este padrão.
Isto se baseia em conhecimento prévio e deve ser validado antes de uso em produção.
```

Ser honesto sobre o que não foi possível verificar é melhor do que demonstrar confiança falsa.

## Justificativas Comuns

| Justificativa | Realidade |
|---|---|
| "Tenho certeza de como essa API funciona" | Certeza não é evidência. Uma assinatura desatualizada parece correta até quebrar. |
| "Buscar docs gasta tempo" | Debugar um padrão errado gasta muito mais. |
| "A documentação não vai cobrir esse caso" | Se não cobre, isso já é uma informação importante sobre o nível de recomendação oficial. |
| "Basta avisar que pode estar desatualizado" | Aviso genérico não resolve. Ou verifique e cite, ou marque como não verificado. |
| "E uma tarefa simples" | Tarefas simples viram templates repetidos no projeto inteiro. |

## Sinais de Alerta

- Escrever código específico de framework sem checar a documentação da versão detectada
- Usar "acho" ou "acredito" sobre uma API em vez de mostrar a fonte
- Implementar sem saber a qual versão o padrão se aplica
- Citar Stack Overflow ou blog de terceiros como base primaria
- Usar APIs descontinuadas porque aparecem em exemplos antigos
- Não ler `go.mod`, `versions.tf` ou arquivos equivalentes antes de implementar
- Entregar código sem fontes para decisões não triviais
- Buscar um site inteiro de docs quando uma única página resolveria

## Verificação

Depois de implementar com base em fontes oficiais:

- [ ] Versões de framework, provider e runtime foram identificadas
- [ ] A documentação oficial relevante foi buscada
- [ ] As fontes usadas são oficiais e atuais
- [ ] O código segue os padrões mostrados na documentação da versão detectada
- [ ] Decisões não triviais trazem citações com URL completa
- [ ] APIs descontinuadas foram evitadas
- [ ] Conflitos entre docs e código existente foram expostos ao usuário
- [ ] Tudo o que não foi verificado foi marcado explicitamente

