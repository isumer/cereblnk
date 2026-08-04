---
name: common-performance
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Performance

Technology-neutral. Judgment lives in
`skills/practices/performance-engineering/`.

## The target

- Name three things before changing anything: operation, percentile,
  target
- Without all three, any change can be called an improvement

```text
operation    order settlement, end to end
percentile   p99
target       under 400 ms
```

Avoid: a task described as "make it faster" · a target set after the
work.

## Measurement

- Every number carries its volume, concurrency, and percentile
- A baseline is recorded before the change, under the same conditions

Avoid: a mean where the tail is the complaint · a benchmark on empty
or warm-cached data · a result with nothing to compare against.

## Order of work

- Remove the work, then reduce it, then make what remains faster
- Profile before theorising: intuition about hot code is unreliable

```text
first     stop repeating the call
second    fetch only the fields used
third     optimise what remains
```

Avoid: micro-optimising inside a loop that should not run · fetching a
full object for one field · tuning a query called per row.

## Relocated cost

- Speed is usually moved, not created; name where it went

```text
cache      gains read latency, pays staleness
index      gains reads, pays every write
batch      gains throughput, pays latency
```

Avoid: a cache added before analysis · an entry with no invalidation
rule · staleness nobody agreed to.

## Bounds

- Every collection paginated, every retry capped, every call timed out

Avoid: a query returning everything · a retry with no ceiling · an
outbound call with no timeout.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a speed change is proposed | The target |
| a measurement is reported | Measurement |
| an optimisation is chosen | Order of work |
| a cache, index, or batch is added | Relocated cost |
| a limit is unset | Bounds |
