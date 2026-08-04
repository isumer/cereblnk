---
name: data-integrity
genre: constraint
category: data
density: neutral
paths:
  - "**/entity/**/*"
  - "**/service/**/*"
---

# Data Integrity

Extends [`backend/transactions.md`](../backend/transactions.md).

## Correctness under concurrency

- Contended rows use a version, or a stated lock
- A conflict resolves by a rule, not by whoever writes last

Avoid: a lost update found by a customer. A read-then-write with a gap.
A counter incremented without a guard.

## Consistency across stores

- One store owns each fact; others hold copies with a stated lag
- A copy states how it is repaired when it drifts

```text
owner       the single writer of the truth
copy        derived, with a stated maximum lag
repair      a reconciliation that runs and reports
```

Avoid: two stores each believing they own a value. A projection with
no rebuild path. Drift discovered by a customer report.

## Money and counts

- Amounts are stored in minor units as integers, with currency
- A total that must balance is reconciled, and the check is automated

Avoid: a monetary value in a floating-point type. A currency implied by
context. A balance nobody reconciles.

## Trigger table

| Seen in the diff | Section |
|---|---|
| two writers can meet | Correctness under concurrency |
| a value exists in two stores | Consistency across stores |
| an amount or balance is stored | Money and counts |
