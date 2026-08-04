---
name: nuxt-patterns
genre: constraint
category: frameworks
paths:
  - "**/pages/**/*.vue"
  - "**/server/**/*.ts"
  - "**/composables/**/*.ts"
  - "**/nuxt.config.*"
---

# Nuxt Patterns

Extends [`frameworks/vue/coding-style.md`](../vue/coding-style.md).
Judgment lives in `skills/frameworks/nuxt/`.

## Where code runs

- Every route declares its rendering mode
- Server code never holds request state at module level

```ts
// server route: request scope only
export default defineEventHandler(async (event) => {
  const session = await requireSession(event)
  return listOrders(session.tenant)
})
```

Avoid: a module-level cache in server code. A composable assumed to be
request-scoped. A route whose mode the framework chose unread.

## Configuration and secrets

- Private configuration is read in server code only
- The public split is verified against the client bundle

```ts
export default defineNuxtConfig({
  runtimeConfig: {
    paymentApiKey: '',
    public: { apiBase: '/api' },
  },
})
```

Avoid: a private key read in a component. A secret named into the
public block. A configuration object spread into a client prop.

## Data

- A fetch states its side, and its result transfers rather than repeats

```ts
const { data } = await useFetch('/api/orders', {
  key: `orders-${tenant}`,
  server: true,
})
```

Avoid: the same call executed on server and client. A fetch in a
component that the route already loaded. A cached page serving last
window's data as current.

## Conventions

- Auto-imported symbols are treated as resolvable, and renames are
  traced across the directories that consume them

```text
composables/useOrders.ts   resolves as useOrders() everywhere
server/api/orders.get.ts   resolves as GET /api/orders
pages/orders/[id].vue      resolves as /orders/:id
```

Avoid: a rename applied without searching the convention's reach. A
directory layout diverging from what the framework resolves.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a route or server handler | Where code runs |
| configuration or a secret | Configuration and secrets |
| data is fetched | Data |
| a symbol is renamed or moved | Conventions |
