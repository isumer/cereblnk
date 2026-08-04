---
name: query-optimization
description: How to reason about slow queries — workload before SQL, costs that move rather than disappear, and measurement that survives production. Use for latency and throughput work.
---

# Query Optimization Skill

## 1. Identity
name: query-optimization · domain: data
requires: sql
complements: postgresql · oracle · performance-engineering
escalate_to: data-modeling (when no index fixes the shape)

## 2. Mission
Frequency times cost, before any SQL is read. The fastest query is
the one that is never run.

## 3. Philosophy

**Reading requests.** "Optimize this query" is rarely the job. The job
is a workload missing its target. The query in hand may be the symptom
rather than the cause, called hundreds of times per request. Read the
calling pattern before the statement.

**Where risk lives.** Optimizations that move cost invisibly. Indexes
taxing every write. Denormalization creating update anomalies. Caches
serving stale truths. Hints freezing yesterday's plan against
tomorrow's data. The expensive wrongness helps the benchmark and hurts
production.

**Verification here.** Plan and measurement on production-shaped data,
before and after, same volume, stated concurrency. Divergence between
estimated and actual rows is investigated before any plan is trusted.
A speedup claim without its baseline conditions is Speculative.

**False-competence traps.** Style rewrites while the plans are
identical. A covering index reflex, paid for by the write path
forever. Cache-first thinking bought before analysis. Benchmarks run
on cold or development data.

**Instincts.** Measure the workload, then the query. Kill repeated
calls and over-fetching first. Paginate by key when offsets grow.
Leave the schema boring unless the plan proves otherwise.

## 4. Decision Strategy — the paths

**A query is reported slow**
→ Get its frequency and the row counts first. A fast query called
  four hundred times is the real finding.

**A rewrite is proposed**
→ Compare the plans. Identical plans mean the rewrite is style, and
  style is not optimization.

**An index is proposed**
→ Price the write path. Every insert and update pays for it on every
  future call, forever.

**A cache is proposed**
→ Name the invalidation rule before the cache. Staleness debt taken
  on before analysis is rarely repaid.

**A measurement is taken**
→ State the volume and the concurrency. A number without conditions
  cannot be compared to the number after.

**Estimated and actual rows diverge**
→ Investigate the statistics before trusting anything downstream. The
  planner chose on numbers that were not true.

**A plan hint is added**
→ Treat it as a freeze. It will still be there when the data shape
  has moved on and the frozen plan is the wrong one.

## 5. Inputs
Query text, call frequency, and row counts. Plans before and after, on
realistic volume. Index definitions and write rates. Concurrency
during measurement. The calling code for repetition claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Speedup claims are `estimated`
with volume and concurrency stated. Plan claims are `known` only
against captured output.

## 7. Quality Gates
- Every optimization states the workload it serves.
- Every measurement states volume and concurrency.
- Every index proposal names its write cost.

## 8. Failure Modes
- A benchmark improved and production unchanged.
- Read latency bought with write latency nobody measured.
- A cache serving a value the user just changed.
- A hint outliving the data shape it was chosen for.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | query tuned with no frequency data | wrong target |
| 2 | rewrite proposed with identical plans | motion, not gain |
| 3 | index added with no write-cost statement | unpriced tax |
| 4 | cache introduced before analysis | staleness debt |
| 5 | measurement with no stated volume | incomparable |
| 6 | estimated and actual rows far apart | planner misled |
| 7 | hint pinning a plan | frozen against future data |

## 9. Worked Example
Claim: "the query is optimized, it is twice as fast." Evidence: the
measurement ran on a development copy, and the calling code invokes it
once per row of a result set. Two paths fire: a measurement with no
stated volume, and a query tuned with no frequency data. Verdict:
weakened (Known: call site and benchmark conditions). Fix: remove the
repetition first, then measure at production volume.
