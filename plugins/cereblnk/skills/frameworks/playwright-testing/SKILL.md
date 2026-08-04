---
name: playwright-testing
description: How to reason about browser E2E tests — the most expensive layer, where flake is a race and selectors are coupling. Use for Playwright work. Constraints in rules/frameworks/playwright-testing/.
---

# Playwright Testing Skill

## 1. Identity
name: playwright-testing · domain: frameworks
requires: test-strategy
complements: junit-testing
escalate_to: selenium-webdriver (legacy grid constraints)

## 2. Mission
This is the most expensive layer. Most of the judgment is deciding
what does not belong here.

## 3. Philosophy

**Reading requests.** "Add an E2E test for this flow" hides two
questions. Which single journey is load-bearing? What is the cheapest
layer that proves each piece? "The E2E is flaky" is never bad luck. It
names a race between the test and the application.

**Where risk lives.** Waiting. Every manual timeout is a race with
another machine's speed. Selectors coupled to markup structure. State
and login shared across specs. The gap between an element existing and
an element being actionable.

**Verification here.** A green run proves the journey once. Break the
application behavior deliberately and watch the test fail. Then repeat
the spec to prove determinism. Trace files are the evidence for what
happened, not recollection.

**False-competence traps.** Fixed timeouts added until the suite goes
green. Deep structural selectors that survive review and die on the
next restyle. One long spec walking the entire application. Screenshot
comparisons standing in for assertions about logic.

**Instincts.** Select by role, then label, then test id. Prefer
assertions that wait on a condition. Give each spec its own state and
fresh context. Stub the network when the backend is not the subject.

## 4. Decision Strategy — the paths

**A new E2E test is requested**
→ Ask which cheaper layer could prove the same thing. Only the
  journey that crosses systems belongs here.

**A test is flaky**
→ Find the race. A fixed wait added to hide it converts the flake
  into a slower flake that returns in CI.

**An element must be ready**
→ Assert on a condition that waits. Existence in the tree is not
  actionability, and the gap is where the race lives.

**A selector is written**
→ Prefer role and accessible name. A structural selector encodes
  markup that design will change without telling anyone.

**Two specs touch the same data**
→ Give each its own. Shared state makes failure order-dependent and
  the report untrustworthy.

**Authentication is needed**
→ Reuse a stored session rather than walking the login form each
  time. The login flow gets exactly one test of its own.

**The backend is not the subject**
→ Stub at the network boundary. Otherwise every backend change
  reports itself as a frontend failure.

## 5. Inputs
Spec source with line refs. Trace files for failure claims. Repeat-run
output for determinism claims. Application selectors and accessible
names. Test data setup.

## 6. Outputs
ACP Response Block only. Facts labeled. A determinism claim is `known`
only against repeated runs. A single green run yields `estimated` at
best, with the run count stated.

## 7. Quality Gates
- No fixed timeout stands in for a condition.
- Every spec owns its state and can run alone.
- Every new E2E states why a cheaper layer could not prove it.

## 8. Failure Modes
- A suite tuned green locally and unreliable in CI forever.
- A restyle breaking tests that assert no changed behavior.
- One flake in a long spec poisoning every later assertion.
- A passing suite that never encoded the failure it was written for.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/playwright-testing/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | fixed timeout before an interaction | race hidden, not fixed |
| 2 | deep structural selector | markup coupling |
| 3 | spec depending on another spec's data | order-dependent failure |
| 4 | login walked in every spec | slow and fragile |
| 5 | screenshot assertion for logic | imprecise oracle |
| 6 | one spec covering many journeys | poisoned signal |
| 7 | determinism claimed from one green run | unproven |

## 9. Worked Example
Claim: "the checkout test is stable now, we added a wait." Evidence:
a fixed timeout precedes the submit click. Path fires: a fixed wait
standing in for a condition. Verdict: weakened (Known: spec line,
file#L). The race still exists and will return on slower hardware.
Fix: assert the button is enabled, then click. Repeat the spec to
show determinism.
