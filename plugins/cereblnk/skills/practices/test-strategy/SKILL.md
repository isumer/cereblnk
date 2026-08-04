---
name: test-strategy
description: How to decide which layer proves what — confidence per hour rather than coverage percentage, and suites that are green while proving nothing. Use for test planning.
---

# Test Strategy Skill

## 1. Identity
name: test-strategy · domain: practices
complements: unit-testing · integration-testing · playwright-testing
escalate_to: qa-agent (coverage decisions) · architect-agent (seam design)

## 2. Mission
Ask what each test would fail on. A suite that cannot fail proves
nothing, however green it is.

## 3. Philosophy

**Reading requests.** "Add tests for this" hides the real question.
Which behaviors are load-bearing, and which failures have hurt or will
hurt? The literal ask is coverage; the real ask is confidence per
engineering hour. A coverage target is almost never the goal.

**Where risk lives.** The layer mismatch. Logic proven through a slow
end-to-end run where a unit test would pin it in milliseconds. A
cross-component seam covered only by unit tests that mocked the seam
away. The dangerous suite is green and silent about the failure that
ships.

**Verification here.** For every proposed test, ask what it would fail
on. Then break the behavior and watch it go red. A layer is right when
the test at that layer catches the failure and the layers below it
cannot.

**False-competence traps.** A coverage percentage pursued as the goal.
A suite heavy at the slowest layer and thin at the fastest. Tests
added after the fix that would have passed before it. Counting tests
rather than asking what they detect.

**Instincts.** Push each check to the cheapest layer that can prove
it. Write the failing test before the fix. Delete tests that cannot
fail. Judge a suite by what it caught, not by its size.

## 4. Decision Strategy — the paths

**Tests are requested for a change**
→ Name the failure modes first. Coverage of lines and coverage of
  failures are different quantities, and only one prevents incidents.

**A behavior could be tested at several layers**
→ Choose the cheapest layer that can fail on it. Higher layers cost
  time and flake for the same information.

**A seam is mocked in a unit test**
→ Ask what proves the seam itself. Mocked seams pass while the real
  translation across them is broken.

**A fix arrives with a test**
→ Check that the test fails without the fix. A test that passes
  before the change encodes nothing about it.

**A suite is called comprehensive**
→ Ask what it has caught. Size is a property of the suite; detection
  is a property of its design.

**A test is flaky**
→ Fix or delete it. A flaky test trains people to re-run, and
  re-running is how a real failure gets dismissed.

**Coverage is reported**
→ Ask which failure modes are covered. High line coverage with the
  race untested is the normal shape of a false sense of safety.

## 5. Inputs
The change and its failure modes. Existing suite composition per
layer. Test execution times and flake history. Past incidents and what
would have caught them.

## 6. Outputs
ACP Response Block only. Facts labeled. A coverage claim is `known`
only against named failure modes. Line percentages support no
confidence claim on their own.

## 7. Quality Gates
- Every proposed test states what it would fail on.
- Every fix ships with a test that fails without it.
- Every layer choice is justified as the cheapest that can prove it.

## 8. Failure Modes
- A high coverage number alongside an untested race.
- Slow end-to-end tests proving what a unit test would have.
- A regression shipping because its test passed before the fix.
- Real failures dismissed as flake by habit.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | coverage percentage stated as the goal | failure modes unexamined |
| 2 | test that passes without the fix | encodes nothing |
| 3 | seam mocked with nothing proving the seam | translation untested |
| 4 | behavior tested only at the slowest layer | cost and flake for nothing |
| 5 | flaky test tolerated | real failures dismissed |
| 6 | suite judged by size | detection unknown |
| 7 | tests added after the fix, never run against it | unverified guard |

## 9. Worked Example
Claim: "the bug is covered, we added a test." Evidence: the test
passes against the version before the fix. Path fires: a test that
passes without the fix. Verdict: refuted (Known: test run on both
versions). Fix: write the failing test first, watch it go red, then
apply the fix and watch it go green.
