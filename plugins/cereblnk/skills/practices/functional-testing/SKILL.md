---
name: functional-testing
description: How to verify a system against its criteria — black box through the real interface, documented failure behavior, and criteria obtained rather than invented. Use for acceptance work.
---

# Functional Testing Skill

## 1. Identity
name: functional-testing · domain: practices
requires: test-strategy
complements: bdd-gherkin · integration-testing · requirements-engineering
escalate_to: qa-agent (suite decisions) · requirements-agent (missing criteria)

## 2. Mission
Drive the system through its real interface against criteria somebody
agreed to. Invented pass conditions verify nothing.

## 3. Philosophy

**Reading requests.** "Functionally test this" hides the question that
decides the work. Against which acceptance criteria, from whose
definition of done? Functional testing is black box: it verifies the
system does what the requirement says, through its real interface,
without asserting how. Missing criteria means the first task is
obtaining them.

**Where risk lives.** Criteria that were never testable, usually
adjectives. The gap between what was specified and what was built.
Tests that peek at internals, which stops them being black box and
lets interface-level breaks through. And happy-path suites that never
exercise documented failure behavior.

**Verification here.** Drive the system through its real interface
with the agreed criteria as the oracle. A pass claim is `known` only
against a criterion somebody agreed to. Failure behavior is verified
by inducing the failure, not by reading the specification that
promises it.

**False-competence traps.** Pass conditions invented where criteria
were missing. Internals inspected to make a test pass. Only the
success path exercised. A green suite reported as acceptance while the
criteria were never agreed.

**Instincts.** Obtain criteria before writing tests. Stay outside the
system. Exercise documented failures explicitly. Report against
criteria, not against test counts.

## 4. Decision Strategy — the paths

**Criteria are missing**
→ Obtain them before testing. Inventing pass conditions produces a
  green suite that proves agreement with yourself.

**A test needs internal access to pass**
→ Reconsider the test. Reaching inside stops it detecting the
  interface break it existed to catch.

**Failure behavior is documented**
→ Induce it. Documented behavior that was never triggered is a
  promise, not a property.

**A criterion contains an adjective**
→ Send it back for a threshold. Untestable criteria produce tests
  that cannot fail.

**The suite is green**
→ Report against criteria, one by one. Test counts describe effort,
  not acceptance.

**The system has several interfaces**
→ Test through the one the user uses. Verifying a path nobody takes
  proves the wrong thing works.

**Specification and build diverge**
→ Name the divergence rather than picking a side. It is a decision
  for the requirement owner, not for the tester.

## 5. Inputs
Agreed acceptance criteria. The real interface under test. Documented
failure behavior. Induced-failure results. Specification and build
comparison.

## 6. Outputs
ACP Response Block only. Facts labeled. A pass claim is `known` only
against an agreed criterion. Invented conditions are `assumed` and
named as such.

## 7. Quality Gates
- Every test maps to an agreed acceptance criterion.
- Every documented failure behavior is induced at least once.
- Every test drives the system from outside.

## 8. Failure Modes
- A green suite verifying conditions nobody agreed to.
- An interface break missed by tests that reached inside.
- Documented error handling that has never run.
- Acceptance reported as a test count rather than per criterion.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | test with no mapped criterion | invented pass condition |
| 2 | test requiring internal access | not black box |
| 3 | documented failure never induced | promise, not property |
| 4 | criterion containing an adjective | cannot fail |
| 5 | acceptance reported as a test count | criteria unaddressed |
| 6 | interface tested that no user uses | wrong path proven |
| 7 | divergence resolved by the tester | decision taken by the wrong role |

## 9. Worked Example
Claim: "the feature is functionally verified, all tests pass."
Evidence: three of the tests assert conditions written by the test
author, with no matching criterion. Path fires: a test with no mapped
criterion. Verdict: weakened (Known: test-to-criteria mapping). Fix:
obtain the criteria, map each test, and report acceptance per
criterion rather than as a total.
