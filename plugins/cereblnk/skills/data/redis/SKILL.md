---
name: redis
description: How to reason about Redis — one thread serving everyone, eviction removing what you assumed resident, and caches without an invalidation story. Use for Redis work.
---

# Redis Skill

## 1. Identity
name: redis · domain: data
complements: query-optimization · performance-engineering
escalate_to: cloud-architecture (cluster topology) · data-modeling (when the cache hides a model problem)

## 2. Mission
One thread serves every client. Any command that scans blocks all of
them, and the fix is never more hardware.

## 3. Philosophy

**Reading requests.** "Cache it" hides three questions. What
invalidates it? What happens when many clients miss at once? What does
the application do when the store is unavailable or evicted the key
early? "Redis is slow" almost always means one scanning command
stalling the single thread.

**Where risk lives.** The single thread, blocked by any command whose
cost grows with data size. Memory and eviction, removing keys the
application assumed resident. Durability settings not matching the
belief that nothing is lost. Cache correctness: invalidation,
stampede, and the confident stale answer.

**Verification here.** For a latency claim, find the expensive command
in the slow log and check its complexity. Reputation is not evidence.
For a durability claim, read the persistence configuration. "We will
not lose it" is Assumed until the settings say so. Check the eviction
policy against what the application assumes stays.

**False-competence traps.** A full keyspace scan run in production. A
cache used as a database with no durability review. A cache with no
invalidation strategy. Large values and collections treated as cheap.

**Instincts.** Nothing that scans on the hot path. Every cache entry
has an invalidation rule written with it. Bound collection sizes. Make
the application survive an unavailable cache.

## 4. Decision Strategy — the paths

**A cache is proposed**
→ Write the invalidation rule first. A cache without one serves a
  stale truth confidently, and nobody knows for how long.

**Many clients can miss at once**
→ Plan the stampede. Expiry aligned across clients turns a cache miss
  into a load spike on the system behind it.

**A command's cost grows with data size**
→ Keep it off the hot path. One scan blocks every other client for
  its full duration.

**Keys are assumed to stay**
→ Read the eviction policy. Under memory pressure the store removes
  what it chooses, not what the application expected.

**Data must survive a restart**
→ Read the persistence configuration. Durability believed but not
  configured is the restart that loses everything.

**The store becomes unavailable**
→ Decide the application's behavior now. Degraded and correct beats
  fast and undefined.

**A collection grows without bound**
→ Cap it. Unbounded growth arrives as an eviction storm affecting
  unrelated keys.

## 5. Inputs
Command mix and slow log. Memory and eviction configuration.
Persistence settings. Key lifetimes and invalidation rules. The
application's fallback path.

## 6. Outputs
ACP Response Block only. Facts labeled. Latency claims are `known`
only against slow log evidence. Durability claims cite the persistence
configuration or stay `assumed`.

## 7. Quality Gates
- Every cache entry has a written invalidation rule.
- Every hot path is free of commands that scan.
- Every durability claim cites the persistence configuration.

## 8. Failure Modes
- One scanning command stalling every client at once.
- A restart losing data everyone believed was persisted.
- Aligned expiry converting a miss into a load spike.
- Keys evicted that the application treated as guaranteed.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | keyspace scan on the hot path | every client blocked |
| 2 | cache entry with no invalidation rule | confident staleness |
| 3 | uniform expiry across many keys | stampede on the backend |
| 4 | durability assumed with no persistence config | loss on restart |
| 5 | key assumed resident under memory pressure | silent eviction |
| 6 | unbounded collection growth | eviction storm |
| 7 | no defined behavior when the store is down | undefined degradation |

## 9. Worked Example
Claim: "the cache is safe, entries expire hourly." Evidence: every key
is written with the same lifetime at deploy time. Path fires: uniform
expiry across many keys. Verdict: weakened (Known: write path). All
entries expire together and the miss becomes a spike on the database.
Fix: spread the lifetimes, and serve the previous value while one
client refreshes.
