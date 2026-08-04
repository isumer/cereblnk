---
name: nextjs-patterns
genre: constraint
category: frameworks
paths:
  - "**/app/**/*.tsx"
  - "**/app/**/*.ts"
  - "**/pages/**/*.tsx"
  - "**/next.config.*"
  - "**/middleware.ts"
---

# Next.js Patterns

Extends [`frameworks/react/patterns.md`](../react/patterns.md).
Judgment lives in `skills/frameworks/nextjs/`.

## The boundary

- A client boundary sits at the smallest subtree that needs interactivity
- Server-only modules never enter a client component's import graph

```tsx
// server component: no directive needed
export default async function OrdersPage() {
  const orders = await listOrders()
  return <OrderTable orders={orders} filters={<Filters />} />
}
```

Avoid: a client directive near the tree root. A server utility
imported by a client component. A third-party client library pulling a
server subtree across.

## Rendering strategy

- Every route states its strategy, and its revalidation window
- Freshness is configured, not assumed

```tsx
// static, revalidated every minute
export const revalidate = 60

// always rendered per request
export const dynamic = 'force-dynamic'

// cached fetch, explicit about its window
const orders = await fetch(url, { next: { revalidate: 30 } })
```

Avoid: a route whose strategy the framework chose unread. A cached
page serving last window's data as current. A dynamic segment made
static by an unnoticed default.

## Data flow

- Data is fetched where it is rendered, not passed down through props
- Sequential awaits in nested components become a waterfall

```tsx
const [orders, customers] = await Promise.all([
  listOrders(tenant),
  listCustomers(tenant),
])
```

Avoid: a fetch in a parent passed to three children. Awaited calls
nested one inside another. A client component refetching what the
server already had.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a client directive or an import | The boundary |
| a route or its caching changes | Rendering strategy |
| data is fetched | Data flow |
