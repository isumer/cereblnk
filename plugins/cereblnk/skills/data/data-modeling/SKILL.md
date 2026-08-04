---
name: data-modeling
description: How to reason about schema shape — invariants the database can enforce, change over time, and denormalization that buys speed with anomalies. Use for schema design work.
---

# Data Modeling Skill

## 1. Identity
name: data-modeling · domain: data
requires: sql
complements: postgresql · oracle · api-design
escalate_to: liquibase-migrations (change process) · query-optimization (plan-driven shape changes)

## 2. Mission
The schema is the last line of defense. Application code changes
weekly; the data it corrupted stays.

## 3. Philosophy

**Reading requests.** "Add a field for this" hides the real question.
Which entity owns it, and which invariant does it belong to? A field
placed on the wrong entity is a join away from correct and a year away
from being fixed. "Make it flexible" usually means the model is not
understood yet.

**Where risk lives.** Invariants left to application code that the
database could enforce. Nullable columns standing in for absent
modeling. Denormalization taken on for speed, paying in anomalies.
Identifiers that carry meaning and later need to change.

**Verification here.** Write the invariant as a constraint and try to
violate it. If the database accepts the bad row, the invariant lives
only in code and only until the next writer. Model claims are checked
against real cardinalities, not intended ones.

**False-competence traps.** A flexible key-value table replacing a
model nobody wanted to think about. Nullable columns multiplying
because absence was never modeled. Denormalization applied before any
plan demanded it. Natural keys chosen for meaning, then changing.

**Instincts.** Let the database hold the invariants it can hold. Model
absence explicitly. Keep identifiers meaningless and stable. Normalize
until a measured plan objects. Name things as the domain names them.

## 4. Decision Strategy — the paths

**A field is added**
→ Ask which entity owns it and which invariant it serves. Ownership
  decided by convenience becomes a permanent join.

**A value may be absent**
→ Model the absence. A nullable column with no stated meaning invites
  three different interpretations from three writers.

**An invariant exists**
→ Express it as a constraint where the database can enforce it. Code
  enforces it for this writer, not the next one, and not for a script.

**Denormalization is proposed**
→ Require a measured plan first, and name the update path. Two copies
  of a truth diverge on the write nobody thought about.

**An identifier is chosen**
→ Prefer meaningless and stable. Any key carrying business meaning
  will eventually need to change, while rows point at it.

**A relationship is drawn**
→ Verify the real cardinality against data, not intent. The optional
  many that was documented as one is where the bugs live.

**A flexible container is proposed**
→ Ask what is unknown about the domain. Flexibility here is usually
  postponed modeling with interest.

## 5. Inputs
Existing schema and constraints. Real cardinalities from data. The
domain vocabulary. Access patterns and plans when shape is contested.
The write paths for any denormalized value.

## 6. Outputs
ACP Response Block only. Facts labeled. Cardinality claims are `known`
only against queried data. Intended relationships are `assumed` and
named as such.

## 7. Quality Gates
- Every enforceable invariant lives in a constraint.
- Every nullable column has a documented meaning for its absence.
- Every denormalized value names its update path.

## 8. Failure Modes
- Corrupt rows written by a script that skipped application checks.
- Three meanings for one nullable column across three features.
- Divergent copies after a write path nobody updated.
- A business key changing while rows still point at it.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | invariant enforced only in application code | next writer bypasses it |
| 2 | nullable column with no stated meaning | ambiguous absence |
| 3 | denormalized value with one update path | divergence on the other |
| 4 | key carrying business meaning | change with references |
| 5 | key-value table replacing a model | postponed modeling |
| 6 | cardinality taken from documentation | untested assumption |
| 7 | field placed for query convenience | permanent wrong ownership |

## 9. Worked Example
Claim: "the amounts stay consistent, the service updates both." Two
tables hold the same total, written by one service method. Path fires:
a denormalized value with one update path. Verdict: weakened (Known:
schema and method; Assumed: no other writer). A batch job writes one
of them. Fix: derive the value, or constrain it where the database can
check. A test writes through the second path and expects rejection.
