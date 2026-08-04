---
name: event-driven-architecture
description: How to reason about events — facts versus commands, at-least-once as the default, ordering only within a key, and the event nobody consumed. Use for messaging work.
---

# Event-Driven Architecture Skill

## 1. Identity
name: event-driven-architecture · domain: practices
complements: microservices · api-design · observability
escalate_to: architect-agent (topology decisions) · sre-agent (delivery failures)

## 2. Mission
Assume every message arrives twice and out of order. Design that is
correct under those assumptions is correct.

## 3. Philosophy

**Reading requests.** "Make it event-driven" hides the coupling
question. Are we decoupling deployment, or moving a synchronous
dependency into an invisible one? "Publish an event when this happens"
hides three more. Is it a fact or a command? May consumers replay it?
Who owns its schema, permanently?

**Where risk lives.** Delivery semantics, where at-least-once is the
norm and exactly-once is usually a story. Ordering, guaranteed within
a key at best. Schema evolution across independently deployed
consumers. Poison messages blocking a partition. And the silent
failure: the event nobody consumed, discovered days later.

**Verification here.** An idempotency claim is verified by delivering
the same message twice and asserting one effect. An ordering claim is
verified against the partitioning key, not against intuition. A
consumption claim is verified by lag metrics, because an unconsumed
topic looks exactly like a quiet one.

**False-competence traps.** Exactly-once delivery assumed from a
configuration flag. Ordering assumed across keys. Events shaped as
commands, recreating the coupling the split removed. Consumer
failures retried forever, blocking everything behind them.

**Instincts.** Make every consumer idempotent. Name events as facts in
the past tense. Version schemas additively. Watch lag as a first-class
signal.

## 4. Decision Strategy — the paths

**An event is defined**
→ Decide fact or command. A command wearing an event's name puts the
  producer back in charge of the consumer's behavior.

**A consumer is written**
→ Make it idempotent. Redelivery is normal operation, not an
  exception, and the second delivery must change nothing.

**Ordering matters**
→ Establish the partitioning key. Order holds within a key and
  nowhere else, whatever the diagram implies.

**A schema changes**
→ Add rather than alter. Consumers deploy independently, so both
  versions exist in flight for as long as that takes.

**A message cannot be processed**
→ Route it aside after bounded retries. Infinite retry on one poison
  message stops every message behind it.

**A topic is quiet**
→ Check lag and consumption. Nothing consumed and nothing produced
  look identical from the outside.

**Two systems must agree**
→ Use an outbox at the source. A write plus a publish, unlinked, will
  eventually disagree.

## 5. Inputs
Event definitions and schemas. Delivery guarantees of the platform.
Partitioning keys. Consumer idempotency implementation. Lag and
dead-letter metrics.

## 6. Outputs
ACP Response Block only. Facts labeled. Idempotency claims are `known`
only against a double-delivery test. Ordering claims cite the
partitioning key.

## 7. Quality Gates
- Every consumer is proven idempotent by double delivery.
- Every ordering claim names its partitioning key.
- Every consumer has bounded retries and a dead-letter path.

## 8. Failure Modes
- Duplicate effects from a redelivery treated as impossible.
- Cross-key ordering assumed and violated under load.
- A partition stalled behind one unprocessable message.
- A schema change breaking a consumer that had not deployed yet.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | consumer with no idempotency mechanism | duplicate effects |
| 2 | ordering assumed across keys | violated under load |
| 3 | exactly-once claimed from configuration | delivery misunderstood |
| 4 | retry with no bound or dead-letter path | partition stalled |
| 5 | event named as an instruction | coupling recreated |
| 6 | schema field altered rather than added | in-flight consumers break |
| 7 | write and publish without an outbox | eventual disagreement |

## 9. Worked Example
Claim: "duplicates are impossible, the broker is exactly-once."
Evidence: the consumer inserts a row with no natural key or
deduplication. Path fires: a consumer with no idempotency mechanism.
Verdict: refuted (Known: consumer code). Redelivery after a partial
acknowledgement inserts twice. Fix: deduplicate on a message key, then
deliver the same message twice and assert one row.
