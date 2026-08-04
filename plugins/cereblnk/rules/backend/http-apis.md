---
name: backend-http-apis
genre: constraint
category: backend
density: neutral
paths:
  - "**/controller/**/*"
  - "**/*Controller.*"
  - "**/routes/**/*"
  - "**/api/**/*"
---

# HTTP APIs

Extends [`architecture/api-design.md`](../architecture/api-design.md).
Covers REST-style and RPC-style HTTP surfaces alike.

## Shape

- A resource path names a noun; the method carries the verb
- Status codes carry meaning: created, accepted, conflict, gone

```text
POST   /orders              201 with a location
GET    /orders/{id}         200, or 404
POST   /orders/{id}/settle  202 when the work is deferred
```

Avoid: a verb in the path. Everything returning 200 with a status
field. A 500 where the caller sent something invalid.

## Requests

- The body binds to a validated type, never to a storage entity
- Query parameters are typed, bounded, and defaulted

Avoid: a filter parameter with no bound. A field a caller can set that
the server should own. Validation performed after persistence.

## Responses

- Collections paginate with a stable sort and a next cursor
- Errors carry a code, a summary, and whether retrying may help

Avoid: an unbounded list. A page whose contents shift between requests.
An error the caller must parse from prose.

## Streaming and long work

- Work longer than a request returns an accepted status and a handle
- A stream states how it ends and how a client resumes

Avoid: a request held open for minutes. A long job with no way to
check progress. A socket with no reconnection contract.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a route or method is defined | Shape |
| a payload or parameter is read | Requests |
| a response is returned | Responses |
| work outlives the request | Streaming and long work |
