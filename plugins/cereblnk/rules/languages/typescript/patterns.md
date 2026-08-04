---
name: typescript-patterns
genre: constraint
category: languages
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Modelling states

- A closed set of outcomes is a discriminated union, checked exhaustively
- Two booleans never encode three states

```typescript
type Settlement =
  | { status: 'captured'; transactionId: string; amount: number }
  | { status: 'declined'; code: string }
  | { status: 'deferred'; retryAfter: string }

function describe(result: Settlement): string {
  switch (result.status) {
    case 'captured':
      return `captured ${result.amount}`
    case 'declined':
      return `declined ${result.code}`
    case 'deferred':
      return `retry after ${result.retryAfter}`
  }
}
```

Avoid: optional fields standing in for a variant · a `default` branch
hiding an unhandled case · a status string with no payload constraint.

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

```typescript
type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; code: string; message: string }
```

Avoid: an endpoint returning a bare array on success and an object on
failure · a caller branching on a message string.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a closed set of outcomes | Modelling states |
| a value may be missing | Absence |
| storage or transport is touched | Data access |
| an endpoint shape is defined | Contracts |
