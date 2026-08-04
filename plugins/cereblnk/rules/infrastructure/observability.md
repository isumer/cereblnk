---
name: infrastructure-observability
genre: constraint
category: infrastructure
density: neutral
paths:
  - "**/prometheus*.yml"
  - "**/prometheus*.yaml"
  - "**/alert*.rules.yml"
  - "**/alertmanager*.y*ml"
  - "**/grafana/**/*.json"
  - "**/logback*.xml"
  - "**/otel*.y*ml"
---

# Observability

Extends [`common/logging.md`](../common/logging.md). Judgment lives in
`skills/infrastructure/observability/`.

## Signals answer questions

- A signal is added because a failure reached a customer first
- A dashboard panel answers a question, or it is removed

Avoid: monitoring designed from a metric catalogue. A panel nobody
reads hiding the one that matters. A signal added because a tool
offered it.

## Alerts

- Every alert names the action its recipient takes at three in the morning
- An alert that has never fired is untested, so it is tested

```text
stated     what is broken, for whom, and what to do
proven     by inducing the failure once
routed     to someone who can act, not to a shared inbox
```

Avoid: an alert describing a state with no action. A pager channel
muted by one noisy rule. A critical alert never fired in a drill.

## Measurement

- Latency is watched at percentiles; an average hides the failure
- Metric labels are bounded, so the metrics system is not the outage

Avoid: a mean reported where the tail is the complaint. An identifier
used as a label. A cardinality problem found by the metrics backend
falling over.

## Tracing and correlation

- A request carries one identifier across every hop
- A log line, a trace and a metric can be joined without guessing

Avoid: an incident spent correlating by timestamp. A trace that stops
at a service boundary. Two identifiers for one request.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a metric or dashboard is added | Signals answer questions |
| an alert is defined | Alerts |
| latency or a label is recorded | Measurement |
| a request crosses a service | Tracing and correlation |
