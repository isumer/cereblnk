---
name: sql
description: How to reason about SQL — a query is a workload statement and a migration is a live-system operation. Use for query, schema, or migration review. Constraints in rules/languages/sql/.
---

# SQL Skill

## 1. Identity
name: sql · domain: languages
complements: query-optimization · data-modeling
escalate_to: postgresql (engine plans) · oracle (engine plans) · liquibase-migrations (change process)

## 2. Mission
A query is a workload statement. A migration is an operation on a
running system. Syntax is the least of it.

## 3. Philosophy

**Reading requests.** "Make this query faster" is rarely about the
query. It is about the workload. How often does it run? On how many
rows? What else contends for those pages? "Add a column" hides three
questions. Rewrite or not, under which lock, for how long.

**Where risk lives.** Migrations, and anything holding locks in
production. A slow read embarrasses. An unindexed foreign key under a
cascading delete takes the system down. Below that sit NULL semantics
and implicit type coercion.

**Verification here.** Read the plan on production-shaped data. Never
a ten-row dev table. A plan that should use the index is Speculative
until the planner says it does. A migration is verified in both
directions, forward and back, at realistic volume.

**False-competence traps.** An index added for every slow query.
Star selects kept for flexibility. Generated SQL trusted unread.
Migrations tested forward only.

**Instincts.** Boring schema over clever schema. Measure before and
after, at real volume. Assume every migration runs live. Check NULL
semantics; never recall them.

## 4. Decision Strategy — the paths

**A query is called slow**
→ Ask for frequency, row counts, and contention before reading the
  SQL. The workload decides whether this is a problem at all.
→ Then read the plan. Not the query shape, the plan.

**An index is proposed**
→ Name the read it serves and the writes it taxes. An index is a
  write cost paid on every insert and update forever.

**A migration changes a large table**
→ Establish the lock it takes and how long it holds. Then write the
  rollback and run it. Untested rollback is not a rollback.

**A foreign key participates in a cascade**
→ Verify the child side is indexed. The cascade scans without it, and
  the outage arrives under load, not in review.

**A predicate compares nullable columns**
→ Walk the three-valued outcome explicitly. NOT IN with a NULL in the
  set returns nothing, silently and correctly.

**Generated SQL reaches production**
→ Read the emitted statement. The repeated query and the missing join
  predicate live there, not in the mapping code.

**A column is added to a widely read table**
→ Star selects downstream now carry it. Find the consumers before,
  not after.

## 5. Inputs
The query and its plan on realistic data. Table sizes and index
definitions. The migration and its rollback. Workload frequency.
Lock behavior of the target engine.

## 6. Outputs
ACP Response Block only. Facts labeled. A plan claim is `known` only
against captured planner output. Volume-dependent claims are
`estimated`, with the row counts stated.

## 7. Quality Gates
- Every performance verdict cites a plan on realistic volume.
- Every migration states its lock and has an exercised rollback.
- Every cascading delete has a verified index on the child side.

## 8. Failure Modes
- An index added for a read, paid for by every write.
- A migration that applies forward and cannot come back.
- Empty results from a NULL inside a negated set.
- A new column breaking consumers that select everything.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/sql/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | performance claim with no captured plan | speculation |
| 2 | plan captured on dev-sized data | wrong shape entirely |
| 3 | cascading delete, unindexed child | scan under load |
| 4 | negated set membership over nullable column | silent empty result |
| 5 | migration with no exercised rollback | one-way door |
| 6 | star select in a consumed view or API | column-add breakage |
| 7 | new index with no stated write cost | amplification unpriced |

## 9. Worked Example
Claim: "the delete is fine, it uses the primary key." Evidence: the
parent row cascades to a child table with no index on the foreign
key. Path fires: cascade without a child-side index. Verdict: refuted
(Known: schema definition, file#L). Fix: index the child column first,
then re-read the plan at production row counts.
