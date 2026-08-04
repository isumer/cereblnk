---
name: nextjs-security
genre: constraint
category: frameworks
paths:
  - "**/app/**/*.tsx"
  - "**/app/**/*.ts"
  - "**/pages/**/*.tsx"
  - "**/next.config.*"
  - "**/middleware.ts"
---

# Next.js Security

Extends [`languages/typescript/security.md`](../../languages/typescript/security.md).

## Bundle

- A secret's absence from the client bundle is verified, not assumed
- Only variables the framework marks public reach the browser

```bash
grep -r "PAYMENT_API_KEY" .next/static && exit 1
```

Avoid: a server value read under a client boundary. A secret named
with the public prefix by mistake. A configuration object spread into
a client prop.

## Server actions and route handlers

- Every action authenticates and authorises for itself
- Being callable only from one form is not a control

```tsx
'use server'

export async function settleOrder(formData: FormData) {
  const session = await requireSession()
  const input = SettleRequest.parse(Object.fromEntries(formData))

  await service.settle(session.tenant, input.orderId)
}
```

Avoid: an action trusting the page that rendered it. An identifier
from the request used as the caller's own. A handler without an input
schema.

## Redirects and rewrites

- A redirect target is validated against an allow-list
- A rewrite never forwards a header the target should not receive

```ts
const ALLOWED = new Set(['/orders', '/settings'])

if (!ALLOWED.has(target)) {
  redirect('/orders')
}
```

Avoid: a redirect built from a query parameter. A proxy passing
cookies to a third-party origin.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an environment value is read | Bundle |
| an action or handler is added | Server actions and route handlers |
| a redirect or rewrite is configured | Redirects and rewrites |
