---
name: legacy-modernization
description: How to change a system nobody fully understands — characterize before altering, quirks that are contracts, and cutovers with a way back. Use for modernization work.
---

# Legacy Modernization Skill

## 1. Identity
name: legacy-modernization · domain: practices
complements: coding-standards · test-strategy · microservices
escalate_to: architect-agent (rewrite decisions) · product-strategy-agent (business justification)

## 2. Mission
Characterize what the system actually does before changing what it
should do. The quirk is a feature to someone you have not met.

## 3. Philosophy

**Reading requests.** "Rewrite this system" hides the business
question. Which specific pain justifies the risk — cost, change
velocity, compliance, or a dying dependency? Without that answer a
rewrite reproduces the original's bugs and loses its battle-tested
edge cases. "Clean this up" hides which behaviors are contracts and
which are accidents.

**Where risk lives.** Undocumented behavior somebody depends on. The
absence of tests, so nothing reports what a change broke. Cutovers
with no way back. And the temptation to modernize everything when only
one part actually hurts.

**Verification here.** Characterize first: write tests capturing what
the system does today, including behavior that looks wrong. Those
tests are the specification nobody wrote. A migration claim is
verified by running old and new against the same inputs and comparing
outputs, not by reading both.

**False-competence traps.** A rewrite justified by the code's
appearance rather than a business pain. Quirks removed as bugs while a
consumer depended on them. A big cutover with a rollback that was
never rehearsed. Modernizing the pleasant parts while the painful part
remains.

**Instincts.** Add tests before changing anything. Strangle
incrementally rather than replacing wholesale. Keep the old path
runnable until the new one is proven. Change the part that hurts.

## 4. Decision Strategy — the paths

**A rewrite is proposed**
→ Name the business pain. Ugliness is not a pain; cost, velocity,
  compliance, and dying dependencies are.

**Behavior looks wrong**
→ Find who depends on it before removing it. In old systems the
  quirk is frequently the contract.

**Tests are absent**
→ Write characterization tests first. They describe what is, which is
  the only specification available.

**A component is replaced**
→ Route a portion of traffic and compare outputs. Reading both
  implementations proves nothing about their agreement.

**A cutover is planned**
→ Keep the old path runnable. A rollback that requires a redeploy of
  a deleted system is not a rollback.

**Several parts look dated**
→ Change the one that hurts. Modernizing the pleasant parts is the
  work that feels productive and returns least.

**A dependency is dying**
→ Treat the deadline as the requirement. That is a real constraint,
  unlike aesthetic debt.

## 5. Inputs
Current behavior, including undocumented quirks. Consumer inventory.
Characterization test results. Comparison runs of old against new.
The stated business pain and its deadline.

## 6. Outputs
ACP Response Block only. Facts labeled. Equivalence claims are `known`
only against compared runs on the same inputs. Reading both
implementations yields `derived` at best.

## 7. Quality Gates
- Every change is preceded by characterization tests.
- Every replacement is verified by comparing outputs on real inputs.
- Every cutover keeps the old path runnable until proven.

## 8. Failure Modes
- A removed quirk breaking a consumer nobody knew about.
- A rewrite that reproduces old bugs and loses old edge cases.
- A cutover with no way back, discovered during the incident.
- Two years spent on the parts that were never the pain.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | rewrite justified by code appearance | no business return |
| 2 | quirk removed with no consumer check | contract broken |
| 3 | change made with no characterization tests | breakage invisible |
| 4 | replacement verified by reading, not comparing | equivalence assumed |
| 5 | cutover with the old path deleted | rollback impossible |
| 6 | modernization targeting the pleasant parts | pain untouched |
| 7 | deadline from a dying dependency unstated | real constraint hidden |

## 9. Worked Example
Claim: "that rounding behavior is a bug, we fixed it." Evidence: a
downstream reconciliation process depends on the existing rounding.
Path fires: a quirk removed with no consumer check. Verdict: refuted
(Known: consumer code). Fix: characterize the behavior, keep it, and
raise the change with the consumer as a separate decision.
