---
name: integration-testing
description: How to test a seam — the real dependency in production shape, the translation layer mocks hid, and rollback paths nobody exercises. Use for seam-level work.
---

# Integration Testing Skill

## 1. Identity
name: integration-testing · domain: practices
requires: test-strategy
complements: unit-testing · postgresql · docker
escalate_to: qa-agent (coverage decisions) · database-agent (data-layer seams)

## 2. Mission
Integration exists to catch what the mocks hid. A substitute that
speaks a different dialect hides it again.

## 3. Philosophy

**Reading requests.** "Add an integration test" hides two questions.
Which seam is at risk? What dependency must be real for the test to
mean anything? Integration is not a larger unit test. It exists to
catch the actual query, the actual schema, and the actual wire format.

**Where risk lives.** The boundaries. Translation from object model to
query. Transaction and rollback behavior. Serialization round trips.
Connection and timeout handling. The classic failure is every unit
green and the application broken, because the seam was only ever
mocked.

**Verification here.** Use the real dependency, close to production
shape. A containerized instance of the actual engine, not an in-memory
substitute with a different dialect. The real serializer, not a
hand-written stand-in. A persistence claim is verified by writing and
reading through the real store, including the rollback path.

**False-competence traps.** In-memory substitutes standing in for the
production engine. Tests that reset state by trusting a rollback that
was never exercised. Seams tested with the same mocks the unit tests
used. Slow suites justified as thorough while proving one path.

**Instincts.** Make the risky dependency real. Keep the rest mocked.
Test the rollback path explicitly. Seed and tear down deterministically
so failure order tells the truth.

## 4. Decision Strategy — the paths

**A seam is chosen for testing**
→ Name what must be real. Anything mocked at the seam removes the
  reason for the test.

**A substitute is proposed for the store**
→ Ask whether its dialect matches production. A different engine
  accepts queries the real one rejects, and the other way round.

**Transactions are involved**
→ Exercise the rollback. Commit paths are covered by accident;
  rollback paths are covered only deliberately.

**Serialization crosses a boundary**
→ Round trip it with the real serializer. Field naming, dates, and
  precision fail here and nowhere earlier.

**Tests share state**
→ Make setup and teardown deterministic. Order-dependent failure
  makes every report untrustworthy.

**A timeout or connection limit exists**
→ Test the exhausted case. Systems fail at the limit, and the limit
  is never reached in a two-row test.

**The suite is slow**
→ Ask which tests need the real dependency. Cost is justified at the
  seam and nowhere else.

## 5. Inputs
The seam under test and its real dependency. Container or environment
configuration. Transaction and rollback paths. Serialization formats.
Test data setup and teardown.

## 6. Outputs
ACP Response Block only. Facts labeled. A seam claim is `known` only
against the real dependency. Results from substitutes are `estimated`
and name the substitute.

## 7. Quality Gates
- Every seam test uses the real dependency for the risky side.
- Every transactional test exercises the rollback path.
- Every test sets up and tears down deterministically.

## 8. Failure Modes
- A query passing against a substitute and failing in production.
- A rollback path first exercised during an incident.
- Order-dependent failures making the report unreadable.
- A slow suite that still never touched the risky seam.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | in-memory substitute for the production engine | dialect mismatch |
| 2 | seam mocked in its own integration test | reason removed |
| 3 | transaction tested without rollback | half the behavior |
| 4 | serialization asserted without a round trip | format drift |
| 5 | shared state with no deterministic teardown | order-dependent results |
| 6 | limits never exercised | failure mode untested |
| 7 | slow suite with mocked risky seams | cost without coverage |

## 9. Worked Example
Claim: "persistence is covered by integration tests." Evidence: the
tests run against an in-memory engine while production uses another.
Path fires: a substitute with a different dialect. Verdict: weakened
(Known: test configuration; Assumed: query compatibility). Fix: run
the seam against a containerized production engine, and include the
rollback path.
