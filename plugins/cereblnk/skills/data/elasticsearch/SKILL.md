---
name: elasticsearch
description: How to reason about search — relevance versus retrieval, mappings that are effectively permanent, shard decisions fixed at creation. Use for Elasticsearch work.
---

# Elasticsearch Skill

## 1. Identity
name: elasticsearch · domain: data
complements: query-optimization · data-modeling
escalate_to: cloud-architecture (cluster topology) · observability (index lifecycle at scale)

## 2. Mission
Relevance and retrieval are different problems with different fixes.
Decide which one you have before touching the query.

## 3. Philosophy

**Reading requests.** "Make search better" splits in two. Relevance
asks whether the right documents rank first. Retrieval asks whether we
match at all. They have different fixes. "Add a field" hides that
mappings are effectively permanent — changing a type means rebuilding
the index, not altering it.

**Where risk lives.** Mappings decided too early or guessed
dynamically. Shard counts fixed at creation, wrong in either
direction. Deep pagination consuming memory across the cluster.
Scoring work done where a cached filter belonged.

**Verification here.** For a relevance claim, look at the analyzed
tokens and the score explanation. "It should match" is Speculative
until the analyzer output shows the terms. For a mapping claim, read
the actual mapping, not the intended one — dynamic mapping may have
guessed. Query cost comes from the profile output.

**False-competence traps.** Dynamic mapping trusted in production.
Analyzed and exact-match field types confused, breaking sorting or
aggregation later. Deep offset pagination. Relevance computed on a
clause that never needed a score.

**Instincts.** Design mappings explicitly. Size shards for the
expected volume, knowing the count is fixed. Filter where scoring is
not needed. Paginate by cursor once the depth grows.

## 4. Decision Strategy — the paths

**Search quality is questioned**
→ Separate relevance from retrieval first. Ranking fixes and matching
  fixes live in different layers and do not substitute.

**A field is added**
→ Define its mapping explicitly. A dynamic guess becomes permanent,
  and correcting it means rebuilding the whole index.

**A field is sorted or aggregated**
→ Confirm it is not analyzed. Aggregating on an analyzed field
  returns tokens where values were expected.

**A clause does not need a score**
→ Put it in filter context. Scoring work spent where it changes no
  ranking is pure cost, repeated per query.

**Pagination goes deep**
→ Switch to a cursor-based approach. Offset pagination asks every
  shard for everything up to the offset.

**An index is created**
→ Decide shard count against expected volume. It cannot be changed
  later without a rebuild.

**A query is slow**
→ Read the profile output. Query shape intuition is unreliable once
  analyzers and filters are involved.

## 5. Inputs
The actual mapping. Analyzer output for relevance claims. Profile
output for cost claims. Index and shard configuration. Document
volume and growth rate.

## 6. Outputs
ACP Response Block only. Facts labeled. Relevance claims are `known`
only against analyzer and score output. Mapping claims cite the
retrieved mapping, not the intended one.

## 7. Quality Gates
- Every indexed field has an explicit mapping.
- Every sorted or aggregated field is unanalyzed.
- Every relevance verdict cites analyzer or score output.

## 8. Failure Modes
- An aggregation returning tokens instead of values.
- A type correction requiring a full rebuild in production.
- Deep pagination exhausting memory across the cluster.
- Scoring computed on clauses that never affected ranking.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | field indexed by dynamic mapping | permanent wrong type |
| 2 | aggregation on an analyzed field | tokens, not values |
| 3 | scoring clause that cannot change ranking | wasted cost per query |
| 4 | offset pagination past shallow depth | cluster-wide memory use |
| 5 | shard count set without volume estimate | rebuild to change |
| 6 | relevance claim with no analyzer output | speculation |
| 7 | mapping read from intent, not the index | drift unnoticed |

## 9. Worked Example
Claim: "the aggregation is broken, the data is wrong." Evidence: the
field was created by dynamic mapping as an analyzed type. Path fires:
aggregation on an analyzed field. Verdict: refuted (Known: retrieved
mapping). The data is intact; the aggregation returns tokens. Fix:
define the field explicitly and rebuild the index, then re-run the
aggregation against the new mapping.
