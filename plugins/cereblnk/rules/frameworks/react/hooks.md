---
name: react-hooks
genre: constraint
category: frameworks
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/hooks/**/*.ts"
  - "**/hooks/**/*.js"
  - "**/use-*.ts"
  - "**/use-*.tsx"
---

# React Hooks

Extends [`frameworks/react/patterns.md`](./patterns.md). The linter's
hook rules are enabled and not suppressed.

## Call order

- Hooks are called unconditionally, at the top level of a component or
  another hook

```jsx
function OrderPanel({ orderId, visible }) {
  const order = useOrder(orderId)

  if (!visible) return null

  return <OrderView order={order} />
}
```

Avoid: a hook inside a condition, a loop, or a callback. An early
return above a hook. A suppression on the hook rules.

## Effects

- An effect synchronises with something outside React
- Nothing else belongs in one
- Deriving, transforming and event handling are not effects

```jsx
useEffect(() => {
  const subscription = socket.subscribe(orderId, onUpdate)
  return () => subscription.unsubscribe()
}, [orderId, onUpdate])
```

Avoid: an effect computing state from props. An effect chained to
another effect's write. An effect fetching what a data library owns.

## Dependencies and cleanup

- The dependency array lists everything the effect reads
- Anything the effect started, it stops

```jsx
useEffect(() => {
  const timer = setInterval(refresh, intervalMs)
  return () => clearInterval(timer)
}, [refresh, intervalMs])
```

Avoid: a dependency omitted to stop a loop. An empty array chosen for
convenience. A subscription or timer with no teardown.

## Stale values

- A value captured in a closure is the value from that render
- Reading the latest requires a ref, a functional update, or a
  dependency

```jsx
setCount((current) => current + 1)
```

Avoid: state read inside a timer and written back. A handler holding
a prop from an old render. A value not re-read after an await.

## Memoisation

- Memoise where a measured cost or a referential identity requires it

```jsx
const totals = useMemo(
  () => orders.reduce((sum, order) => sum + order.total, 0),
  [orders],
)
```

Avoid: a memo wrapping every component by default. A callback
memoised for a child that re-renders anyway. An array kept for an
unmeasured gain.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a hook is called | Call order |
| an effect is added | Effects |
| a dependency array is written | Dependencies and cleanup |
| a closure reads state | Stale values |
| a memo or callback is wrapped | Memoisation |
