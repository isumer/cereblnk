---
name: backend-resilience
genre: constraint
category: backend
density: neutral
paths:
  - "**/client/**/*"
  - "**/*Client.*"
  - "**/integration/**/*"
---

# Resilience

Extends [`../architecture/integration.md`](../architecture/integration.md).

## Timeouts

- Every outbound call has a connect and a read timeout, set explicitly
- A caller's timeout is shorter than the timeout of what calls it

```text
    edge request budget      2000 ms
    downstream call           800 ms
    database statement        300 ms
```

Avoid: a client left on its library default. A chain where an inner
call may outlive the request that waits for it.

## Retries

- Only idempotent operations are retried
- Retries are bounded, spaced, and jittered

Avoid: a retry on a write whose effect is unknown. A fixed delay that
synchronises every caller into one wave.

## Circuit breaking

- A dependency that fails repeatedly is skipped, not queued against
- The breaker states what happens while it is open

```text
    closed     calls pass, failures counted
    open       calls fail fast, fallback answers
    half open  one trial call decides the next state
```

Avoid: a breaker with no defined fallback. Requests piling up behind a
dependency that is already known to be down.

## Degradation

- A failed optional dependency degrades the response, not the request
- What was degraded is visible to the caller and in the logs

Avoid: a recommendation service failure returning an error page. A
silent empty result that reads as real data.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an HTTP or database client | Timeouts |
| a retry, backoff, or repeat | Retries |
| a breaker, bulkhead, or fallback | Circuit breaking |
| an optional dependency | Degradation |
