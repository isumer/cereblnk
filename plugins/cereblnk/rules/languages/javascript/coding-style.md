---
name: javascript-coding-style
genre: constraint
category: languages
paths:
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
---

# JavaScript Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/javascript/`.

## Layout

- Enforcement by a formatter and a linter, both configured in the repo
- Modules use named exports; a default export only where required
- `const` by default, `let` where reassignment is the point, never `var`

```javascript
export const MAXIMUM_ATTEMPTS = 3

export function settle(order) {
  let attempt = 0
  while (attempt < MAXIMUM_ATTEMPTS) {
    attempt += 1
  }
}
```

Avoid: a per-file lint disable · a formatter run only on some files ·
a variable reassigned across a function's whole body.

## Types without a compiler

- JSDoc where a shape is not obvious from the code
- The annotation matches runtime behavior, or it is removed

```javascript
/**
 * @param {{ firstName: string, lastName: string }} user
 * @returns {string}
 */
export function formatUser(user) {
  return `${user.firstName} ${user.lastName}`
}
```

Avoid: JSDoc describing a shape the function no longer accepts · a
type comment on an obvious local · documentation standing in for a
runtime check.

## Equality and absence

- Strict equality; a loose comparison states its reason
- Absence is checked against `null` and `undefined`, not falsiness

```javascript
if (value === null || value === undefined) {
  return fallback
}
```

Avoid: a falsy check gating on a number or a string · `==` used out of
habit · optional chaining hiding an unmodelled absence.

## Immutability

- Updates produce a new value; the original is left alone

```javascript
const updated = { ...order, settledAt }
const withItem = [...order.items, item]
```

Avoid: an in-place push on shared state · a mutation inside a map
callback · an exported mutable object.

## Async

- Every promise is awaited, returned, or detached with a stated reason
- State read before an `await` is re-read after it
- A rejection has a named handler

```javascript
export async function settle(order) {
  const captured = await gateway.capture(order.total)
  return ledger.record(captured)
}
```

Avoid: a floating promise in a handler · a stale snapshot written back
after a suspension · ordering that depends on resolution speed.

## Output

- No `console` statements in shipped code; use the project's logger

```javascript
logger.warn({ event: 'settlement.deferred', orderId, retryAfter })
```

Avoid: a debug log left in a merged change · logging as the error
handling.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a module, export, or declaration | Layout |
| a non-obvious shape | Types without a compiler |
| a comparison or a presence check | Equality and absence |
| an object or array is updated | Immutability |
| a promise, or a `catch` | Async |
| a `console` call | Output |
