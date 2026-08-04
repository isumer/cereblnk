---
name: redux-coding-style
genre: constraint
category: frameworks
paths:
  - "**/store/**/*.ts"
  - "**/*.slice.ts"
  - "**/slices/**/*.ts"
---

# Redux Coding Style

Judgment lives in `skills/frameworks/redux/`.
Patterns live in [`patterns.md`](patterns.md).

## Slice layout

- One slice owns one domain noun
- Name, initial state, and reducers are declared in that order

```ts
const paymentSlice = createSlice({
    name: "payment",
    initialState,
    reducers: {
        captureRequested(state) { state.status = "pending"; },
    },
});
```

Avoid: a slice holding two unrelated nouns. A reducer named for the
component that dispatches it.

## Action naming

- Actions are named for the event that happened
- The past tense marks a fact; the imperative marks a command

```ts
reducers: {
    captureRequested(state) { state.status = "pending"; },
    paymentCaptured(state, action: PayloadAction<Payment>) {
        state.status = "settled";
        state.current = action.payload;
    },
    refundFailed(state, action: PayloadAction<string>) {
        state.status = "failed";
        state.error = action.payload;
    },
}
```

Avoid: an action named `setState` or `updateData`. Two actions
describing the same event differently.

## Selectors

- Every read goes through a selector, colocated with its slice
- Derived values are memoised where the input is a collection

```ts
export const selectPending = createSelector(
    [selectPayments],
    (payments) => payments.filter((p) => p.status === "pending"),
);
```

Avoid: a component reaching into state shape directly. A new array
built on every render.

## Typing

- The store exports its own state and dispatch types
- Hooks are typed once and re-exported

```ts
export type RootState = ReturnType<typeof store.getState>;
export const useAppDispatch = () => useDispatch<AppDispatch>();
```

Avoid: `useSelector` typed at each call site. A dispatch cast to
`any` to accept a thunk.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a createSlice call | Slice layout |
| a new action | Action naming |
| a state read in a component | Selectors |
| useSelector or useDispatch | Typing |
