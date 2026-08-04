---
name: cloud-managed-services
genre: constraint
category: cloud
density: neutral
paths:
  - "**/*.tf"
  - "**/infra/**/*"
---

# Managed Services

Extends [`architecture/integration.md`](../architecture/integration.md).

## Choosing one

- What the service replaces is stated, along with what leaving costs
- Data gravity is priced before the data lands

Avoid: a managed service adopted for a feature one library provides. A
choice whose exit path nobody described. Data placed where moving it
later is the real cost.

## Depending on one

- A managed dependency has a timeout, a retry ceiling and a fallback
- Its limits and quotas are known before production traffic meets them

```text
known      rate limits, size limits, concurrency quotas
handled    throttling responses, with backoff
degraded   defined behavior when the service is unavailable
```

Avoid: a quota discovered at peak. A throttling response treated as an
error. An outage cascading because nothing degraded.

## Configuration

- Every managed resource is created by code, never by a console
- Its configuration is reviewed like source, and drift is detected

Avoid: a setting changed by hand and lost on the next apply. A resource
nobody can recreate. Encryption or backup left at a default nobody
read.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a managed service is adopted | Choosing one |
| a call to one is made | Depending on one |
| its settings change | Configuration |
