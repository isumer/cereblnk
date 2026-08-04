---
name: liquibase-migrations
description: How to reason about schema migrations — lock scope, half-failure, checksum history, and rollbacks that cannot bring data back. Use for changelog work.
---

# Liquibase Migrations Skill

## 1. Identity
name: liquibase-migrations · domain: data
requires: sql
complements: postgresql · oracle
escalate_to: data-modeling (schema design) · devsecops (pipeline gating)

## 2. Mission
History is immutable. A rollback block that was never executed is not
a rollback.

## 3. Philosophy

**Reading requests.** "Add a migration for this" hides three
questions. What else runs while it runs? What happens on half-failure,
given this database's transactional DDL? How does this deploy interact
with the code deploy, expanding or breaking?

**Where risk lives.** Editing an applied changeset, which splits
environments by checksum. Databases without transactional schema
changes, leaving a changeset half-applied. Destructive changes no
rollback can truly undo. Missing preconditions where environments have
drifted.

**Verification here.** Execute forward, then execute the rollback,
against a production-shaped copy. That run in CI is the floor, not the
goal. For a destructive change, ask whether the data comes back. If
not, the honest answer is documented irreversibility plus a backup
gate, not a cosmetic rollback block.

**False-competence traps.** Rollback blocks written and never run. An
applied changeset fixed in place, with checksums cleared to silence
the error. One large changeset for a whole feature. Generated diffs
committed unread.

**Instincts.** New changesets fix old ones. One logical change each.
Expand and contract for anything running code reads. Preconditions
guard drift. Every destructive step carries a data-preservation story.

## 4. Decision Strategy — the paths

**A changeset has already been applied somewhere**
→ Never edit it. Write a new one. Editing splits environments and the
  divergence surfaces as a checksum error much later.

**A checksum error appears**
→ Find what changed and why. Clearing checksums silences the alarm
  and keeps the divergence.

**The database lacks transactional schema changes**
→ Split the work so a half-applied state is still valid. Atomicity
  assumed here is atomicity absent.

**A change is destructive**
→ Ask whether the data returns. If it does not, document the
  irreversibility and gate on a backup. Do not write a rollback block
  that only looks like one.

**Running code reads the affected shape**
→ Expand first, migrate, then contract in a later deploy. One
  breaking step assumes both deploys land together, and they do not.

**Environments have drifted**
→ Guard with a precondition. A migration that assumes a shape it
  never checked fails in exactly the environment nobody tested.

**A diff was generated automatically**
→ Read every line before committing. Drops and reorders ride along
  quietly inside a large generated file.

## 5. Inputs
Changelog and changeset source. Target database and its transactional
schema behavior. Applied-changeset state per environment. CI output of
the forward and rollback run. The deploy sequence for the code change.

## 6. Outputs
ACP Response Block only. Facts labeled. A reversibility claim is
`known` only against an executed rollback. An unexecuted rollback
block is `assumed` and is named as such.

## 7. Quality Gates
- Every rollback is executed in CI, not merely written.
- No applied changeset is edited in place.
- Every destructive change states whether data returns.

## 8. Failure Modes
- Environments diverging silently after a checksum was cleared.
- A half-applied changeset on a non-transactional database.
- A rollback that restores the schema and not the data.
- A breaking change deployed ahead of the code that needs it.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | edit to an already-applied changeset | environment split |
| 2 | checksums cleared to resolve an error | divergence preserved |
| 3 | rollback block with no CI execution | reversibility assumed |
| 4 | destructive change with a cosmetic rollback | data not recoverable |
| 5 | one changeset carrying many logical changes | half-applied state |
| 6 | generated diff committed without review | silent drops |
| 7 | shape assumed with no precondition | fails only in production |

## 9. Worked Example
Claim: "the migration is safe, it has a rollback." Evidence: the
changeset drops a column; the rollback re-adds it, empty. Path fires:
a destructive change with a cosmetic rollback. Verdict: refuted
(Known: changeset lines). The schema returns and the data does not.
Fix: state the irreversibility, gate on a verified backup, and move
the drop behind an expand-and-contract sequence.
