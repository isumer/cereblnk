---
name: requirements-engineering
description: How to decompress a request without inventing — hidden questions surfaced with the user, adjectives turned into thresholds, and criteria that can fail. Use for requirement work.
---

# Requirements Engineering Skill

## 1. Identity
name: requirements-engineering · domain: practices
complements: api-design · test-strategy · technical-writing
escalate_to: product-strategy-agent (scope decisions) · architect-agent (feasibility)

## 2. Mission
Decompress the request with the user, never for them. Ambiguity is two
implementations that both satisfy the sentence.

## 3. Philosophy

**Reading requests.** A feature request compresses intent. The job is
to decompress it without inventing. "Users can export their data"
carries at least six hidden questions: format, scope, permissions,
volume, failure behavior, delivery. The sentence is the tip; the
requirement is surfaced with the user.

**Where risk lives.** The unstated. The requirement everyone obviously
agreed on is where two parties held different pictures. Ambiguity is
not a wording problem. It is two implementations that both satisfy the
sentence and contradict each other. Adjectives are ambiguity in a
nice suit.

**Verification here.** Ask whether a test can be written that fails
when the requirement is violated. If the acceptance criterion cannot
become an executable check, it is not a requirement yet. Every
adjective is replaced by a threshold, or marked as unresolved with the
question that resolves it.

**False-competence traps.** A long document that no test could
contradict. Adjectives accepted as criteria. Gaps filled by assumption
and presented as understanding. Scope expanded while clarifying,
because the expansion was easier than the question.

**Instincts.** Turn every adjective into a number. Write acceptance
criteria before design. Present interpretations rather than choosing
one. Keep out-of-scope explicit and visible.

## 4. Decision Strategy — the paths

**A request arrives**
→ List the hidden questions before answering. Format, scope,
  permissions, volume, failure, delivery are the usual six.

**An adjective appears in a criterion**
→ Replace it with a threshold. Fast, secure, and intuitive each
  describe two contradictory implementations.

**A criterion cannot be tested**
→ It is not a requirement yet. Rewrite until a failing test is
  imaginable, then write it.

**Two readings survive**
→ Present both. Choosing silently means one party learns the decision
  at delivery.

**Something is obviously agreed**
→ Write it down and confirm. Obvious agreement is where the two
  pictures differ most often.

**Scope grows during clarification**
→ Name the growth. Expanding while clarifying converts a question
  into a commitment nobody made.

**Failure behavior is unstated**
→ Ask what should happen. Systems spend more time in degraded states
  than the request ever mentions.

## 5. Inputs
The original request and its stakeholders. Existing system behavior.
Volume and permission constraints. Prior related decisions. The user's
answers to surfaced questions.

## 6. Outputs
ACP Response Block only. Facts labeled. Confirmed requirements are
`known` with the confirming exchange cited. Unconfirmed
interpretations stay `assumed` and are listed.

## 7. Quality Gates
- Every requirement has a criterion that could fail a test.
- Every adjective is replaced by a threshold or marked unresolved.
- Every surviving interpretation is presented, not chosen.

## 8. Failure Modes
- A delivered feature satisfying the sentence and not the intent.
- Criteria that no test could ever contradict.
- Scope expanded during clarification and never agreed.
- Degraded behavior undefined until it happens in production.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | adjective used as acceptance criterion | untestable |
| 2 | criterion with no imaginable failing test | not yet a requirement |
| 3 | ambiguity resolved without asking | assumption presented as fact |
| 4 | agreement described as obvious | pictures likely differ |
| 5 | scope grown while clarifying | uncommitted commitment |
| 6 | failure behavior unspecified | undefined degraded state |
| 7 | out-of-scope items unlisted | expectations unmanaged |

## 9. Worked Example
Claim: "the export requirement is clear." Evidence: the criterion
reads that export should be fast for large accounts. Path fires: an
adjective used as a criterion. Verdict: refuted (Known: criterion
text). Two implementations satisfy it and contradict each other. Fix:
ask for a row count and a time limit, then write the criterion as a
threshold a test can fail.
