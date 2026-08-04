---
name: hibernate-jpa
description: Fetch plans, cascades, ownership, emitted SQL — how to reason about JPA work. Use for entity/query-touching tasks. Constraints in rules/languages/java/. Constraints in rules/frameworks/hibernate-jpa/.
---

# Hibernate/JPA Skill

## 1. Identity
name: hibernate-jpa · domain: frameworks
requires: java · sql
complements: postgresql · query-optimization · spring-boot
escalate_to: database-agent (schema/migration decisions) · performance-engineering (plan analysis)

## 2. Mission
Reason in emitted SQL, not annotations. The mapping is a promise; the
statement log is the truth.

## 3. Philosophy

**Reading requests.** "The list page is slow" is an N+1 hunt first.
"Add a relation" hides four decisions: fetch strategy, cascade scope,
owning side, and the SQL of every existing query it touches.

**Where risk lives.** LAZY promises detonating as
LazyInitializationException or N+1 storms. Cascade REMOVE reaching
further than intended. Flush-order surprises near native queries.
Long sessions accumulating dirty state.

**Verification here.** Show the SQL: statement logging or a
query-count assertion. A fetch claim is the emitted statements. A
mapping claim is the DDL diff. "The cache handles it" is Assumed
until hit ratios are shown.

**False-competence traps.** EAGER as the LazyInit "fix" — a permanent
cartesian tax. cascade=ALL for convenience — delete semantics nobody
chose. Annotation-rich entities mistaken for a designed model. JPQL
"obviously" equivalent while paging+join-fetch moves to memory.

**Instincts.** LAZY by default; fetch explicitly per use case. DTO
projections for reads. The owning side is chosen, not discovered.
Query counts asserted for every touched list endpoint.

## 4. Decision Strategy — the paths

**A list endpoint is slow or reviewed**
→ Count queries with logging or a count assertion. Growth with
  result size is the N+1 finding; fix with fetch join or entity
  graph on THAT use case, never global EAGER.

**A relation is added**
→ LAZY. Choose the owning side aloud. Cascade only what the
  aggregate truly owns; REMOVE is opt-in with a stated reason.

**LazyInitializationException appears**
→ The unit of work ended early. Fetch what the use case needs
  inside it, or project a DTO. EAGER is not on the menu.

**Paging meets join fetch on a collection**
→ Hibernate pages in memory: finding. Two queries (ids, then fetch)
  or a projection.

**A native query runs mid-session**
→ Check flush semantics: pending changes may not be visible.
  Flush explicitly or restructure.

**A write path is reviewed**
→ Long session with many managed entities: dirty-check cost and
  surprise updates. Keep units of work short; detach or project.

## 5. Inputs
Entity mappings. The queries in scope. Statement log or query-count
tests. Generated DDL. Session/transaction boundaries.

## 6. Outputs
ACP Response Block only. Fetch claims `known` with the statement
evidence. Mapping claims `known` against DDL. Cache claims `assumed`
without hit ratios — and say so.

## 7. Quality Gates
- Every list endpoint touched carries a query-count assertion.
- Every new relation states side, fetch, and cascade with reasons.
- No EAGER introduced as an exception fix.

## 8. Failure Modes
- N+1 storm shipped behind a green unit suite.
- cascade=ALL deleting children on parent removal, discovered late.
- In-memory paging on a large collection fetch.
- Native update invisible to the session's first-level cache.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/hibernate-jpa/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | repository call or lazy access inside a loop | N+1 |
| 2 | fetch=EAGER on a collection | cartesian tax |
| 3 | cascade includes REMOVE/ALL without a stated reason | over-cascade |
| 4 | pagination combined with collection join fetch | memory paging |
| 5 | list endpoint without a query-count test | unverified fetch |

## 9. Worked Example
Claim: "orders page is fine, items are LAZY." Statement log on one
page: 1 + 25 selects — each row's items loaded during serialization.
Verdict: refuted (Known: log, file#L). Fix: fetch-join query for the
page's use case + count assertion `<= 2`; the entity default stays
LAZY.
