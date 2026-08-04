---
name: backend-caching
genre: constraint
category: backend
density: neutral
paths:
  - "**/*Cache*.*"
  - "**/cache/**/*"
---

# Caching

Extends [`common/performance.md`](../common/performance.md).

## Before the cache

- The invalidation rule is written before the cache exists
- The staleness the cache buys is stated, in seconds, and agreed

Avoid: a cache added before analysis. An entry with no invalidation
rule. Staleness nobody agreed to.

## Keys and scope

- A key includes everything that changes the value, tenant included
- A cache never crosses a security boundary

```text
included    tenant, locale, version, permission scope
excluded    request identifiers, timestamps, anything unique
```

Avoid: a key missing the tenant. One user's response served to
another. A key so specific it never hits.

## Misses

- Many clients missing at once is planned for, not discovered
- Expiry is spread; a refresh serves the previous value

Avoid: uniform expiry across a whole namespace. A miss storm reaching
the database. A refresh path that blocks every reader.

## Correctness

- A write invalidates before it returns, or the read path tolerates the
  window
- The cache is never the system of record

Avoid: a stale value returned right after the user changed it. A cache
holding data no store can rebuild.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a cache is introduced | Before the cache |
| a cache key is built | Keys and scope |
| expiry or refresh is configured | Misses |
| a write touches cached data | Correctness |
