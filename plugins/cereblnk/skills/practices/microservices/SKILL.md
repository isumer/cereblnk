---
name: microservices
description: How to reason about service boundaries — which pain the split answers, boundaries along capabilities, and independence proven by deploying alone. Use for decomposition work.
---

# Microservices Skill

## 1. Identity
name: microservices · domain: practices
complements: event-driven-architecture · api-design · kubernetes
escalate_to: architect-agent (boundary decisions) · sre-agent (operational cost)

## 2. Mission
A split answers a specific pain. Without one, it buys distributed cost
for organizational fashion.

## 3. Philosophy

**Reading requests.** "Split this into services" hides the question
the split is meant to answer. Independent deployment? Independent
scaling? Team autonomy? If none is the actual pain, the split adds
distributed-system cost and returns nothing. "Add a service" hides who
owns its data, its uptime, and its schema evolution.

**Where risk lives.** Boundaries drawn along technical layers rather
than business capabilities, so every feature touches three services
and nothing deploys alone. Shared stores recreating the coupling the
split was meant to remove. Synchronous chains multiplying failure and
latency. Distributed transactions attempted where a saga belonged.

**Verification here.** An independence claim is verified by deploying
one service alone and confirming nothing else must ship with it. The
deploy history is the evidence. A resilience claim is verified by
failing a dependency deliberately and watching what the caller does.

**False-competence traps.** A distributed monolith described as
microservices. Services sharing a database schema. Chained
synchronous calls where each hop multiplies failure probability.
Boundaries chosen from a diagram rather than from change history.

**Instincts.** Draw boundaries along capabilities that change
together. Give each service its own data. Prefer asynchronous
communication across boundaries. Prove independence by deploying.

## 4. Decision Strategy — the paths

**A split is proposed**
→ Name the pain it solves. Deployment, scaling, or autonomy — one of
  them, specifically, or the cost has no return.

**A boundary is drawn**
→ Check change history. Components that always change together
  belong together, whatever the layer diagram suggests.

**Two services share a store**
→ Name it as coupling. Shared schemas mean neither service can evolve
  its data alone, which was the point of splitting.

**A synchronous chain forms**
→ Count the hops. Each one multiplies failure probability and adds
  its latency to every request.

**A transaction spans services**
→ Use a saga with compensations. Distributed transactions promise
  atomicity that the network will not honor.

**Independence is claimed**
→ Deploy one alone. The claim is about deployment, so deployment is
  the evidence.

**A dependency can fail**
→ Fail it deliberately and watch. Resilience described in a document
  is Assumed until exercised.

## 5. Inputs
Service boundaries and their data ownership. Change history across
components. Call graphs and synchronicity. Deploy history for
independence claims. Failure injection results.

## 6. Outputs
ACP Response Block only. Facts labeled. Independence claims are
`known` only against a solo deployment. Resilience claims cite a
failure injection.

## 7. Quality Gates
- Every split names the pain it solves.
- Every service owns its data exclusively.
- Every independence claim cites a solo deploy.

## 8. Failure Modes
- A distributed monolith with all the cost and none of the autonomy.
- A schema change blocked because another service reads the table.
- A user request failing because the fourth hop timed out.
- Compensations discovered missing during a partial failure.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | split with no named pain | cost without return |
| 2 | boundary along a technical layer | every feature crosses it |
| 3 | two services sharing a schema | coupling preserved |
| 4 | synchronous chain of three or more | multiplied failure |
| 5 | cross-service transaction | atomicity unavailable |
| 6 | independence claimed with no solo deploy | assumed |
| 7 | resilience described but never injected | untested |

## 9. Worked Example
Claim: "the services are independent." Evidence: the deploy history
shows all three released together on every occasion. Path fires: an
independence claim with no solo deploy. Verdict: refuted (Known:
deploy history). Fix: identify what forces the coupling — usually a
shared schema or a synchronous contract — and remove that first.
