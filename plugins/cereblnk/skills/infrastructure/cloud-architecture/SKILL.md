---
name: cloud-architecture
description: How to reason about cloud designs — availability against which failure, blast radius, data gravity, and cost shape at production volume. Use for topology and platform decisions.
---

# Cloud Architecture Skill

## 1. Identity
name: cloud-architecture · domain: infrastructure
complements: terraform · kubernetes · observability
escalate_to: sre-agent (failover verification) · compliance-agent (residency obligations)

## 2. Mission
Availability is meaningless without naming the failure it survives.
Design answers a specific failure or it answers none.

## 3. Philosophy

**Reading requests.** "Move this to the cloud" hides three questions.
What is the availability requirement? What data may live where? What
does this cost at expected volume? "Make it highly available" hides
the decisive one: available against which failure — instance, zone,
region, or dependency? Each carries a different price and design.

**Where risk lives.** Blast radius, where one account or one network
boundary holds everything. Data gravity and transfer cost, which
exceed storage cost and create lock-in. Implicit single points: one
gateway, one managed dependency, one credential. Cost shapes that work
at demo scale and become unaffordable at production volume.

**Verification here.** An availability claim is verified by naming the
failure it survives and exercising the failover. A configuration
labelled redundant means nothing if the path was never tested. A cost
claim is verified against the pricing model at projected volume,
including transfer and request counts. Read the deployed topology, not
the diagram.

**False-competence traps.** Multi-region designs for systems whose
recovery objective would accept a restore. Redundancy declared and
never exercised. Cost estimated from compute hours only. Diagrams
trusted where the deployed topology diverged months ago.

**Instincts.** Name the failure first, then design for it. Keep blast
radius small and explicit. Price transfer, not just storage and
compute. Exercise every failover you claim.

## 4. Decision Strategy — the paths

**High availability is requested**
→ Name the failure to survive. Instance, zone, region, and dependency
  failures have different designs and very different costs.

**Redundancy is configured**
→ Exercise the failover. Untested failover is a belief, and beliefs
  fail at the least convenient moment.

**Data is placed**
→ Ask what leaving costs. Transfer charges and gravity decide future
  options more than the storage decision does.

**A single component carries everything**
→ Name it as the blast radius. One gateway, one account, or one
  credential is the design's real availability number.

**A cost estimate is produced**
→ Include transfer and request volume. Compute hours alone
  underestimate by the margin that matters.

**A diagram is offered as evidence**
→ Read the deployed topology instead. Diagrams describe intentions
  from the day they were drawn.

**Compliance touches data location**
→ Establish the constraint before the design. Residency retrofits are
  migrations, not configuration changes.

## 5. Inputs
Availability requirements and recovery objectives. Deployed topology,
not diagrams. Pricing model with projected volume, transfer, and
requests. Failover test evidence. Data residency constraints.

## 6. Outputs
ACP Response Block only. Facts labeled. Availability claims are
`known` only against exercised failover. Cost claims are `estimated`
with volume assumptions stated.

## 7. Quality Gates
- Every availability claim names the failure it survives.
- Every redundancy claim cites an exercised failover.
- Every cost estimate includes transfer and request volume.

## 8. Failure Modes
- A redundant design that has never failed over successfully.
- A bill that grows faster than usage because transfer was unpriced.
- One shared component defining the true availability.
- A compliance constraint discovered after the data landed.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | availability claimed without naming a failure | undefined guarantee |
| 2 | redundancy configured, never exercised | belief, not capability |
| 3 | cost estimated from compute only | transfer unpriced |
| 4 | one component shared by everything | real blast radius |
| 5 | topology taken from a diagram | drift unread |
| 6 | data placed before residency is established | migration later |
| 7 | multi-region for a restorable workload | cost without requirement |

## 9. Worked Example
Claim: "we are highly available, the database is replicated." Evidence:
the standby has never been promoted and the application holds one
connection string. Path fires: redundancy configured and never
exercised. Verdict: weakened (Known: topology; Assumed: failover
works). Fix: rehearse a promotion with traffic running, and measure
how long clients take to reconnect.
