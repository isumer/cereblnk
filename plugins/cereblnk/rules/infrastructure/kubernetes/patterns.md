---
name: kubernetes-patterns
genre: constraint
category: infrastructure
density: neutral
paths:
  - "**/k8s/**/*.y*ml"
  - "**/manifests/**/*.y*ml"
  - "**/*deployment*.y*ml"
  - "**/*statefulset*.y*ml"
  - "**/*daemonset*.y*ml"
  - "**/*service*.y*ml"
  - "**/*ingress*.y*ml"
---

# Kubernetes Patterns

Judgment lives in `skills/infrastructure/kubernetes/`.

## The workload contract

- Every workload declares what ready means, and what alive means
- Probes match measured startup, not a hopeful number

```yaml
startupProbe:
  httpGet: { path: /health/started, port: 8080 }
  failureThreshold: 30
  periodSeconds: 5
readinessProbe:
  httpGet: { path: /health/ready, port: 8080 }
  periodSeconds: 5
livenessProbe:
  httpGet: { path: /health/live, port: 8080 }
  periodSeconds: 20
```

Avoid: a liveness probe faster than startup, restarting a healthy
workload. Readiness that only checks the port. A probe copied between
unlike services.

## Resources and disruption

- Requests and limits are declared; eviction order is not left to chance
- A rollout states how much capacity it may remove at once

```yaml
resources:
  requests: { cpu: "250m", memory: "512Mi" }
  limits:   { cpu: "1000m", memory: "512Mi" }
---
spec:
  minAvailable: 1
  selector:
    matchLabels: { app: settlement }
```

Avoid: a workload with no requests, evicted first under pressure. A
rollout that removes every replica of a singleton. A budget that
blocks all progress.

## Change safety

- A change is diffed against what runs, before it applies
- Immutable fields are identified, because changing them recreates

```bash
kubectl diff -f manifests/settlement/
```

Avoid: an apply judged from the source rather than the diff. A
recreation during peak traffic. A selector edited in place, which
Kubernetes refuses on an existing Deployment.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a workload or probe is defined | The workload contract |
| resources or a rollout change | Resources and disruption |
| a manifest is applied | Change safety |
