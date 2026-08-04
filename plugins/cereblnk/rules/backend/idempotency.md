---
name: backend-idempotency
genre: constraint
category: backend
density: neutral
paths:
  - "**/*Controller.*"
  - "**/handlers/**/*"
  - "**/consumers/**/*"
---

# Idempotency

Extends [`http-apis.md`](http-apis.md) and [`messaging.md`](messaging.md).

## Where it is required

- Every operation a client may retry carries an idempotency contract
- Payment, provisioning, and message consumption are always in scope

Avoid: relying on the client to retry only once. Treating a timeout as
a failure when the work may have completed.

## The key

- The key comes from the caller and is scoped to the operation
- A key is stored with the result it produced, before the reply is sent

```text
    key         supplied by the caller, unique per intent
    scope       operation plus tenant, never global
    stored      with the outcome, inside the same transaction
    lifetime    long enough to outlive the caller's retry window
```

Avoid: a key derived from a payload hash that legitimate repeats share.
A key kept only in memory. A record written after the response.

## Replay behaviour

- A repeated key returns the first outcome, unchanged
- A repeated key with a different payload is rejected, not merged

Avoid: a second attempt producing a second effect. A replay answered
with a fresh result that contradicts the first.

## Concurrency

- Two simultaneous attempts on one key resolve to one winner
- The loser waits for the outcome or is told to retry

```text
    insert key first, let uniqueness decide the winner
    winner performs the work and records the outcome
    loser reads the recorded outcome, or retries after it lands
```

Avoid: a check-then-act sequence across two statements. Uniqueness
enforced in application memory instead of storage.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a write endpoint or command handler | Where it is required |
| an idempotency key or request identifier | The key |
| a retry, replay, or duplicate check | Replay behaviour |
| a lock, upsert, or unique constraint | Concurrency |
