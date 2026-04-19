# Checklist de Performance

Checklist de referência rápida para performance de aplicações web. Use em conjunto com a skill `performance-optimization`.

## Sumário

- [Metas de Core Web Vitals](#metas-de-core-web-vitals)
- [Diagnóstico de TTFB](#diagnóstico-de-ttfb)
- [Checklist de Frontend](#checklist-de-frontend)
- [Checklist de Backend](#checklist-de-backend)
- [Comandos de Medição](#comandos-de-medição)
- [Antipadrões Comuns](#antipadrões-comuns)

## Metas de Core Web Vitals

| Métrica | Bom | Precisa Melhorar | Ruim |
|--------|------|------------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| INP (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |

## Diagnóstico de TTFB

Quando o TTFB estiver lento (> 800ms), verifique cada componente na waterfall de rede do DevTools:

- [ ] **Resolução de DNS** lenta → adicione `<link rel="dns-prefetch">` ou `<link rel="preconnect">` para origens conhecidas
- [ ] **Handshake TCP/TLS** lento → habilite HTTP/2, considere deploy em edge e verifique keep-alive
- [ ] **Processamento do servidor** lento → faça profiling do backend, revise queries lentas e adicione cache

## Checklist de Frontend

### Imagens
- [ ] Imagens usam formatos modernos (WebP, AVIF)
- [ ] Imagens têm dimensionamento responsivo (`srcset` e `sizes`)
- [ ] Imagens e elementos `<source>` têm `width` e `height` explícitos, para evitar CLS em art direction
- [ ] Imagens abaixo da dobra usam `loading="lazy"` e `decoding="async"`
- [ ] Imagens hero ou LCP usam `fetchpriority="high"` e não usam lazy loading

### JavaScript
- [ ] Bundle inicial abaixo de 200KB gzipped
- [ ] Code splitting com `import()` dinâmico para rotas e funcionalidades pesadas
- [ ] Tree shaking habilitado, verificando se a dependência entrega ESM e marca `sideEffects: false`
- [ ] Sem JavaScript bloqueante em `<head>`; use `defer` ou `async`
- [ ] Computação pesada delegada para Web Workers, quando aplicável
- [ ] `React.memo()` em componentes caros que re-renderizam com as mesmas props
- [ ] `useMemo()` e `useCallback()` apenas onde o profiling mostrar benefício
- [ ] Long tasks (> 50ms) quebradas para manter a main thread disponível, principal alavanca para INP
- [ ] Padrão `yieldToMain` usado dentro de loops longos para permitir eventos de input entre blocos
- [ ] APIs modernas de escalonamento usadas quando disponíveis: `scheduler.yield()` preferencialmente, `scheduler.postTask()` com prioridades e `isInputPending()` para ceder execução só quando necessário
- [ ] `requestIdleCallback` usado para trabalho adiável e não urgente, como analytics, prefetch e warmup
- [ ] Trabalho não crítico retirado de handlers de evento para não atrasar a resposta à interação
- [ ] Scripts de terceiros carregados com `async` ou `defer`, auditados por tamanho e encapsulados por uma fachada quando forem pesados

### CSS
- [ ] Critical CSS inline ou pré-carregado
- [ ] Sem CSS bloqueante para estilos não críticos
- [ ] Sem custo de runtime de CSS-in-JS em produção; prefira extração

### Fontes
- [ ] Limitadas a 2–3 famílias, com 2–3 pesos cada; cada peso extra é mais uma requisição
- [ ] Apenas formato WOFF2, evitando WOFF, TTF e EOT
- [ ] Self-hosted quando possível, já que CDNs de fonte adicionam round-trips de DNS, TCP e TLS
- [ ] Fontes críticas para LCP pré-carregadas com `<link rel="preload" as="font" type="font/woff2" crossorigin>`
- [ ] `font-display: swap` ou `optional` em fontes não críticas para evitar FOIT
- [ ] Subsetting com `unicode-range` para enviar apenas os glifos necessários
- [ ] Uso de variable fonts avaliado quando múltiplos pesos e estilos forem necessários
- [ ] Métricas da fonte fallback ajustadas com `size-adjust`, `ascent-override` e `descent-override` para reduzir CLS na troca
- [ ] Avalie stack de fontes do sistema antes de adotar fonte customizada

### Rede
- [ ] Assets estáticos com cache de `max-age` longo e content hashing
- [ ] Respostas de API com cache quando apropriado, por exemplo com `Cache-Control`
- [ ] HTTP/2 ou HTTP/3 habilitado
- [ ] Recursos com `<link rel="preconnect">` para origens conhecidas
- [ ] `fetchpriority` usado em recursos críticos que não são imagem, como `<link rel="preload">` chave ou scripts above the fold
- [ ] Sem redirecionamentos desnecessários

### Renderização
- [ ] Sem layout thrashing, isto é, layouts síncronos forçados
- [ ] Animações usam `transform` e `opacity`, aproveitando aceleração por GPU
- [ ] Listas longas usam virtualização, como `react-window`
- [ ] Sem re-renders desnecessários de página inteira
- [ ] Seções fora da tela usam `content-visibility: auto` com `contain-intrinsic-size` para pular layout e paint de áreas não visíveis
- [ ] Sem handlers de `unload` nem `Cache-Control: no-store` nas respostas HTML, preservando elegibilidade para bfcache

## Checklist de Backend

### Banco de Dados
- [ ] Sem padrões de query N+1, usando eager loading ou joins quando necessário
- [ ] Queries com índices apropriados
- [ ] Endpoints de lista paginados, nunca `SELECT * FROM table`
- [ ] Pool de conexões configurado
- [ ] Log de queries lentas habilitado

### API
- [ ] Tempo de resposta < 200ms em p95
- [ ] Sem computação pesada síncrona em request handlers
- [ ] Operações em lote em vez de loops com chamadas individuais
- [ ] Compressão de resposta habilitada, como `gzip` ou `brotli`
- [ ] Cache adequado, em memória, Redis ou CDN

### Infraestrutura
- [ ] CDN para assets estáticos
- [ ] Servidor próximo dos usuários, ou deploy em edge
- [ ] Escala horizontal configurada, quando necessária
- [ ] Endpoint de health check para o load balancer

## Comandos de Medição

### Dados de campo de INP e fluxo no DevTools

1. **Comece por dados de campo**: use [CrUX Vis](https://developer.chrome.com/docs/crux/vis) ou sua ferramenta de RUM para medir INP de usuários reais antes de otimizar.
2. **Identifique interações lentas**: abra o DevTools, vá ao painel Performance, grave enquanto interage e procure long tasks disparadas por cliques ou teclas.
3. **Teste em Android intermediário**: problemas de INP muitas vezes só aparecem em hardware mais lento; use dispositivo real ou CPU throttling de 4x a 6x no DevTools.

```bash
# Lighthouse CLI
npx lighthouse https://localhost:3000 --output json --output-path ./report.json

# Análise de bundle
npx webpack-bundle-analyzer stats.json
# ou para Vite:
npx vite-bundle-visualizer

# Verificar tamanho do bundle
npx bundlesize

# Web Vitals no código
import { onLCP, onINP, onCLS } from 'web-vitals';
onLCP(console.log);
onINP(console.log);
onCLS(console.log);

# INP com detalhe por interação (build com attribution)
import { onINP } from 'web-vitals/attribution';
onINP(({ value, attribution }) => {
  const { interactionTarget, inputDelay, processingDuration, presentationDelay } = attribution;
  console.log({ value, interactionTarget, inputDelay, processingDuration, presentationDelay });
});
```

## Antipadrões Comuns

| Antipadrão | Impacto | Correção |
|---|---|---|
| Queries N+1 | Crescimento linear de carga no banco | Use joins, includes ou batch loading |
| Queries sem limite | Exaustão de memória, timeouts | Sempre pagine e adicione `LIMIT` |
| Índices ausentes | Leituras lentas à medida que os dados crescem | Adicione índices em colunas filtradas ou ordenadas |
| Layout thrashing | Jank e frames perdidos | Agrupe leituras de DOM e depois as escritas |
| Imagens não otimizadas | LCP lento e desperdício de banda | Use WebP, tamanhos responsivos e lazy load |
| Bundles grandes | Time to Interactive lento | Faça code split, tree shaking e audite dependências |
| Main thread bloqueada | INP ruim e UI sem resposta | Quebre long tasks com `scheduler.yield()` ou `yieldToMain` e mova trabalho para Web Workers |
| Vazamentos de memória | Crescimento contínuo de memória, até crash | Limpe listeners, intervals e refs |
