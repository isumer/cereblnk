---
name: unit-testing
description: How to write a unit test that can fail — one behavior, its edges, and doubles that stub collaborators rather than the thing under test. Use for unit-level work.
---

# Unit Testing Skill

## 1. Identity
name: unit-testing · domain: practices
requires: test-strategy
complements: junit-testing · integration-testing
escalate_to: qa-agent (coverage decisions)

## 2. Mission
Invert the logic and watch the test go red. A test that stays green
against broken behavior tests nothing.

## 3. Philosophy

**Reading requests.** "Write a unit test for this method" hides the
real question. Which single behavior is worth pinning, and what are
its boundary inputs? A method has a happy path and a set of edges. The
edges are the test. "It is simple, no test needed" usually marks
simplicity that was assumed rather than verified.

**Where risk lives.** The seam between the unit and its collaborators.
Over-mocking turns the test into a mirror of the implementation, green
on a refactor and green on a bug. Under-isolation makes it a slow
integration test in disguise. Boundary values, error branches, and
empty inputs are where units actually break.

**Verification here.** Break the behavior deliberately and watch the
test fail for the right reason. A test that survives an inverted
condition proves nothing. Doubles are verified by asking what they
replace: stubbing a collaborator is isolation, stubbing the behavior
under test is testing the mock.

**False-competence traps.** Assertions on every interaction, so the
test documents the implementation and breaks on refactors. One test
carrying six assertions about unrelated things. Only the happy path
covered. Doubles standing in for the very logic being examined.

**Instincts.** One behavior per test, named for the behavior. Cover
edges before the happy path. Keep doubles at the boundary. Watch every
new test fail once before trusting it.

## 4. Decision Strategy — the paths

**A test is written**
→ Name the single behavior it pins. A name describing the method
  rather than the behavior signals a test with no thesis.

**A double is introduced**
→ Ask what it replaces. Replacing the logic under examination turns
  the test into a mirror.

**Only the happy path is covered**
→ Add the edges. Empty inputs, boundary values, and error branches
  are where the unit fails in production.

**A test asserts many things**
→ Split it. A failure that names six possible causes costs more than
  the test saved.

**Interactions are asserted**
→ Ask whether behavior or implementation is being pinned. Interaction
  assertions break on refactors and survive real bugs.

**A new test passes immediately**
→ Break the behavior once and confirm it fails. Otherwise its ability
  to fail is untested.

**Code is called too simple to test**
→ Test the edge anyway. Simplicity assumed rather than verified is
  where the empty-collection failure lives.

## 5. Inputs
The unit under test and its collaborators. Boundary and error inputs.
Existing doubles. The failure the test is meant to catch.

## 6. Outputs
ACP Response Block only. Facts labeled. A test's effectiveness is
`known` only after it has been observed failing against broken
behavior.

## 7. Quality Gates
- Every test pins one named behavior.
- Every test has been observed failing at least once.
- Every double replaces a collaborator, not the behavior examined.

## 8. Failure Modes
- A suite that stays green when the logic is inverted.
- Tests broken by a refactor that changed no behavior.
- A failure report naming six possible causes.
- An empty-collection bug in code deemed too simple to test.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | test never observed failing | ability to fail unproven |
| 2 | double replacing the logic under test | testing the mock |
| 3 | assertions on every interaction | implementation pinned |
| 4 | many unrelated assertions in one test | unclear failure |
| 5 | happy path only | edges unprotected |
| 6 | test named after the method | no stated thesis |
| 7 | code excused as too simple | assumed, not verified |

## 9. Worked Example
Claim: "the validator is tested." Evidence: the test passes with the
condition inverted. Path fires: a test never observed failing.
Verdict: refuted (Known: mutated run). The assertion checks a value
the validator never changes. Fix: assert the rejection, invert the
logic once, and confirm the failure before trusting it.
