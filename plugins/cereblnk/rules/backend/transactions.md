---
name: backend-transactions
genre: constraint
category: backend
density: neutral
paths:
  - "**/service/**/*"
  - "**/*Service.*"
---

# Transactions

Extends [`common/patterns.md`](../common/patterns.md).

## The boundary

- The unit of work is the operation that must succeed or fail whole
- It opens in the service, not in a repository or a controller

Avoid: a transaction per repository call. A boundary opened at the
edge and held through rendering. A method annotated but never proxied.

## What stays outside

- Remote calls, queue publishes and file writes happen outside the lock
- A long-running step never holds a transaction open

```text
inside    reads and writes to the owned store
outside   payment capture, notification, object upload
between   an outbox row written inside, published after
```

Avoid: a payment gateway called inside a transaction. A lock held for
the duration of an upload. A retry that reopens a transaction around a
remote call.

## Concurrency

- Contended rows use optimistic locking with a version, or a stated
  pessimistic lock
- A conflict has a defined resolution, not a retry loop

Avoid: a lost update discovered by a customer. A pessimistic lock with
no timeout. Optimistic locking added after the first conflict.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a unit of work spans writes | The boundary |
| a remote or slow call appears | What stays outside |
| two writers can meet | Concurrency |
