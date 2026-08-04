---
name: typescript-coding-style
genre: constraint
category: languages
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/typescript/`.

## Layout

- Enforcement by a formatter and a linter, both configured in the repo
- Strict compiler options on, including strict null checks
- Named exports; a default export only where a framework requires one

Avoid: a per-file lint disable · a compiler option relaxed for one
file · two formatters across a team.

## Types at the edges

- Exported functions, shared utilities and public methods declare
  parameter and return types
- Local types stay inferred where the right side names them
- A repeated inline object shape becomes a named type

```typescript
interface User {
  firstName: string
  lastName: string
}

export function formatUser(user: User): string {
  return `${user.firstName} ${user.lastName}`
}
```

Avoid: an exported function with inferred parameters · the same object
shape written at three call sites · a type restating what the
initialiser already says.

## Interface or type

- `interface` for object shapes that get extended or implemented
- `type` for unions, intersections, tuples and mapped types
- String literal unions before `enum`, unless interoperability needs one

```typescript
interface User {
  id: string
  email: string
}

type UserRole = 'admin' | 'member'
type UserWithRole = User & { role: UserRole }
```

Avoid: an enum where a union reads better · an interface holding a
union alias · a type alias duplicating an existing interface.

## `unknown`, never `any`

- External and untrusted values arrive as `unknown`, then narrow
- A generic carries the caller's type through

```typescript
function errorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message
  }
  return String(error)
}
```

Avoid: `any` in application code · a cast used to silence an error ·
`any` inside a generic signature, which launders everything after it.

## Validate at the boundary

- External data is parsed by a schema, and the type is inferred from it
- One validation per boundary; inside, the checked type is trusted

```typescript
const OrderRequest = z.object({
  id: z.string().uuid(),
  totalMinorUnits: z.number().int().nonnegative(),
})

type OrderRequest = z.infer<typeof OrderRequest>

export function parseOrder(body: unknown): OrderRequest {
  return OrderRequest.parse(body)
}
```

Avoid: an annotation on a fetch result with no runtime check · a type
declared separately from the schema that validates it · re-validation
in inner layers.

## Immutability

- Updates produce a new value; the original is left alone
- `readonly` on shapes that must not change after construction

```typescript
const updated = { ...order, settledAt }
const withItem = [...order.items, item]
```

Avoid: an in-place push on shared state · a mutation inside a map
callback · an exported mutable object.

## Async and errors

- Every promise is awaited, returned, or explicitly detached with a reason
- `try`/`catch` narrows the caught value before using it
- State read before an `await` is re-read after it

Avoid: a floating promise in a handler · a caught value used as an
`Error` without narrowing · a stale snapshot written back after a
suspension.

## Output

- No `console` statements in shipped code; use the project's logger

Avoid: a debug log left in a merged change · logging as the error
handling.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a file, export, or lint disable | Layout |
| an exported function or repeated shape | Types at the edges |
| a new named type | Interface or type |
| `any`, or a cast | `unknown`, never `any` |
| external data enters | Validate at the boundary |
| an object or array is updated | Immutability |
| a promise, or a `catch` | Async and errors |
| a `console` call | Output |
