---
name: release-engineering
description: How to reason about releases — three separable events, the irreversible parts, rollbacks that were never rehearsed, and health defined before the deploy. Use for release work.
---

# Release Engineering Skill

## 1. Identity
name: release-engineering · domain: delivery
complements: git-strategy · artifact-management · liquibase-migrations
escalate_to: sre-agent (production verification) · database-agent (migration coupling)

## 2. Mission
A release is three events, not one: code deployed, feature enabled,
schema migrated. Separating them is most of the craft.

## 3. Philosophy

**Reading requests.** "Ship it Friday" hides three questions. Who is
around to roll back? What does this touch that cannot be undone? How
would we know it went wrong? The date is the least informative part of
the request.

**Where risk lives.** The irreversible parts: schema changes, consumed
messages, sent mail, third-party calls. Coupled releases where code
and schema must land together, so neither rolls back alone. The gap
between deployed and verified. And the release bundling thirty changes,
where a regression has thirty suspects.

**Verification here.** A rollback claim is verified by rehearsing it,
not by having a plan. The artifact returns and the data model tolerates
the old code. A health claim is verified against signals defined before
the release, not by an absence of complaints. Version claims are
verified against the deployed artifact's identity.

**False-competence traps.** A rollback plan nobody rehearsed. Code and
migration coupled into one step, then called atomic. Big-bang releases,
cheap to ship and expensive to diagnose. Health judged by silence.

**Instincts.** Separate deploy from enable from migrate. Define the
health signals before shipping. Rehearse the rollback. Keep releases
small enough that a regression has few suspects.

## 4. Decision Strategy — the paths

**A release is planned**
→ Split it into deploy, enable, and migrate. Each has its own
  reversibility, and bundling them removes the choice.

**Something in the release is irreversible**
→ Name it explicitly and gate it. Sent mail and consumed messages do
  not roll back, whatever the deployment tool reports.

**A rollback plan exists**
→ Rehearse it. A plan discovered broken during an incident is worse
  than no plan, because it consumed the time.

**Code and schema must land together**
→ Sequence them so each can stand alone. Expand, deploy, migrate,
  contract. Coupled steps forfeit rollback for both.

**The release is called healthy**
→ Check the signals defined beforehand. Silence measures attention,
  not health.

**Many changes are bundled**
→ Count the suspects a regression would have. Small releases are
  bought with frequency, and paid for once.

**A version is claimed deployed**
→ Compare artifact identity, not names. Tags move; the running bytes
  are the fact.

## 5. Inputs
The change set and its irreversible elements. Deployment sequence for
code, flags, and schema. Rehearsed rollback evidence. Health signals
defined before release. Deployed artifact identity.

## 6. Outputs
ACP Response Block only. Facts labeled. Rollback claims are `known`
only against a rehearsal. Health claims cite predefined signals.
Unrehearsed plans are `assumed` and named.

## 7. Quality Gates
- Every release states which parts are irreversible.
- Every rollback claim cites a rehearsal.
- Every release defines its health signals before shipping.

## 8. Failure Modes
- A rollback attempted for the first time during an incident.
- Code rolled back while the schema stayed ahead of it.
- A regression with thirty candidate causes.
- A release declared healthy because nobody complained yet.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | deploy, enable, and migrate as one step | rollback forfeited |
| 2 | rollback plan with no rehearsal | untested under pressure |
| 3 | irreversible action with no gate | no way back |
| 4 | health judged by absence of complaints | attention, not signal |
| 5 | large bundled release | many suspects per regression |
| 6 | version claimed from a tag | identity unverified |
| 7 | schema and code coupled in one deploy | neither rolls back |

## 9. Worked Example
Claim: "we can roll back, the plan is in the runbook." Evidence: the
release includes a schema change that removes a column the previous
code reads. Path fires: a rollback plan with no rehearsal, plus
coupled code and schema. Verdict: refuted (Known: change set and
runbook). The artifact rolls back; the data model does not. Fix:
expand and contract across two releases, and rehearse the rollback.
