---
name: javascript-patterns
genre: constraint
category: languages
paths:
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
---

# JavaScript Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Modelling states

- A closed set of outcomes carries a discriminant field and its payload
- Every branch of the discriminant is handled

```javascript
function describe(result) {
  switch (result.status) {
    case 'captured':
      return `captured ${result.amount}`
    case 'declined':
      return `declined ${result.code}`
    case 'deferred':
      return `retry after ${result.retryAfter}`
    default:
      throw new Error(`unknown settlement status: ${result.status}`)
  }
}
```

Avoid: optional fields standing in for a variant · a silent default
branch · two booleans encoding three states.


## Absence

- A value that may be missing says so in the type
- `null` and `undefined` are distinguished, or one is chosen repo-wide

Avoid: optional chaining used to hide an unmodelled absence · a falsy
check where zero or an empty string is data.

## Data access

- Storage sits behind one module per aggregate, returning domain types
- The caller never sees the transport shape

Avoid: a query builder leaking into a component · a response type used
as the domain model · a fetch call inside rendering logic.

## Contracts

- A response envelope is one shape across every endpoint
- Errors carry a stable code, not a message the caller parses

```javascript
const ok = (data) => ({ ok: true, data })
const fail = (code, message) => ({ ok: false, code, message })
```

Avoid: a bare array on success and an object on failure · a caller
branching on a message string.


## Trigger table

| Seen in the diff | Section |
|---|---|
| a closed set of outcomes | Modelling states |
| a value may be missing | Absence |
| storage or transport is touched | Data access |
| an endpoint shape is defined | Contracts |
