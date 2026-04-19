---
name: frontend-ui-engineering
description: Constrói UIs com qualidade de produção. Use ao criar ou modificar interfaces voltadas ao usuário. Use ao criar componentes, implementar layouts, gerenciar estado ou quando a saída precisar parecer e se comportar como algo de produção, e não gerado por IA.
---

# Frontend UI Engineering

## Visão Geral

Construa interfaces com qualidade de produção, acessíveis, performáticas e visualmente refinadas. O objetivo é uma UI que pareça ter sido feita por um engenheiro com senso de design em uma empresa de alto nível, e não algo gerado por IA. Isso exige aderência real ao design system, acessibilidade adequada, padrões de interação bem pensados e nada de uma estética genérica de "cara de IA".

## Quando Usar

- Ao criar novos componentes ou páginas de UI
- Ao modificar interfaces existentes voltadas ao usuário
- Ao implementar layouts responsivos
- Ao adicionar interatividade ou gerenciamento de estado
- Ao corrigir problemas visuais ou de UX

## Arquitetura de Componentes

### Estrutura de Arquivos

Mantenha juntos todos os artefatos relacionados a um componente:

```
src/components/
  TaskList/
    TaskList.tsx          # Implementação do componente
    TaskList.test.tsx     # Testes
    TaskList.stories.tsx  # Stories do Storybook (se usar)
    use-task-list.ts      # Hook customizado (se o estado for complexo)
    types.ts              # Tipos específicos do componente (se necessário)
```

### Padrões de Componentes

**Prefira composição em vez de configuração:**

```tsx
// Bom: componível
<Card>
  <CardHeader>
    <CardTitle>Tarefas</CardTitle>
  </CardHeader>
  <CardBody>
    <TaskList tasks={tasks} />
  </CardBody>
</Card>

// Evite: configuração excessiva
<Card
  title="Tarefas"
  headerVariant="large"
  bodyPadding="md"
  content={<TaskList tasks={tasks} />}
/>
```

**Mantenha os componentes focados:**

```tsx
// Bom: faz uma coisa só
export function TaskItem({ task, onToggle, onDelete }: TaskItemProps) {
  return (
    <li className="flex items-center gap-3 p-3">
      <Checkbox checked={task.done} onChange={() => onToggle(task.id)} />
      <span className={task.done ? 'line-through text-muted' : ''}>{task.title}</span>
      <Button variant="ghost" size="sm" onClick={() => onDelete(task.id)}>
        <TrashIcon />
      </Button>
    </li>
  );
}
```

**Separe busca de dados da apresentação:**

```tsx
// Container: cuida dos dados
export function TaskListContainer() {
  const { tasks, isLoading, error } = useTasks();

  if (isLoading) return <TaskListSkeleton />;
  if (error) return <ErrorState message="Falha ao carregar tarefas" retry={refetch} />;
  if (tasks.length === 0) return <EmptyState message="Ainda não há tarefas" />;

  return <TaskList tasks={tasks} />;
}

// Apresentação: cuida da renderização
export function TaskList({ tasks }: { tasks: Task[] }) {
  return (
    <ul role="list" className="divide-y">
      {tasks.map(task => <TaskItem key={task.id} task={task} />)}
    </ul>
  );
}
```

## Gerenciamento de Estado

**Escolha a abordagem mais simples que resolva o problema:**

```
Estado local (useState)          → Estado de UI específico do componente
Estado elevado                   → Compartilhado entre 2-3 componentes irmãos
Context                          → Tema, autenticação, localidade (muita leitura, pouca escrita)
Estado na URL (searchParams)     → Filtros, paginação, estado compartilhável da UI
Estado de servidor (React Query, SWR) → Dados remotos com cache
Store global (Zustand, Redux)    → Estado complexo do cliente compartilhado na aplicação
```

**Evite prop drilling com profundidade maior que 3 níveis.** Se você está passando props por componentes que não as usam, introduza contexto ou reestruture a árvore de componentes.

## Aderência ao Design System

