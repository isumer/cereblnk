---
name: postgresql
description: How to reason about Postgres — plan reality, lock levels under live traffic, vacuum debt, and folklore from other engines. Use for Postgres work.
---

# PostgreSQL Skill

## 1. Identity
name: postgresql · domain: data
requires: sql
complements: query-optimization · liquibase-migrations
escalate_to: data-modeling (schema shape) · cloud-architecture (managed HA topology)

## 2. Mission
Ask which layer is slow before tuning anything. Plan, bloat, locks,
and connections fail differently and are fixed differently.

## 3. Philosophy

**Reading requests.** "Postgres is slow" decomposes into four
candidates. A bad plan choice. Vacuum debt. Lock waits. Connection
churn. "Add a JSON column" hides one question. Are we buying
schemaless debt where a table belongs? The workload question comes
before any tuning question.

**Where risk lives.** Schema changes under live traffic, where the
lock level decides who blocks. Vacuum starvation on hot tables. Long
transactions holding cleanup back. Index builds that lock writes on a
production table.

**Verification here.** Read the plan with actual row counts on
production-shaped volume. Estimated against actual rows is the honesty
meter. Behavior claims go to the statistics views. A lock claim is
checked against that exact statement on that exact version.

**False-competence traps.** Folklore from other engines applied
unread. Knob turning before a single plan is read. JSON columns chosen
for flexibility, forfeiting constraints and statistics. An index
created and never checked for use.

**Instincts.** Build production indexes concurrently, knowing the
invalid-index cleanup that follows. Shape indexes to the actual
predicate. Keep transactions short as a design rule. Check the version
before recommending a feature.

## 4. Decision Strategy — the paths

**Slowness is reported**
→ Name the layer first: plan, bloat, locks, or connections. Tuning
  the wrong layer is motion that measures as progress.

**A plan is read**
→ Compare estimated rows against actual. Large divergence means the
  statistics are wrong, and every downstream choice inherits that.

**Schema is changed on a live table**
→ Establish the lock level for that exact statement and version.
  Some forms block reads, some only writes, and the difference is the
  outage.

**An index is created in production**
→ Build it concurrently. Then check the failure path: a cancelled
  concurrent build leaves an invalid index that must be dropped.

**An index exists and the query is still slow**
→ Check whether the planner uses it. An unused index is pure write
  cost with a comforting name.

**A table is hot and churning**
→ Look at vacuum progress and dead rows. Bloat presents as a plan
  problem and resists every plan-level fix.

**A JSON column is proposed**
→ Ask which constraints and statistics are being given up. Flexible
  storage prices itself in planner blindness later.

## 5. Inputs
Query text and its plan with actual rows, on realistic volume. Table
and index definitions. Statistics views for usage and bloat claims.
Server version. The exact statement for any lock claim.

## 6. Outputs
ACP Response Block only. Facts labeled. Plan claims are `known` only
against captured output with actual rows. Lock claims cite the
statement form and version.

## 7. Quality Gates
- Every performance verdict names the layer it addresses.
- Every production index build states its concurrency and cleanup.
- Every lock claim cites the statement form and server version.

## 8. Failure Modes
- Tuning applied to the plan while the real cost was bloat.
- A schema change blocking writes for the length of a rewrite.
- An index paid for on every write and never chosen by the planner.
- A cancelled concurrent build leaving an invalid index behind.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | tuning proposed with no plan read | theater |
| 2 | estimated and actual rows far apart | stale statistics |
| 3 | index built on a production table without concurrency | writes blocked |
| 4 | index added with no usage check afterwards | pure write cost |
| 5 | long-running transaction on a hot table | vacuum starved |
| 6 | schema change with no stated lock level | unknown blast radius |
| 7 | JSON column replacing a modelled table | constraints forfeited |

## 9. Worked Example
Claim: "the index fixed it." Evidence: the index exists; the plan
still shows a sequential scan and the statistics view shows zero
scans. Path fires: an index added with no usage check. Verdict:
refuted (Known: plan and usage output). The predicate shape does not
match the index. Fix: shape the index to the actual predicate, then
re-read the plan at production volume.
