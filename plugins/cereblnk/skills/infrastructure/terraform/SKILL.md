---
name: terraform
description: How to reason about Terraform — read the plan rather than the diff, state as the fragile asset, replaces hiding inside routine changes. Use for infrastructure-as-code work.
---

# Terraform Skill

## 1. Identity
name: terraform · domain: infrastructure
complements: kubernetes · helm · cloud-architecture
escalate_to: infra-agent (topology decisions) · security-agent (state and secret exposure)

## 2. Mission
Every request is read as its plan, not as its diff. The plan is the
only place the real consequences appear.

## 3. Philosophy

**Reading requests.** "Add a resource" hides a bigger question. What
else will the plan do? Provider upgrades, drift, and ripple effects
ride along. "Rename this" is never a rename here. It is a destroy and
create unless the configuration says otherwise.

**Where risk lives.** The state file: corruption, drift, secrets held
in clear text, concurrent applies without locking. Every replacement
and destruction the plan contains. Targeted surgery and manual state
edits. Provider upgrades changing meaning under unchanged
configuration.

**Verification here.** Read the entire plan. Trace every replacement
and destruction to an intent. A safe-change claim is Speculative until
the plan says update in place. State claims are verified against the
state itself, never memory. An apply is verified by a following empty
plan.

**False-competence traps.** Module abstraction built for one
environment, producing plans nobody reads. A plan skimmed for
additions while one replacement passes unseen. Drift fixed by editing
state rather than reconciling reality. Destructive habits carried from
development.

**Instincts.** Read plans line by line, replacements first. Lock state
and keep secrets out of it. Reconcile drift in reality, not in the
ledger. Pin provider versions and upgrade deliberately.

## 4. Decision Strategy — the paths

**A change is proposed**
→ Read the full plan before judging it. The diff shows what was
  typed; the plan shows what will happen.

**The plan contains a replacement**
→ Trace it to an intent. An unintended replacement is the most common
  route from a routine change to an outage.

**A resource is renamed**
→ Declare the move explicitly. Otherwise the tool destroys and
  recreates something that only changed its label.

**Drift is discovered**
→ Reconcile reality with the configuration. Editing state to match
  the world falsifies the ledger and hides the next drift.

**A provider version is bumped**
→ Plan before and after. Resource semantics move between versions
  while the configuration text stays identical.

**An apply completes**
→ Run one more plan. A non-empty plan afterwards means the
  configuration and reality still disagree.

**Targeted application is proposed**
→ Ask what it is skipping. Partial application leaves state and
  reality partly reconciled, which is worse than either.

## 5. Inputs
Configuration and the full plan output. State listing for existing
resources. Provider versions before and after. Locking configuration.
Post-apply plan for verification.

## 6. Outputs
ACP Response Block only. Facts labeled. Change claims are `known` only
against plan output. State claims cite the state, not recollection.

## 7. Quality Gates
- Every plan is read for replacements and destructions first.
- Every rename declares its move explicitly.
- Every apply is followed by a verifying plan.

## 8. Failure Modes
- A database replaced by a change intended as a tag edit.
- State edited to hide drift that then recurs invisibly.
- A provider bump changing behavior under unchanged code.
- Concurrent applies corrupting state without locking.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | change judged from the diff, not the plan | consequences unseen |
| 2 | plan containing an untraced replacement | destroy and create |
| 3 | rename without a declared move | resource recreated |
| 4 | drift resolved by editing state | ledger falsified |
| 5 | provider bumped with no before-and-after plan | silent semantic change |
| 6 | no verifying plan after apply | reconciliation unproven |
| 7 | targeted apply used routinely | partial reconciliation |

## 9. Worked Example
Claim: "it only changes a tag." Evidence: the plan shows a replacement
on a managed database because the tag participates in its name. Path
fires: a plan containing an untraced replacement. Verdict: refuted
(Known: plan output). Fix: change the tag without touching the name,
re-plan, and confirm the operation is an in-place update.
