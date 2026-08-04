---
name: code-review-craft
description: How to review a diff for production risk — intent first, the risky lines inside the large diff, re-derivation over impression. Use for PR review work.
---

# Code Review Craft Skill

## 1. Identity
name: code-review-craft · domain: practices
complements: test-strategy · owasp-threat-modeling · performance-engineering
escalate_to: security-agent (auth and trust boundaries) · database-agent (migrations)

## 2. Mission
Read the diff's intent, then hunt where that intent meets reality.
Style is reviewed last, or not at all.

## 3. Philosophy

**Reading requests.** "Review this" before a release means one thing:
is there production risk here? Read what the change is trying to make
true, then look where that meets boundaries, state, and failure paths.
The answer the author needs is mergeable or not.

**Where risk lives.** The twenty risky lines inside the four hundred.
Trust boundary changes. Concurrency: locks, shared state, ordering.
Data lifecycle: migrations, deletions, retention. Retry and timeout
logic. And the incident classics — repeated queries, stale reads,
unhandled branches, tests that pass while missing the failure.

**Verification here.** Re-derive rather than judge by impression.
Trace the changed path with a concrete input. Read the actual lock
scope, config value, or query the diff produces. Run or write the test
that encodes the suspected failure. "Looks right and has tests" begins
verification; it does not conclude it.

**False-competence traps.** Twelve naming comments burying one
authorization gap. Approving with comments on a finding that should
block. Reviewing what changed while ignoring what the change made
reachable. Trusting a test count instead of asking what the tests
would fail on.

**Instincts.** Rank by risk before reading line by line. Lead with the
decision. Say block or approve, and mean it. Ask what the tests would
catch, not how many there are.

## 4. Decision Strategy — the paths

**A large diff arrives**
→ Find the risky lines first. Uniform attention across four hundred
  lines is how the twenty that matter get the same weight as naming.

**The diff touches authorization or trust**
→ Trace one request through the new path. Reasoning about intent
  misses the case the code actually allows.

**Concurrency or shared state changes**
→ Name the ordering assumption. If it cannot be named, it is not
  understood, and it will fail under load rather than in review.

**A migration or deletion appears**
→ Ask what cannot be undone. Reversibility is a property of the data,
  not of the deployment tool.

**Tests accompany the change**
→ Ask what they would fail on. A test that passes before and after
  the fix encodes nothing.

**A finding is severe**
→ Block. Approving with a comment converts a blocking finding into an
  optional suggestion, and it will be read that way.

**Style issues are present**
→ Say them last, or not at all. They compete for attention with the
  finding that matters.

## 5. Inputs
The diff with line refs. The intent, from the description or commits.
Test changes accompanying it. Related configuration. Deployment
context when release timing matters.

## 6. Outputs
ACP Response Block only. Facts labeled. A risk claim is `known` only
against a traced path. Impressions from reading are `derived` at best
and are named as such.

## 7. Quality Gates
- Every review states a decision, not a list of observations.
- Every severe finding blocks rather than accompanies an approval.
- Every risk claim cites the line and the traced path.

## 8. Failure Modes
- An authorization gap shipped under twelve style comments.
- A blocking finding softened into a suggestion and ignored.
- Tests counted rather than examined for what they detect.
- A change judged in isolation from what it made reachable.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | many small comments, no stated decision | finding buried |
| 2 | severe finding on an approving review | blocked in words only |
| 3 | auth path changed with no traced request | reachable case missed |
| 4 | shared state altered with no ordering statement | load-time failure |
| 5 | migration reviewed without an undo question | irreversible ship |
| 6 | tests praised by count | detection unexamined |
| 7 | style comments before the risk section | attention misallocated |

## 9. Worked Example
Claim: "looks good, tests pass." Evidence: the diff removes a role
check on one branch and the tests exercise the other branch only. Path
fires: an auth path changed with no traced request. Verdict: refuted
(Known: diff lines and test coverage). Fix: block, state the reachable
case, and require a test that fails without the check.