### Evite a Estética de IA

Interfaces geradas por IA costumam seguir padrões reconhecíveis. Evite todos eles:

| Padrão de IA | Por Que É um Problema | Qualidade de Produção |
|---|---|---|
| Tudo roxo/índigo | Modelos tendem a paletas visualmente "seguras", deixando todo app com a mesma aparência | Use a paleta real do projeto |
| Gradientes em excesso | Gradientes adicionam ruído visual e entram em conflito com a maioria dos design systems | Gradientes discretos ou superfícies planas alinhadas ao design system |
| Tudo muito arredondado (`rounded-2xl`) | Arredondamento máximo passa sensação de "amigável", mas ignora a hierarquia real de raios de borda | `border-radius` consistente com o design system |
| Hero sections genéricas | Layout de template sem relação com o conteúdo real nem com a necessidade do usuário | Layout orientado pelo conteúdo |
| Texto estilo lorem ipsum | Placeholder esconde problemas de layout que só aparecem com conteúdo real, como comprimento, quebra e overflow | Conteúdo de placeholder realista |
| Padding exagerado em todo lugar | Espaçamento generoso e uniforme destrói hierarquia visual e desperdiça área útil | Escala de espaçamento consistente |
| Grades genéricas de cards | Grades uniformes são atalho de layout que ignoram prioridade da informação e padrões de leitura | Layout orientado pelo propósito |
| Design carregado de sombras | Sombras em camadas competem com o conteúdo e degradam renderização em dispositivos modestos | Sombras sutis ou nenhuma, salvo exigência do design system |

### Espaçamento e Layout

Use uma escala de espaçamento consistente. Não invente valores:

```css
/* Use a escala: incrementos de 0.25rem (ou a escala adotada pelo projeto) */
/* Bom */   padding: 1rem;      /* 16px */
/* Bom */   gap: 0.75rem;       /* 12px */
/* Ruim */  padding: 13px;      /* Fora da escala */
/* Ruim */  margin-top: 2.3rem; /* Fora da escala */
```

### Tipografia

Respeite a hierarquia tipográfica:

```
h1 → Título da página (um por página)
h2 → Título de seção
h3 → Título de subseção
body → Texto padrão
small → Texto secundário/de apoio
```

Não pule níveis de heading. Não use estilo de heading em conteúdo que não seja título.

### Cor

- Use tokens semânticos de cor: `text-primary`, `bg-surface`, `border-default`, e não valores hexadecimais crus
- Garanta contraste suficiente (4.5:1 para texto normal, 3:1 para texto grande)
- Não dependa apenas de cor para comunicar informação; use também ícones, texto ou padrões

## Acessibilidade (WCAG 2.1 AA)

Todo componente deve atender a estes padrões:

### Navegação por Teclado

```tsx
// Todo elemento interativo deve ser acessível por teclado
<button onClick={handleClick}>Clique aqui</button>        // ✓ Focável por padrão
<div onClick={handleClick}>Clique aqui</div>               // ✗ Não é focável
<div role="button" tabIndex={0} onClick={handleClick}    // ✓ Mas prefira <button>
     onKeyDown={e => {
       if (e.key === 'Enter') handleClick();
       if (e.key === ' ') e.preventDefault();
     }}
     onKeyUp={e => {
       if (e.key === ' ') handleClick();
     }}>
  Clique aqui
</div>
```

### Rótulos ARIA

```tsx
// Rotule elementos interativos que não têm texto visível
<button aria-label="Fechar diálogo"><XIcon /></button>

// Rotule campos de formulário
<label htmlFor="email">E-mail</label>
<input id="email" type="email" />

// Ou use aria-label quando não houver rótulo visível
<input aria-label="Buscar tarefas" type="search" />
```

### Gerenciamento de Foco

