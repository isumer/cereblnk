---
name: nuxt-coding-style
genre: constraint
category: frameworks
paths:
  - "**/pages/**/*.vue"
  - "**/composables/**/*.ts"
  - "**/server/api/**/*.ts"
---

# Nuxt Coding Style

Judgment lives in `skills/frameworks/nuxt/`.
Patterns live in [`patterns.md`](patterns.md).

## Directory roles

- A file's directory declares when it runs
- Auto-imported directories hold only what they are named for

```text
    pages/         routes, one file per route
    composables/   reusable reactive logic
    server/api/    server handlers, never imported by pages
    utils/         pure functions, no reactivity
```

Avoid: a composable holding a route. A server handler imported into a
component.

## Composables

- A composable name starts with `use` and returns refs
- State shared across components is created once

```ts
export function usePaymentStatus(reference: string) {
    const status = useState(`payment:${reference}`, () => "unknown");
    return { status };
}
```

Avoid: a composable returning plain values that lose reactivity. Module
level state created outside `useState`.

## Data fetching

- Page data is fetched with the framework's fetch helpers
- Every fetch declares a stable key

```ts
const { data: order } = await useAsyncData(
    `order:${route.params.id}`,
    () => $fetch(`/api/orders/${route.params.id}`),
);
```

Avoid: a bare `$fetch` in setup without a key. Two fetches sharing one
key by accident.

## Server handlers

- One handler per file, exported as the default
- The handler validates its input before any work

```ts
export default defineEventHandler(async (event) => {
    const body = await readValidatedBody(event, paymentSchema.parse);
    return capture(body);
});
```

Avoid: a handler exporting helpers. Input read and used without a
declared shape.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new file under pages/ or utils/ | Directory roles |
| a use* function | Composables |
| useAsyncData or $fetch | Data fetching |
| a file under server/api/ | Server handlers |
