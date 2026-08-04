---
name: react-patterns
genre: constraint
category: frameworks
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**/*.ts"
  - "**/components/**/*.tsx"
  - "**/app/**/*.tsx"
  - "**/pages/**/*.tsx"
---

# React Patterns

Extends [`languages/typescript/patterns.md`](../../languages/typescript/patterns.md).
Judgment lives in `skills/frameworks/react/`.

## State location

- State lives at the lowest component that needs it
- Shared state moves up one level, not to a global store by default
- Server data is not copied into component state

```jsx
function OrderFilters({ onChange }) {
  const [term, setTerm] = useState('')

  return <input value={term} onChange={(e) => setTerm(e.target.value)} />
}
```

Avoid: a global store holding what one subtree uses · state lifted
three levels for one reader · a fetch result mirrored into `useState`.

## Rendering states

- Every data-dependent component renders empty, loading, error and
  filled — all four are written, not assumed

```jsx
if (query.isLoading) return <Spinner />
if (query.error) return <ErrorPanel error={query.error} />
if (query.data.length === 0) return <EmptyOrders />

return <OrderList orders={query.data} />
```

Avoid: a component with only the filled path · an error state rendered
as an empty one · a loading flicker nobody designed.

## Lists

- A key identifies the item, not its position
- A list item's identity survives reordering and filtering

```jsx
{orders.map((order) => (
  <OrderRow key={order.id} order={order} />
))}
```

Avoid: an array index used as a key · a key built from a value that
changes · a fragment wrapping a list with no key.

## Composition

- A component renders, or it decides — rarely both
- Shared behavior moves into a hook, not a wrapper hierarchy

```jsx
function OrderPage({ orderId }) {
  const order = useOrder(orderId)
  return <OrderView order={order} />
}
```

Avoid: a component fetching, deciding, and rendering in one body · a
provider added to pass one value two levels · a render prop where a
hook reads better.

## Trigger table

| Seen in the diff | Section |
|---|---|
| state is introduced or lifted | State location |
| a component reads remote data | Rendering states |
| a collection is rendered | Lists |
| a component grows past one job | Composition |