```tsx
// Mova o foco quando o conteúdo mudar
function Dialog({ isOpen, onClose }: DialogProps) {
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (isOpen) closeRef.current?.focus();
  }, [isOpen]);

  // Prende o foco dentro do diálogo quando ele estiver aberto
  return (
    <dialog open={isOpen}>
      <button ref={closeRef} onClick={onClose}>Fechar</button>
      {/* conteúdo do diálogo */}
    </dialog>
  );
}
```

### Estados Vazios e de Erro com Significado

```tsx
// Não mostre telas em branco
function TaskList({ tasks }: { tasks: Task[] }) {
  if (tasks.length === 0) {
    return (
      <div role="status" className="text-center py-12">
        <TasksEmptyIcon className="mx-auto h-12 w-12 text-muted" />
        <h3 className="mt-2 text-sm font-medium">Sem tarefas</h3>
        <p className="mt-1 text-sm text-muted">Comece criando uma nova tarefa.</p>
        <Button className="mt-4" onClick={onCreateTask}>Criar tarefa</Button>
      </div>
    );
  }

  return <ul role="list">...</ul>;
}
```

## Design Responsivo

Projete para mobile primeiro e expanda a partir daí:

```tsx
// Tailwind: responsividade mobile-first
<div className="
  grid grid-cols-1      /* Mobile: uma coluna */
  sm:grid-cols-2        /* Small: 2 colunas */
  lg:grid-cols-3        /* Large: 3 colunas */
  gap-4
">
```

Teste nestes breakpoints: 320px, 768px, 1024px e 1440px.

## Loading e Transições

```tsx
// Skeleton loading, e não spinner para conteúdo
function TaskListSkeleton() {
  return (
    <div className="space-y-3" aria-busy="true" aria-label="Carregando tarefas">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="h-12 bg-muted animate-pulse rounded" />
      ))}
    </div>
  );
}

// Atualizações otimistas para melhorar a velocidade percebida
function useToggleTask() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: toggleTask,
    onMutate: async (taskId) => {
      await queryClient.cancelQueries({ queryKey: ['tasks'] });
      const previous = queryClient.getQueryData(['tasks']);

      queryClient.setQueryData(['tasks'], (old: Task[]) =>
        old.map(t => t.id === taskId ? { ...t, done: !t.done } : t)
      );

      return { previous };
    },
    onError: (_err, _taskId, context) => {
      queryClient.setQueryData(['tasks'], context?.previous);
    },
  });
}
```

## Veja Também

Para requisitos detalhados de acessibilidade e ferramentas de teste, veja `references/accessibility-checklist.md`.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Acessibilidade é opcional" | Em muitas jurisdições, é exigência legal e padrão de qualidade de engenharia. |
| "Depois a gente deixa responsivo" | Adaptar responsividade depois é 3 vezes mais difícil do que construir certo desde o início. |
| "O design não está finalizado, então vou pular a estilização" | Use os padrões do design system. UI sem estilo passa uma primeira impressão ruim para quem revisa. |
| "Isso é só um protótipo" | Protótipos viram código de produção. Construa a base corretamente. |
| "A estética de IA serve por enquanto" | Isso sinaliza baixa qualidade. Use o design system real do projeto desde o começo. |

## Sinais de Alerta

- Componentes com mais de 200 linhas (divida-os)
- Estilos inline ou valores arbitrários em pixels
- Ausência de estados de erro, loading ou vazio
- Nenhum teste de navegação por teclado
- Cor como único indicador de estado (vermelho/verde sem texto ou ícones)
- Visual genérico com "cara de IA" (gradientes roxos, cards oversized, layouts de catálogo)

## Verificação

Depois de construir a UI:

- [ ] O componente renderiza sem erros no console
- [ ] Todos os elementos interativos são acessíveis por teclado (navegue com Tab pela página)
- [ ] Um leitor de tela consegue transmitir o conteúdo e a estrutura da página
- [ ] Responsivo: funciona em 320px, 768px, 1024px e 1440px
- [ ] Estados de loading, erro e vazio foram tratados
- [ ] Segue o design system do projeto (espaçamento, cores, tipografia)
- [ ] Não há avisos de acessibilidade no dev tools nem no axe-core
