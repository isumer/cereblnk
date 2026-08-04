---
name: redux-testing
genre: constraint
category: frameworks
paths:
  - "**/*.slice.test.ts"
  - "**/store/**/*.test.ts"
  - "**/slices/**/*.test.ts"
---

# Redux Testing

Judgment lives in `skills/frameworks/redux/`.
Style constraints live in [`coding-style.md`](coding-style.md).

## Reducers

- A reducer is tested as a pure function of state and action
- Each test names the transition it asserts

```ts
it("moves to pending on captureRequested", () => {
    const next = reducer(initialState, captureRequested());

    expect(next.status).toBe("pending");
    expect(next.error).toBeUndefined();
});
```

Avoid: a reducer tested through a rendered component. A test asserting
the whole state object as one snapshot.

## Selectors

- Selectors are tested against a hand-built state
- Memoised selectors are asserted for identity across calls

```ts
const state = { payments: { items: [pending, settled] } };

expect(selectPending(state)).toEqual([pending]);
expect(selectPending(state)).toBe(selectPending(state));
```

Avoid: a selector test built from a reducer sequence. A memoised
selector whose identity is never checked.

## Async flows

- Thunks are tested with a real store and a faked boundary
- Both the resolved and the rejected path are asserted

```ts
const store = makeStore({ api: { capture: async () => payment } });

await store.dispatch(capturePayment("ref-1"));

expect(store.getState().payment.status).toBe("settled");
```

Avoid: a thunk tested by inspecting dispatched action names alone. A
flow whose failure branch is never exercised.

## Store wiring

- The store's assembled shape is asserted once
- A new slice is added to that assertion

```ts
const state = makeStore().getState();

expect(Object.keys(state).sort())
    .toEqual(["order", "payment", "session"]);
```

Avoid: a slice registered and never reached by any test. Two stores
built differently in tests and production.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a reducer case | Reducers |
| a selector | Selectors |
| a thunk or async action | Async flows |
| a slice added to the store | Store wiring |
