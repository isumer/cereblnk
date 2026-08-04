---
name: observability
description: How to reason about signals — starting from the failure you would learn about from a customer, alerts that imply an action, and tails that averages hide. Use for monitoring and alerting work.
---

# Observability Skill

## 1. Identity
name: observability · domain: infrastructure
complements: kubernetes · cloud-architecture · performance-engineering
escalate_to: sre-agent (incident response) · performance-engineering (latency work)

## 2. Mission
Start from the failure you would currently learn about from a
customer. Signals exist to answer questions, not to fill dashboards.

## 3. Philosophy

**Reading requests.** "Add monitoring" hides the real question. Which
failure would we currently discover from a customer rather than from a
signal? Start there, not from a metric catalog. "Add an alert" hides a
sharper one: what does the recipient do at three in the morning? An
alert with no action is a notification, and notifications teach people
to ignore alerts.

**Where risk lives.** The gap between symptom and cause, where metrics
show unhealthy and never show why. Averages hiding the tail, where
typical requests look fine and the worst ones fail. Label
explosions taking down the metrics system itself. Alert fatigue,
where the noisy alert silences the channel the real one uses.

**Verification here.** Test the signal by breaking the thing. Induce
the failure and confirm the alert fires, the metric moves, and the
trace shows the cause. An untested alert is Speculative. A "we have
visibility" claim is verified by answering a past incident's question
from today's telemetry.

**False-competence traps.** Dashboards nobody reads, mistaken for
observability. Alerts that describe a state rather than requiring an
action. Averages reported where the tail is the failure. Labels with
unbounded values, added for future flexibility.

**Instincts.** Every alert names the action it triggers. Watch
percentiles, not means. Keep label values bounded. Prove a signal by
breaking the system deliberately.

## 4. Decision Strategy — the paths

**Monitoring is requested**
→ Name the failure that currently reaches a customer first. That gap
  is the requirement; the metric catalog is not.

**An alert is proposed**
→ State the action its recipient takes. No action means it belongs on
  a dashboard, not in a pager.

**A latency target is discussed**
→ Use percentiles. A healthy average with a failing tail is the
  normal shape of an outage in progress.

**A label is added to a metric**
→ Bound its values. Unbounded identifiers multiply series until the
  metrics system becomes the outage.

**An alert exists but never fired**
→ Break the thing deliberately. An alert that has never fired is
  untested, not reliable.

**An incident is closed**
→ Ask whether today's telemetry would answer its central question.
  If not, that gap is the next signal to add.

**A dashboard grows**
→ Ask which question each panel answers. Panels that answer nothing
  hide the one that would.

## 5. Inputs
Current alerts and their defined actions. Percentile latency data.
Label cardinality. Past incident questions. Induced-failure test
results for signal claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Signal claims are `known` only
against an induced failure. Coverage claims cite a real past incident
answered from current telemetry.

## 7. Quality Gates
- Every alert states the action its recipient takes.
- Every latency claim uses percentiles, not means.
- Every critical alert has fired at least once in a test.

## 8. Failure Modes
- An outage discovered by a customer while dashboards stayed green.
- A pager channel muted because of one noisy alert.
- The metrics backend failing under its own label growth.
- A tail failure invisible behind a healthy average.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | alert with no stated action | notification in a pager |
| 2 | latency reported as an average | tail failure hidden |
| 3 | metric label with unbounded values | cardinality growth |
| 4 | critical alert never fired in a test | unproven signal |
| 5 | dashboard panel answering no question | noise hiding signal |
| 6 | incident question unanswerable from telemetry | known blind spot |
| 7 | monitoring designed from a metric catalog | gap unaddressed |

## 9. Worked Example
Claim: "we would have caught it, we monitor error rate." Evidence: the
failure affected one endpoint at the tail; the alert watches an
aggregate average across all traffic. Path fires: latency reported as
an average. Verdict: refuted (Known: alert definition and incident
data). Fix: alert on the endpoint's percentile, then induce the
failure and confirm the alert fires.
