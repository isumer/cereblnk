---
name: react-testing
genre: constraint
category: frameworks
paths:
  - "**/*.test.tsx"
  - "**/*.test.jsx"
  - "**/*.spec.tsx"
  - "**/*.spec.jsx"
  - "**/__tests__/**/*.ts"
  - "**/__tests__/**/*.tsx"
---

# React Testing

Extends [`languages/typescript/testing.md`](../../languages/typescript/testing.md).

## Query as a user

- Elements are found by role and accessible name
- A test that a screen reader could not follow is testing markup

```jsx
render(<OrderForm onSubmit={onSubmit} />)

await user.type(screen.getByRole('textbox', { name: /reference/i }), 'ORD-1')
await user.click(screen.getByRole('button', { name: /submit/i }))

expect(onSubmit).toHaveBeenCalledWith({ reference: 'ORD-1' })
```

Avoid: a query by class name or test id where a role exists. A
selector reaching into the DOM tree. An assertion on internal state.

## Every state

- Empty, loading, error and filled each have a test
- The error path is broken once, to prove the test fails

```jsx
it('shows the error panel when the request fails', async () => {
  server.use(failingOrdersHandler)

  render(<OrderPage orderId="ord_1" />)

  expect(await screen.findByRole('alert')).toHaveTextContent(/could not load/i)
})
```

Avoid: only the filled state tested. An error state asserted by an
empty render. A snapshot standing in for the assertion.

## Async

- Waiting uses a condition, never a timer
- User interaction goes through the user-event layer

```jsx
await waitFor(() => expect(screen.getByRole('list')).toBeInTheDocument())
```

Avoid: a fixed delay before an assertion. An act warning suppressed. A
promise left un-awaited in a test body.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a component test is added | Query as a user |
| a component reads remote data | Every state |
| an interaction or a wait | Async |
