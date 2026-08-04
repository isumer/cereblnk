---
name: react-coding-style
genre: constraint
category: frameworks
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**/*.ts"
  - "**/components/**/*.tsx"
---

# React Coding Style

Extends [`languages/typescript/coding-style.md`](../../languages/typescript/coding-style.md).

## Components

- One component per file, named for the file, exported by name
- Props are typed and destructured at the signature

```tsx
interface OrderRowProps {
  order: Order
  onSettle: (id: OrderId) => void
}

export function OrderRow({ order, onSettle }: OrderRowProps) {
  return <tr onClick={() => onSettle(order.id)}>{order.reference}</tr>
}
```

Avoid: two components in one file. Props read from a single untyped
object. A default export where the name matters.

## Markup

- Conditional rendering returns early, or uses one guarded expression
- A fragment wraps siblings; a wrapper element needs a reason

```tsx
export function OrderPanel({ order }: OrderPanelProps) {
  if (!order) {
    return <EmptyPanel />
  }

  return (
    <>
      <OrderHeader order={order} />
      <OrderItems items={order.items} />
    </>
  )
}
```

Avoid: three nested ternaries in a return. A div added only to satisfy
a single-root rule. Logic computed inside the markup.

## Files

- A component's styles, tests and stories sit beside it

Avoid: a component split across four folders by file kind. A shared
folder that grows without a boundary.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a component is written | Components |
| markup is returned | Markup |
| a file is added | Files |
