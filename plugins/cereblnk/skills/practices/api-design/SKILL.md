---
name: api-design
description: How to reason about API contracts — breaking changes that do not look like it, error semantics, idempotency where retries happen, unbounded collections. Use for contract work.
---

# API Design Skill

## 1. Identity
name: api-design · domain: practices
complements: event-driven-architecture · microservices · code-review-craft
escalate_to: architect-agent (boundary decisions) · security-agent (authorization surface)

## 2. Mission
Versioning is a consequence of a compatibility promise, not a
substitute for having one.

## 3. Philosophy

**Reading requests.** "Add an endpoint" hides the contract questions.
Who consumes it, today and plausibly? What are its error semantics? Is
it idempotent? How will it change without breaking anyone? "Version
the API" hides the real one: what is our actual compatibility promise?

**Where risk lives.** Breaking changes that do not look like it. A
meaning shifting under a stable shape. Validation tightened.
Defaults reordered. Error contracts left to framework defaults that
leak internals. Collections without pagination, discovered at scale.
Idempotency absent exactly where retries happen.

**Verification here.** Analyze consumer impact against the current
contract artifact — the specification and the actual responses, not
the intent. Classify each change as additive, tolerant-reader safe, or
breaking, with evidence. Idempotency is verified by replaying the
request. Error contracts are verified by inducing the errors.

**False-competence traps.** Style debates about verbs and structure
while the error body leaks internals. Compatibility claimed without
enumerating consumers. A version number added instead of a promise. A
collection endpoint with no limit, shipped because the test data was
small.

**Instincts.** Enumerate consumers before changing anything. Make
error shapes explicit and stable. Paginate every collection from the
first version. Make retryable operations idempotent by design.

## 4. Decision Strategy — the paths

**A field's meaning changes**
→ Treat it as breaking even if the shape holds. Consumers parse
  meaning, and nothing in the schema will warn them.

**Validation is tightened**
→ Enumerate who currently sends what. Requests accepted yesterday and
  rejected today are a breaking change for their senders.

**A collection is returned**
→ Paginate from the first release. Adding a limit later breaks every
  consumer that assumed completeness.

**An operation can be retried**
→ Make it idempotent, with a key the client controls. Retries happen
  whether or not the design expects them.

**An error is returned**
→ Define its shape deliberately. Framework defaults leak internals
  and become a contract nobody wrote.

**Compatibility is claimed**
→ Name the consumers checked. Without enumeration the claim is
  Assumed, however careful the change looked.

**A version is introduced**
→ State the promise it encodes. A number with no stated guarantee
  moves the problem rather than solving it.

## 5. Inputs
Current contract artifact and actual responses. Consumer inventory and
their usage. Change classification evidence. Replay results for
idempotency. Induced errors for contract verification.

## 6. Outputs
ACP Response Block only. Facts labeled. Compatibility claims are
`known` only with a consumer enumeration. Idempotency claims cite a
replay.

## 7. Quality Gates
- Every change is classified against the current contract artifact.
- Every collection endpoint is paginated.
- Every retryable operation has a client-controlled idempotency key.

## 8. Failure Modes
- A consumer broken by a meaning change under an unchanged shape.
- A double charge from a retry the design never anticipated.
- A stack trace shipped as an error body and depended upon.
- An endpoint returning everything until the data grew.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | field meaning changed, shape unchanged | silent break |
| 2 | validation tightened with no sender analysis | rejected valid clients |
| 3 | collection without pagination | breaks at scale |
| 4 | retryable operation with no idempotency key | duplicate effects |
| 5 | error body from framework defaults | internals as contract |
| 6 | compatibility claimed with no consumer list | assumed |
| 7 | version added with no stated promise | number without meaning |

## 9. Worked Example
Claim: "the change is backward compatible, the response shape is the
same." Evidence: a status field now excludes a value it previously
returned. Path fires: a meaning change under an unchanged shape.
Verdict: refuted (Known: contract diff and consumer switch
statements). Consumers branch on that value. Fix: keep emitting it, or
version the endpoint and enumerate who must move.
