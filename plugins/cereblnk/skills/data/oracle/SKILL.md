---
name: oracle
description: How to reason about Oracle — plans built on statistics, bind variables, set work versus row loops, and separately licensed features. Use for Oracle work.
---

# Oracle Skill

## 1. Identity
name: oracle · domain: data
requires: sql
complements: query-optimization · liquibase-migrations
escalate_to: data-modeling (schema shape) · compliance-agent (licensing exposure)

## 2. Mission
The optimizer plans on statistics. Feed it fiction and every
downstream decision inherits the lie.

## 3. Philosophy

**Reading requests.** "Oracle is slow" decomposes by layer. A plan
built on stale statistics. Contention on rows or blocks. Procedural
code doing row by row what one set operation does. "Use this feature"
carries a second question here. Several options are licensed
separately, and using one by accident is a contractual risk.

**Where risk lives.** Stale optimizer statistics. Implicit type
conversion quietly disabling an index. Literals instead of binds,
producing parse storms. Procedural loops calling SQL per row. Licensed
features slipping in unreviewed.

**Verification here.** Read the actual plan with runtime statistics on
production-shaped data. Estimated against actual cardinality is the
honesty meter. An index-usage claim is verified by the plan, never by
the hint that requested it. Licensing claims are verified against the
options actually enabled.

**False-competence traps.** Hints applied before the plan is read,
freezing a choice the optimizer avoided for a reason. Literals in
frequently executed statements. Cursor loops doing set work. Semantics
imported from another engine, where nulls and locking differ.

**Instincts.** Fresh, representative statistics before blaming the
query. Binds for anything repeated. Set operations over row loops.
Confirm the licensing before recommending an option.

## 4. Decision Strategy — the paths

**A query is slow**
→ Check statistics freshness first. A plan chosen on old numbers
  cannot be tuned into a good one.

**A plan is read**
→ Compare estimated against actual cardinality. Divergence means the
  optimizer chose on a picture that was never true.

**An index is expected but unused**
→ Look for implicit conversion on the predicate. A type mismatch
  disables the index silently and leaves the query looking innocent.

**A statement runs frequently**
→ Use bind variables. Literals produce a new parse each time and the
  contention appears far from the statement.

**Procedural code loops over rows**
→ Ask whether one set operation replaces it. Each iteration pays a
  context switch that the elegant-looking loop hides.

**A hint is proposed**
→ Read the plan first. A hint is a freeze, and the data shape it was
  frozen against will move.

**A database option is used**
→ Confirm it is licensed here. Accidental use is a contract question
  before it is a technical one.

## 5. Inputs
Statement text and its plan with runtime statistics. Statistics
freshness and representativeness. Wait and contention data. Enabled
options for any licensing claim. Procedural source for loop claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Plan claims are `known` only
against captured output with runtime statistics. Licensing claims cite
the enabled options.

## 7. Quality Gates
- Every tuning verdict states statistics freshness.
- Every index claim is confirmed by the plan, not by a hint.
- Every option used is confirmed licensed for this installation.

## 8. Failure Modes
- A plan tuned repeatedly while the statistics stayed wrong.
- An index ignored because of an implicit type conversion.
- Parse contention from literals in a hot statement.
- A licensing exposure created by a technical convenience.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | tuning proposed with no statistics check | plan built on fiction |
| 2 | estimated and actual cardinality far apart | wrong plan inevitable |
| 3 | predicate comparing mismatched types | index silently disabled |
| 4 | literals in a frequently executed statement | parse storm |
| 5 | cursor loop performing set work | context switching |
| 6 | hint added before the plan was read | frozen bad choice |
| 7 | separately licensed option used | contractual exposure |

## 9. Worked Example
Claim: "the index is ignored, so we added a hint." Evidence: the
predicate compares a character column to a number. Path fires:
mismatched types on the predicate. Verdict: refuted (Known: column
type and predicate). The conversion disabled the index; the hint now
forces a plan the optimizer was right to avoid. Fix: correct the type,
remove the hint, re-read the plan.
