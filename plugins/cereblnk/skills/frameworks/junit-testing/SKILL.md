---
name: junit-testing
description: What a test proves — failure-mode coverage, determinism, mutation discipline. Use for JVM test work. Constraints in rules/languages/java/. Constraints in rules/frameworks/junit-testing/.
---

# JUnit Testing Skill

## 1. Identity
name: junit-testing · domain: frameworks
requires: java
complements: spring-boot · test-strategy · integration-testing
escalate_to: qa-agent (suite strategy) · test-strategy (what to test at which layer)

## 2. Mission
A test is evidence only if it can fail. Reason about which failure
each test encodes — not how many asserts it makes.

## 3. Philosophy

**Reading requests.** "Write tests for X" hides: which behaviors are
load-bearing, which failures have hurt or will. Line coverage is the
literal ask; failure-mode coverage is the operational one. "Flaky"
means a hidden dependency, not a rerun button.

**Where risk lives.** Green suites that never encoded the real
failure (trap #8). Mock choreography pinning internals — passing
through refactors AND bugs. Shared fixtures coupling order. Ambient
time and randomness.

**Verification here.** Mutate to verify: break the behavior, watch
the test fail. A test that cannot fail is decoration. For flakes:
make the dependency explicit — inject the clock, fix the seed,
isolate the state — and reproduce deterministically.

**False-competence traps.** Assertion-count theater. verify() on
every interaction sold as rigor. @SpringBootTest for a pure method.
Stubbing the very behavior under test.

**Instincts.** One behavior per test, named as its claim. Boundaries
and error paths before happy-path variants. Real objects until
isolation is needed; then fakes over interaction mocks. Time and
random injected, never ambient.

## 4. Decision Strategy — the paths

**A bug is fixed**
→ Regression test first, red against pre-fix code, then the fix.
  A retrofitted green test proves nothing.

**A test is written**
→ Name it as the behavioral claim. Assert the outcome, not the
  interactions — unless the interaction IS the contract.
→ Ask: what mutation makes this red? None: rewrite it.

**A test is flaky**
→ Find the hidden dependency: time, order, shared state, network.
  Inject or isolate it; reproduce the failure deterministically.
  Retry-until-green is a finding, not a fix.

**Mocking grows heavy**
→ The design is the finding: report the coupling; prefer a fake or
  a seam over choreography.

**@SpringBootTest is reached for**
→ Pure logic: plain JUnit. Slice tests (@WebMvcTest, @DataJpaTest)
  for one layer. Full context only for wiring itself.

**Time or randomness appears**
→ Inject Clock/seed. An ambient now() in a test path is a flake
  scheduled for later.

## 5. Inputs
Code under test. Existing suite and fixtures. The failure being
encoded (bug report, boundary, spec line). Build/test runner config.

## 6. Outputs
ACP Response Block only. "Covered" is `known` only with the test that
goes red on the failure — cite it. Flake diagnoses `derived` from the
reproduced dependency.

## 7. Quality Gates
- Every fix ships with a red-first regression test.
- Every new test answers the mutation question.
- No ambient time/random in touched tests.

## 8. Failure Modes
- Suite green while the planted failure mode passes silently.
- Refactor breaking twenty interaction tests and zero behavior.
- Order-dependent fixtures passing alone, failing together.
- A minutes-long context boot for a millisecond assertion.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/junit-testing/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | fix commit without a failing-first test | unproven fix |
| 2 | verify()/times() where an outcome is assertable | choreography |
| 3 | new Date()/now()/Random() in a test path | scheduled flake |
| 4 | shared mutable static fixture | order coupling |
| 5 | @SpringBootTest on pure logic | wiring tax |
| 6 | fixed Thread.sleep in a test | permanent flake |

## 9. Worked Example
Claim: "refund logic is covered — 14 tests pass." Mutation: invert
the refund-window boundary; all 14 stay green — they verify mock
calls, none asserts the boundary outcome. Verdict: refuted (Known:
mutation run). Fix: one boundary test per edge (day 29, 30, 31),
outcome-asserted; choreography tests deleted.
