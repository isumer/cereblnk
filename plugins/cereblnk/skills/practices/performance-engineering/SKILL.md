---
name: performance-engineering
description: How to reason about speed — the operation, the percentile, and the target named before any change; profiles before theories; costs that move rather than vanish. Use for latency and throughput work.
---

# Performance Engineering Skill

## 1. Identity
name: performance-engineering · domain: practices
complements: query-optimization · observability · cloud-architecture
escalate_to: sre-agent (production measurement) · database-agent (data-layer work)

## 2. Mission
Name the operation, the percentile, and the target. Without all three,
any change can be called an improvement.

## 3. Philosophy

**Reading requests.** "Make it faster" is incomplete until three
things are named. Which operation, at what percentile, against which
target? "Users say it is slow" is a starting point for measurement,
not a diagnosis. The slow thing is frequently not the thing being
blamed.

**Where risk lives.** The unmeasured assumption. Optimizing the
function that looks expensive while the real cost is a lock, a round
trip count, or a queue wait. Optimizations that move cost invisibly:
caching buying staleness, indexes taxing writes, batching adding
latency. Benchmarks that do not resemble production.

**Verification here.** Profile first. A claim about where time goes is
Speculative until a profile or trace says so. Then measure before and
after, on production-shaped data and concurrency, at the percentile
that matters. An improvement claim without its baseline conditions is
not a claim.

**False-competence traps.** Micro-optimizing code that merely looks
hot. Averages reported where the tail is the complaint. Benchmarks run
single-threaded against warm caches. Improvements measured only after
the change, with no baseline to compare.

**Instincts.** Measure before theorizing. Fix the largest contributor
first. State conditions with every number. Prefer removing work to
making work faster.

## 4. Decision Strategy — the paths

**Speed is requested**
→ Get the operation, the percentile, and the target. Without them the
  work has no definition of done.

**A bottleneck is suspected**
→ Profile before changing anything. Intuition about hot code is
  reliably wrong once locks and waiting are involved.

**An optimization is proposed**
→ Name what cost it moves. Speed is rarely created; it is usually
  relocated to writes, memory, or freshness.

**A measurement is taken**
→ State volume, concurrency, and percentile. A number without
  conditions cannot be compared with the number after.

**An average looks healthy**
→ Read the tail. The complaint lives at the percentile the average
  smooths away.

**Work can be removed**
→ Prefer that to making it faster. Removed work has no percentile and
  no regression risk.

**A benchmark is written**
→ Shape it like production: warm state, real concurrency, real data
  size. A benchmark that flatters the change teaches nothing.

## 5. Inputs
Profiles or traces for the operation. Baseline and post-change
measurements with conditions. Percentile latency data. Concurrency and
data volume. The stated target.

## 6. Outputs
ACP Response Block only. Facts labeled. Bottleneck claims are `known`
only against profile evidence. Improvement claims are `estimated` with
conditions stated.

## 7. Quality Gates
- Every performance task names operation, percentile, and target.
- Every bottleneck claim cites a profile.
- Every improvement cites a baseline under the same conditions.

## 8. Failure Modes
- Hours spent on code that was never the cost.
- A benchmark improvement invisible in production.
- Latency traded for staleness nobody agreed to.
- A tail regression hidden behind an improved average.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | optimization with no profile | wrong target likely |
| 2 | request with no percentile or target | undefined done |
| 3 | improvement with no baseline | unverifiable claim |
| 4 | average reported where tail is the complaint | wrong measure |
| 5 | benchmark on cold or small data | flattering conditions |
| 6 | cache or index added with no cost named | relocated, not removed |
| 7 | work optimized that could be removed | effort misplaced |

## 9. Worked Example
Claim: "the endpoint is twice as fast now." Evidence: the benchmark
ran single-threaded on a warm cache, and the reported figure is a
mean. Two paths fire: a benchmark on flattering conditions, and an
average where the tail is the complaint. Verdict: weakened (Known:
benchmark configuration). Fix: measure at the complained-about
percentile under real concurrency, against the recorded baseline.
