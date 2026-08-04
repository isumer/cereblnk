---
name: backend-concurrency
genre: constraint
category: backend
density: neutral
paths:
  - "**/service/**/*"
  - "**/*Service.*"
  - "**/worker/**/*"
---

# Concurrency

Extends [`transactions.md`](transactions.md).

## Shared state

- State shared between requests is held in storage, not in the process
- A value cached per instance states how staleness is bounded

Avoid: a counter kept in a static field. An in-memory map treated as a
cluster-wide fact.

## Lost updates

- A read-modify-write cycle carries a version, checked on write
- A conflict is reported to the caller, never resolved by guessing

```text
    read      row plus its version
    modify    in the domain, not in the database
    write     conditional on the version read
    conflict  surfaced, with what changed
```

Avoid: an update that overwrites whatever it finds. A retry loop that
reapplies the same stale change.

## Locks

- A lock is held for the shortest span that keeps the invariant
- Locks are acquired in one declared order across the codebase

Avoid: a lock held across a network call. Two paths taking the same two
locks in opposite orders.

## Instance boundaries

- A guarantee needed across instances is enforced by shared storage
- Scheduled work states whether one instance or all instances run it

```text
    per instance    caches, warmers, metrics collection
    exactly once    scheduled jobs, sequence allocation, cleanup
```

Avoid: a lock that protects only the instance holding it. A nightly job
running once per pod without anyone deciding that.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a static field, cache, or singleton | Shared state |
| a read followed by an update | Lost updates |
| a lock, mutex, or synchronized block | Locks |
| a scheduled task or background worker | Instance boundaries |
