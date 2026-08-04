---
name: backend-authorization
genre: constraint
category: backend
density: neutral
paths:
  - "**/auth/**/*"
  - "**/*Permission*.*"
  - "**/security/**/*"
---

# Authorization

Extends [`common/security.md`](../common/security.md).

## Every path, deliberately

- Access is denied by default; each path states its rule
- A new path is unreachable until its rule exists

Avoid: a permit-all fallback. A path protected by being unguessable. A
rule ordered after a broader match that already accepted it.

## Ownership

- An ownership check compares the authenticated principal to the resource
- An identifier from the request is never treated as the caller's own

```text
authenticated principal    who the caller is
requested resource         what they asked for
decision                   computed from both, on the server
```

Avoid: a tenant identifier read from the body. A check that trusts a
client-side filter. An administrative path sharing a method with a
tenant path.

## Data scope

- A query filters by the principal's scope, inside the query
- Results are never filtered in memory after loading everything

Avoid: a repository method reachable with no scope. A list endpoint
returning other tenants' rows before filtering. Isolation assumed from
a filter no test exercises.

## Changes

- A permission change is recorded, with who made it and why
- Elevation is temporary, scoped, and expires on its own

Avoid: a role widened to unblock a failure. A grant with no expiry. An
audit record the acting party can delete.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a path or handler is added | Every path, deliberately |
| a resource is accessed by identifier | Ownership |
| a query returns rows | Data scope |
| a permission is granted | Changes |
