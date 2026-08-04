---
name: vue-coding-style
genre: constraint
category: frameworks
paths:
  - "**/*.vue"
  - "**/composables/**/*.ts"
  - "**/use*.ts"
---

# Vue Coding Style

Extends [`languages/typescript/coding-style.md`](../../languages/typescript/coding-style.md).
Judgment lives in `skills/frameworks/vue/`.

## Components

- One component per file, named for the file, props typed
- Emitted events are named for the domain, not for the widget

```vue
<script setup lang="ts">
interface Props {
  order: Order
}

const props = defineProps<Props>()
const emit = defineEmits<{ settleRequested: [id: OrderId] }>()

const isOverdue = computed(() => props.order.dueDate < new Date())
</script>
```

Avoid: two components in one file. An untyped prop. An emitted event
named after a click.

## Reactivity

- Derivation is computed; watchers are for external effects
- A reactive source is read through its container, never destructured

```vue
<script setup lang="ts">
const store = useOrderStore()
const overdue = computed(() => store.orders.filter((o) => o.isOverdue))
</script>
```

Avoid: a destructured reactive object. A watcher assigning a value a
computed would derive. Two watchers writing each other's sources.

## Lifecycle

- Whatever is started on mount is stopped on unmount, in one place

```vue
<script setup lang="ts">
onMounted(() => {
  const timer = setInterval(refresh, intervalMs)
  onUnmounted(() => clearInterval(timer))
})
</script>
```

Avoid: a listener with no teardown. A subscription created in a
computed. A timer surviving the component.

## Templates

- A template reads values; computation lives in the script block
- Every list key identifies the item, never its index

Avoid: a method call in a binding. Three nested conditions in markup. A
key built from a value that changes.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a component or prop is declared | Components |
| a value derives from another | Reactivity |
| something is started on mount | Lifecycle |
| markup binds or iterates | Templates |
