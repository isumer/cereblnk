---
name: selenium-webdriver
description: How to reason about Selenium E2E tests — synchronization, locator stability, session isolation, and the honest limit that a real browser run is CI's job. Use for WebDriver work. Constraints in rules/frameworks/selenium-webdriver/.
---

# Selenium WebDriver Skill

## 1. Identity
name: selenium-webdriver · domain: frameworks
requires: test-strategy
complements: junit-testing
escalate_to: playwright-testing (modern default tooling)
Boundary: this skill informs; agents decide.

## 2. Mission
Write the test and name its run command. Claiming it passes without a
real run is the trap this skill exists to name.

## 3. Philosophy

**Reading requests.** "Add a Selenium test for this flow" hides two
questions. Which single journey is load-bearing? What is the cheapest
layer that proves each piece? "The test is flaky" is never bad luck.
It names a race between the test and the application.

**Where risk lives.** Synchronization. Every sleep is a guess against
another machine's speed. Locators coupled to markup structure. Browser
sessions shared across tests. The gap between an element being present
and being interactable.

**Verification here.** Wait explicitly on a condition, never on time.
Determinism is shown by repeated runs, not by one green result. And
the honest boundary holds: this plugin writes the test and names its
command. Running a real browser is outside it. A "passes" claim needs
CI output, and stays Assumed without it.

**False-competence traps.** Sleeps tuned until the suite goes green.
Absolute structural locators surviving review and dying on the next
markup change. One long test walking the entire application. A local
run reported as proof.

**Instincts.** Explicit waits on conditions. Stable locators: id,
test id, accessible name. Page objects keeping markup detail out of
test intent. Each test owns its session. The run belongs to CI, and
that is stated plainly.

## 4. Decision Strategy — the paths

**A wait is needed**
→ Wait on a condition, with a timeout as the ceiling. A sleep encodes
  one machine's speed into a test that runs on many.

**A locator is written**
→ Prefer an id, a test id, or an accessible name. Absolute structural
  paths encode markup nobody promised to keep.

**A test needs a browser session**
→ Give it a fresh one. Shared sessions carry cookies and state that
  make failures order-dependent.

**Markup detail appears in a test method**
→ Move it behind a page object. Test intent and markup change for
  different reasons and at different times.

**A test is reported as passing**
→ Name where it ran. A local result is Assumed here; only CI output
  makes the claim `known`.

**An element is present but not clickable**
→ Wait on interactability, not presence. The gap between them is
  where most flake lives.

**A new E2E is requested**
→ Ask which cheaper layer proves the same thing. Only cross-system
  journeys justify this cost.

## 5. Inputs
Test source with line refs. Locator strategy and page objects. CI run
output for any pass claim. Grid or driver configuration. Application
markup for locator stability.

## 6. Outputs
ACP Response Block only. Facts labeled. A pass claim without CI output
is `assumed` and says so. Determinism claims cite repeated runs.

## 7. Quality Gates
- No sleep stands in for a condition.
- Every locator uses a stable attribute, not structure.
- Every pass claim names where the test actually ran.

## 8. Failure Modes
- A suite calibrated to one machine and unreliable everywhere else.
- Locators broken by a markup change that altered no behavior.
- Order-dependent failures from a reused session.
- A local green run treated as evidence.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/selenium-webdriver/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | sleep before an interaction | speed-dependent race |
| 2 | absolute structural locator | markup coupling |
| 3 | driver reused across tests | order-dependent state |
| 4 | markup detail inside a test method | intent and structure mixed |
| 5 | pass claimed with no CI output | assumed, not known |
| 6 | wait on presence before clicking | interactability gap |
| 7 | one test covering many journeys | poisoned signal |

## 9. Worked Example
Claim: "the login test passes." Evidence: a local run, with a sleep
before the submit click. Two paths fire: a sleep standing in for a
condition, and a pass claimed without CI. Verdict: weakened (Known:
test lines; Assumed: CI behavior). Fix: wait until the button is
clickable, then assert against CI output before the claim is `known`.
