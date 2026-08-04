---
name: nextjs-coding-style
genre: constraint
category: frameworks
paths:
  - "**/app/**/page.tsx"
  - "**/app/**/layout.tsx"
  - "**/app/**/route.ts"
---

# Next.js Coding Style

Judgment lives in `skills/frameworks/nextjs/`.
Patterns live in [`patterns.md`](patterns.md).

## Component boundary

- Server is the default; `"use client"` marks a leaf, not a branch
- The directive sits at the top of the file that needs it

```tsx
"use client";

export function AmountField({ value, onChange }: Props) {
    return <input value={value} onChange={onChange} />;
}
```

Avoid: a client directive on a layout or page that wraps server work.
A server-only import reached from a client file.

## Route files

- One route file states one HTTP surface
- Handlers are named for their method and return a `Response`

```ts
export async function POST(request: Request) {
    const body = await request.json();
    return Response.json(await capture(body), { status: 201 });
}
```

Avoid: a handler branching on `request.method`. A route file exporting
helpers other files import.

## Data access

- Server components await their own data
- A fetch declares its caching intent

```tsx
export default async function OrderPage({ params }: Props) {
    const order = await getOrder(params.id, { cache: "no-store" });
    return <OrderView order={order} />;
}
```

Avoid: a page fetching through a client effect. A request whose
freshness depends on an unstated default.

## Metadata and params

- Metadata is exported, not assigned in a component body
- Route params are typed at the boundary

```tsx
export const metadata: Metadata = { title: "Order" };

type Props = { params: { id: string } };
```

Avoid: a title set through a side effect. A param read as `any`.

## Trigger table

| Seen in the diff | Section |
|---|---|
| "use client" or a component file | Component boundary |
| a route.ts handler | Route files |
| a fetch or data call in app/ | Data access |
| metadata or params typing | Metadata and params |
