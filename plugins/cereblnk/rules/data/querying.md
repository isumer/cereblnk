---
name: data-querying
genre: constraint
category: data
density: neutral
paths:
  - "**/repository/**/*"
  - "**/*Repository.*"
  - "**/*.sql"
---

# Querying

Extends [`common/performance.md`](../common/performance.md). Judgment
lives in `skills/data/query-optimization/`.

## Before the query

- Frequency and row counts come before the statement is read
- A fast query called per row is the finding, not the statement

Avoid: a statement tuned with no call-frequency data. An optimisation
proven on development volume. A rewrite whose plan is identical.

## Plans

- A performance claim cites a plan captured on production-shaped data
- Estimated against actual rows is checked before the plan is trusted

Avoid: a claim with no captured plan. A plan read on ten rows. An
index added with no check that the planner uses it.

## Bounds

- Every list query paginates, with a stable sort
- Every query has a bound on what it can return

Avoid: a query returning everything. Offset pagination past shallow
depth. A join whose row multiplier nobody counted.

## Writes

- Bulk changes are one statement, not a loop
- A write states its lock and its expected duration

Avoid: a save per row over thousands. A modifying statement that
leaves a stale context. A batch with no checkpoint.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a query is called slow | Before the query |
| a performance change is proposed | Plans |
| a list or join is returned | Bounds |
| rows are modified in bulk | Writes |
