---
name: backend-rate-limiting
genre: constraint
category: backend
density: neutral
paths:
  - "**/*RateLimit*.*"
  - "**/middleware/**/*"
  - "**/filter/**/*"
---

# Rate Limiting

Extends [`common/security.md`](../common/security.md).

## What is limited

- Every endpoint a caller can repeat has a limit
- Expensive and authentication paths are limited more tightly

```text
per principal    the normal dimension
per source       for unauthenticated surfaces
per resource     where one target can be overwhelmed
```

Avoid: a limit only on the login path. A global limit one noisy client
consumes. A limit applied after the expensive work ran.

## Behavior at the limit

- A limited caller learns the limit, the window and when to retry
- Rejection is cheap and happens before the work

Avoid: a rejection that costs as much as the request. A caller with no
way to know the limit. A silent drop instead of a stated refusal.

## Fairness

- One caller cannot exhaust capacity for everyone
- A burst allowance is stated, not accidental

Avoid: a shared bucket across tenants. A limit so tight that normal use
trips it. A retry policy that turns a limit into a stampede.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an endpoint is added | What is limited |
| a limit is enforced | Behavior at the limit |
| capacity is shared | Fairness |
