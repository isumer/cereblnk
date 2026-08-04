---
name: component-testing
description: How to test a rendered component — the states nobody renders, queries a user could make, and assertions on output rather than internals. Use for component-level work.
---

# Component Testing Skill

## 1. Identity
name: component-testing · domain: practices
requires: test-strategy
complements: unit-testing · accessibility · react
escalate_to: qa-agent (coverage decisions) · frontend-agent (implementation)

## 2. Mission
Test what the user perceives and can do. Internal state is not the
contract; rendered output is.

## 3. Philosophy

**Reading requests.** "Test this component" hides the real question.
Which rendered behaviors matter across its states — empty, loading,
error, filled — and which are just markup? A component test verifies
what a user perceives and can do, not the shape of internal state.

**Where risk lives.** The states nobody renders. The error state. The
empty state. The loading flicker. The disabled combination of
properties. And testing implementation details, so the test passes by
construction and fails on refactors instead of bugs.

**Verification here.** Render in isolation and interact as a user
would: query by role and label, dispatch real events, assert on
rendered output and accessible roles. Verify by breaking the behavior
— remove the error handling — and watching that state's test fail.

**False-competence traps.** Assertions on internal state, green
whatever the user sees. Queries by class name, coupling the test to
styling. Only the filled state covered. Snapshots accepted as
assertions, updated whenever they fail.

**Instincts.** Cover every state the component can enter. Query the
way a user finds things. Assert on what is rendered. Treat a snapshot
as a change detector, never as a specification.

## 4. Decision Strategy — the paths

**A component is tested**
→ Enumerate its states first. Empty, loading, error, and filled each
  need a test, and three of them are usually missing.

**A query is written**
→ Find elements by role or label. Class-based queries couple the test
  to styling and break on a restyle.

**An assertion is chosen**
→ Assert on rendered output. Internal state passes whatever the user
  actually sees.

**A snapshot is added**
→ Treat it as change detection. A snapshot updated on every failure
  asserts nothing at all.

**Error handling exists**
→ Remove it once and confirm a test fails. Error states are the ones
  written and never exercised.

**Props combine**
→ Test the disabled and edge combinations. Individually valid
  properties produce invalid states together.

**A test breaks on a refactor**
→ Ask what it was pinning. Behavior survives refactors; internals do
  not, and pinning internals is the cost.

## 5. Inputs
The component and its property surface. Enumerated states. Rendered
output and accessible roles. Event handling. Existing snapshots.

## 6. Outputs
ACP Response Block only. Facts labeled. Behavior claims are `known`
only against rendered output. Internal state assertions support no
user-facing claim.

## 7. Quality Gates
- Every state the component can enter has a test.
- Every query finds elements the way a user would.
- Every error path has been broken once and seen to fail.

## 8. Failure Modes
- An error state that has never been rendered in any test.
- Tests broken by a restyle that changed no behavior.
- A snapshot updated to green without anyone reading the diff.
- Valid properties combining into an unhandled state.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | only the filled state tested | error and empty unproven |
| 2 | query by class name | coupled to styling |
| 3 | assertion on internal state | user-visible result unchecked |
| 4 | snapshot treated as specification | asserts nothing |
| 5 | error handling never broken in a test | path unexercised |
| 6 | property combinations untested | invalid state reachable |
| 7 | test failing on a pure refactor | internals pinned |

## 9. Worked Example
Claim: "the component handles errors, there is a test." Evidence: the
test asserts an internal flag and never renders the error branch. Path
fires: an assertion on internal state. Verdict: weakened (Known: test
body). Removing the error markup keeps the test green. Fix: render the
error state, assert the visible message, and confirm failure when the
handling is removed.
