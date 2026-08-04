---
name: architecture-integration
genre: constraint
category: architecture
density: neutral
applies_when: one system calls or depends on another
---

# Integration

Extends [`common/patterns.md`](../common/patterns.md).

## Calling out

- Every outbound call has a timeout, a retry ceiling, and a fallback
- A dependency's failure has a defined behavior, decided in advance

```text
timeout     stated per call, never the library default
retries     bounded, delayed, only on idempotent operations
fallback    degraded and correct, or a clear failure
```

Avoid: a call with no timeout. Unbounded retry against a struggling
dependency. An outage cascading because nothing degraded.

## Coupling

- A synchronous chain is counted; each hop multiplies failure
- Work that can wait moves to a message

Avoid: three services called in sequence to serve one request. A
request path that fails when a reporting service is down.

## Contracts with others

- An external contract is pinned, and its changes are watched
- A partner's payload is validated on arrival like any other input

Avoid: a third-party response trusted because it is internal. A
schema change discovered when parsing fails in production.

## Consistency

- Where two systems must agree, one owns the truth
- Cross-system writes use an outbox or a saga, never a distributed
  transaction

Avoid: a write and a publish that can disagree. Compensations
discovered missing during a partial failure.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an outbound call is made | Calling out |
| a service calls another | Coupling |
| an external payload is handled | Contracts with others |
| two systems must agree | Consistency |
