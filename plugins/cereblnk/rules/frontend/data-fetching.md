---
name: frontend-data-fetching
genre: constraint
category: frontend
density: neutral
paths:
  - "**/api/**/*"
  - "**/hooks/**/*"
  - "**/services/**/*"
---

# Frontend Data Fetching

Extends [`state-management.md`](state-management.md) and
[`../backend/http-apis.md`](../backend/http-apis.md).

## Ownership

- One place owns a request; components read its result
- Server state and client state are kept apart

Avoid: two components fetching the same resource independently. Server
responses copied into local state and edited there.

## Request lifecycle

- Every request has a declared key, so it can be shared and invalidated
- Loading, empty, error and success are all represented

```text
    key          identifies the request and its inputs
    loading      distinct from empty
    error        carries what the user can do next
    stale        known, and refreshed on a stated trigger
```

Avoid: a boolean flag standing in for four states. A cache entry no
code can invalidate.

## Cancellation and races

- A request whose result is no longer wanted is cancelled
- The last request issued is the one whose result is applied

Avoid: a slow earlier response overwriting a newer one. A fetch left
running after its view unmounts.

## Mutations

- A mutation states what it invalidates
- Optimistic updates declare their rollback

Avoid: a write followed by a manual refetch of everything. An
optimistic change with no path back when the server disagrees.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a fetch, query, or service call | Ownership |
| a loading or error branch | Request lifecycle |
| an effect that fetches on a changing input | Cancellation and races |
| a create, update, or delete call | Mutations |
