---
name: vue-patterns
genre: constraint
category: frameworks
paths:
  - "**/*.vue"
  - "**/composables/**/*.ts"
---

# Vue Patterns

Judgment lives in `skills/frameworks/vue/`.
Style constraints live in [`coding-style.md`](coding-style.md).

## Component contract

- Props are declared with types and defaults
- A component emits events; it does not write to its props

```vue
<script setup lang="ts">
const props = withDefaults(defineProps<{
    amount: number;
    currency?: string;
}>(), { currency: "EUR" });

const emit = defineEmits<{ capture: [reference: string] }>();
</script>
```

Avoid: a prop mutated inside the child. An emitted event with an
undeclared payload.

## Reactivity

- `ref` holds a value; `reactive` holds an object that stays whole
- Derived state is computed, never assigned in a watcher

```ts
const payments = ref<Payment[]>([]);
const pending = computed(() =>
    payments.value.filter((p) => p.status === "pending"));
```

Avoid: a watcher writing a value another computed could derive. A
reactive object replaced wholesale, losing its reactivity.

## Composables

- A composable owns one concern and returns refs
- Cleanup is registered where the effect is created

```ts
export function usePolling(run: () => void, ms: number) {
    const id = setInterval(run, ms);
    onScopeDispose(() => clearInterval(id));
}
```

Avoid: a composable that both fetches and renders. An interval or
listener left running after the scope ends.

## Template boundaries

- Templates read state and call handlers, nothing more
- Conditional rendering and iteration do not share one element

```vue
<template>
    <ul>
        <li v-for="p in pending" :key="p.reference">
            {{ p.reference }}
        </li>
    </ul>
</template>
```

Avoid: business logic inside an interpolation. `v-if` and `v-for` on
one element, where precedence decides the meaning.

## Trigger table

| Seen in the diff | Section |
|---|---|
| defineProps or defineEmits | Component contract |
| ref, reactive, computed, or watch | Reactivity |
| a use* function | Composables |
| a template block | Template boundaries |
