# Checklist de Acessibilidade

Referência rápida para conformidade com WCAG 2.1 AA. Use em conjunto com a skill `frontend-ui-engineering`.

## Sumário

- [Verificações Essenciais](#verificações-essenciais)
- [Padrões Comuns de HTML](#padrões-comuns-de-html)
- [Ferramentas de Teste](#ferramentas-de-teste)
- [Referência Rápida: Regiões ARIA Live](#referência-rápida-regiões-aria-live)
- [Antipadrões Comuns](#antipadrões-comuns)

## Verificações Essenciais

### Navegação por Teclado
- [ ] Todos os elementos interativos recebem foco com a tecla Tab
- [ ] A ordem de foco segue a ordem visual e lógica
- [ ] O foco é visível, com outline ou ring nos elementos focados
- [ ] Widgets customizados têm suporte por teclado, como Enter para ativar e Escape para fechar
- [ ] Não há armadilhas de teclado; o usuário sempre consegue sair com Tab
- [ ] Existe link para pular ao conteúdo no topo da página, visível ao menos no foco por teclado
- [ ] Modais prendem o foco enquanto abertos e devolvem o foco ao fechar

### Leitores de Tela
- [ ] Todas as imagens têm texto `alt`, ou `alt=""` se forem decorativas
- [ ] Todos os campos de formulário têm labels associadas, com `<label>` ou `aria-label`
- [ ] Botões e links têm texto descritivo, não apenas "Clique aqui"
- [ ] Botões só com ícone têm `aria-label`
- [ ] A página tem um único `<h1>` e os headings não pulam níveis
- [ ] Mudanças dinâmicas de conteúdo são anunciadas com regiões `aria-live`
- [ ] Tabelas têm cabeçalhos `<th>` com `scope`

### Visual
- [ ] Contraste de texto ≥ 4.5:1 em texto normal ou ≥ 3:1 em texto grande, 18px+
- [ ] Componentes de UI têm contraste ≥ 3:1 contra o fundo
- [ ] Cor não é a única forma de transmitir informação
- [ ] O texto pode ser ampliado em 200% sem quebrar o layout
- [ ] Não há conteúdo piscando mais de 3 vezes por segundo

### Formulários
- [ ] Todo campo tem label visível
- [ ] Campos obrigatórios são indicados sem depender só de cor
- [ ] Mensagens de erro são específicas e associadas ao campo
- [ ] Estado de erro é visível por mais do que cor, como ícone, texto ou borda
- [ ] Erros de submissão do formulário são resumidos e podem receber foco
- [ ] Campos conhecidos usam autocomplete, por exemplo `type="email" autocomplete="email"`

### Conteúdo
- [ ] Idioma declarado, por exemplo `<html lang="en">`
- [ ] A página tem `<title>` descritivo
- [ ] Links se distinguem do texto ao redor sem depender só de cor
- [ ] Alvos de toque ≥ 44x44px no mobile
- [ ] Empty states significativos, e não telas em branco

## Padrões Comuns de HTML

### Botões vs. Links

```html
<!-- Use <button> para ações -->
<button onClick={handleDelete}>Delete Task</button>

<!-- Use <a> para navegação -->
<a href="/tasks/123">View Task</a>

<!-- NUNCA use div/span como botão -->
<div onClick={handleDelete}>Delete</div>  <!-- BAD -->
```

### Labels de Formulário

```html
<!-- Associação explícita de label -->
<label htmlFor="email">Email address</label>
<input id="email" type="email" required />

<!-- Associação implícita por wrapping -->
<label>
  Email address
  <input type="email" required />
</label>

<!-- Label oculta, mas label visível é preferível -->
<input type="search" aria-label="Search tasks" />
```

### Roles ARIA

```html
<!-- Navegação -->
<nav aria-label="Main navigation">...</nav>
<nav aria-label="Footer links">...</nav>

<!-- Mensagens de status -->
<div role="status" aria-live="polite">Task saved</div>

<!-- Mensagens de alerta -->
<div role="alert">Error: Title is required</div>

<!-- Diálogos modais -->
<dialog aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Delete</h2>
  ...
</dialog>

<!-- Estados de carregamento -->
<div aria-busy="true" aria-label="Loading tasks">
  <Spinner />
</div>
```

### Listas Acessíveis

```html
<ul role="list" aria-label="Tasks">
  <li>
    <input type="checkbox" id="task-1" aria-label="Complete: Buy groceries" />
    <label htmlFor="task-1">Buy groceries</label>
  </li>
</ul>
```

## Ferramentas de Teste

```bash
# Auditoria automatizada
npx axe-core          # Programmatic accessibility testing
npx pa11y             # CLI accessibility checker

# No navegador
# Chrome DevTools → Lighthouse → Accessibility
# Chrome DevTools → Elements → Accessibility tree

# Teste com leitores de tela
# macOS: VoiceOver (Cmd + F5)
# Windows: NVDA (free) or JAWS
# Linux: Orca
```

## Referência Rápida: Regiões ARIA Live

| Valor | Comportamento | Uso |
|-------|----------|---------|
| `aria-live="polite"` | Anunciado na próxima pausa | Atualizações de status, confirmações de salvamento |
| `aria-live="assertive"` | Anunciado imediatamente | Erros, alertas sensíveis ao tempo |
| `role="status"` | Equivalente a `polite` | Mensagens de status |
| `role="alert"` | Equivalente a `assertive` | Mensagens de erro |

## Antipadrões Comuns

| Antipadrão | Problema | Correção |
|---|---|---|
| `div` como botão | Não recebe foco e não tem suporte por teclado | Use `<button>` |
| `alt` ausente | Imagens ficam invisíveis para leitores de tela | Adicione `alt` descritivo |
| Estados comunicados só por cor | Invisíveis para pessoas com daltonismo | Adicione ícones, texto ou padrões |
| Mídia com autoplay | Desorienta e não pode ser interrompida | Adicione controles e evite autoplay |
| Dropdown customizado sem ARIA | Inutilizável por teclado e leitor de tela | Use `<select>` nativo ou listbox ARIA correto |
| Remover outline de foco | Usuários não veem onde estão | Estilize o foco, não o remova |
| Links ou botões vazios | Anunciados sem descrição | Adicione texto ou `aria-label` |
| `tabindex > 0` | Quebra a ordem natural de Tab | Use só `tabindex="0"` ou `-1` |
