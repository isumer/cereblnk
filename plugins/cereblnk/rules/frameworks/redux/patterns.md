---
name: redux-patterns
genre: constraint
category: frameworks
paths:
  - "**/store/**/*.ts"
  - "**/*.slice.ts"
  - "**/*Slice.ts"
  - "**/reducers/**/*.ts"
  - "**/selectors/**/*.ts"
---

# Redux Patterns

Extends [`frameworks/react/patterns.md`](../react/patterns.md).
Judgment lives in `skills/frameworks/redux/`.

## What belongs in the store

- Global, shared, or persisted state; nothing else
- Server data belongs to a data layer, not to hand-written reducers

Avoid: form state in the store. A value one component reads. A cache
of remote data maintained by reducers.

## Reducers

- A reducer is pure: same input, same output, no side effect
- Updates are immutable, whatever the syntax looks like

```typescript
const ordersSlice = createSlice({
  name: 'orders',
  initialState,
  reducers: {
    selected(state, action: PayloadAction<OrderId>) {
      state.selectedId = action.payload
    },
  },
})
```

Avoid: a fetch inside a reducer. A random value or timestamp generated
there. An object replaced by mutation outside the producer.

## Selectors

- Components read through selectors, never the raw state shape
- A derived value is memoised where it builds a new object

```typescript
const selectOverdue = createSelector(
  [selectOrders],
  (orders) => orders.filter((order) => order.isOverdue),
)
```

Avoid: a component reaching into the state tree. A selector returning
a new array every call. State shape leaking into a template.

## Actions

- An action describes what happened, not what to do
- One event dispatches one action

Avoid: an action named as a setter. Three actions expressing one
event. An action carrying a component reference.

## Trigger table

| Seen in the diff | Section |
|---|---|
| state is added to the store | What belongs in the store |
| a reducer is written | Reducers |
| a component reads state | Selectors |
| an action is dispatched | Actions |
