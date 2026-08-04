---
name: typescript-security
genre: constraint
category: languages
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/tsconfig*.json"
---

# TypeScript Security

Extends [`common/security.md`](../../common/security.md).

## Rendering

- Values are escaped for the destination that renders them
- Raw HTML insertion needs a sanitiser and a stated reason

```typescript
// the framework escapes this
<span>{comment.body}</span>

// raw insertion is sanitised, and the reason is stated
<article dangerouslySetInnerHTML={{ __html: sanitize(article.html) }} />
```

Avoid: user text placed into markup unescaped · a sanitiser skipped
because the value looked internal · an attribute built by string
concatenation.

## Secrets

- Only variables the build marks public reach the client bundle
- Server-only modules are proven absent from the client bundle

```typescript
const apiKey = process.env.PAYMENT_API_KEY

if (!apiKey) {
  throw new Error('PAYMENT_API_KEY is not configured')
}
```

Avoid: a key read inside a client component · a secret named with the
public prefix by mistake · a credential in a committed fixture.

## Input

- Every external payload is parsed by a schema before use
- Identifiers used in a path or a query are validated first

```typescript
export async function handler(request: Request) {
  const order = OrderRequest.parse(await request.json())
  return repository.save(order)
}
```

Avoid: a request body spread into a database call · a path segment
taken from a parameter without checking · a redirect target from user
input.

## Dependencies

- The lock file is committed; the tree is audited on change
- Install scripts from new packages are reviewed before running

Avoid: an unaudited transitive addition · a package added to fix a
type error.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a value reaches markup | Rendering |
| an environment variable is read | Secrets |
| an external payload is used | Input |
| a package is added or updated | Dependencies |
