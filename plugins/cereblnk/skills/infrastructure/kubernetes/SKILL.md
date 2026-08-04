---
name: kubernetes
description: How to reason about Kubernetes — the contract a workload declares, what the cluster may do to it, and probe semantics that turn slow starts into crash loops. Use for manifest and runtime work.
---

# Kubernetes Skill

## 1. Identity
name: kubernetes · domain: infrastructure
complements: docker · helm · observability
escalate_to: sre-agent (production incidents) · security-agent (RBAC and boundaries)

## 2. Mission
Interrogate the cluster, not the manifest. Declared intent and
observed behavior diverge exactly where it matters.

## 3. Philosophy

**Reading requests.** "Deploy this" hides the contract questions. What
does ready mean for this workload? What may the cluster do to it —
evict, reschedule, scale? What happens to in-flight work when it does?
"The pod is crashing" starts by asking which loop is unhappy:
scheduler, kubelet, probes, or the application.

**Where risk lives.** Probes with the wrong semantics, restarting a
slow-starting workload into a loop. Missing resource declarations,
making eviction a lottery. Rollout settings fighting disruption
budgets during upgrades. Access boundaries assumed rather than read.

**Verification here.** Ask the cluster. Events for a scheduling claim.
The rendered object from the server for a configuration claim. For a
zero-downtime claim, delete a pod and watch the drain with traffic
running. A rollout claim is verified by observing one.

**False-competence traps.** Manifest fluency mistaken for operational
knowledge. Probe and resource blocks copied between unlike services.
Applying treated as always safe while immutable fields force
recreation. Scaling configured on the wrong signal for the workload.

**Instincts.** Give every workload requests and limits. Match probe
semantics to actual startup behavior. Verify drain under traffic.
Read the rendered object rather than the file.

## 4. Decision Strategy — the paths

**A workload is deployed**
→ Define what ready means for it. Ready that only proves the process
  started sends traffic to something that cannot serve.

**A liveness probe is configured**
→ Check it against real startup time. A probe faster than warm-up
  converts a slow start into a permanent restart loop.

**Resources are unset**
→ Set requests and limits. Without them the scheduler guesses and
  eviction order becomes arbitrary.

**Zero downtime is claimed**
→ Delete a pod with traffic running and watch. Termination handling
  and drain behavior decide this, not the rollout strategy alone.

**A manifest is applied**
→ Check for immutable fields. Some changes recreate rather than
  update, and recreation during peak is an outage.

**A rollout runs during maintenance**
→ Check the disruption budget against the strategy. Together they can
  block progress or permit too much at once.

**Access is assumed**
→ Read the actual role bindings. Assumed boundaries are discovered
  during an incident, from the wrong side.

## 5. Inputs
Manifests and the server-rendered objects. Cluster events for
scheduling claims. Probe configuration against measured startup.
Resource declarations. Observed rollout and drain behavior.

## 6. Outputs
ACP Response Block only. Facts labeled. Behavior claims are `known`
only against cluster observation. Manifest reading yields `derived` at
best.

## 7. Quality Gates
- Every workload declares requests and limits.
- Every probe matches measured startup and failure behavior.
- Every zero-downtime claim cites an observed drain under traffic.

## 8. Failure Modes
- A slow-starting service restarted forever by its own probe.
- Traffic routed to a pod that reported ready too early.
- Eviction removing the wrong workload under pressure.
- An apply recreating a resource during peak traffic.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/infrastructure/kubernetes/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | liveness probe faster than measured startup | restart loop |
| 2 | readiness proving only that the process started | traffic to a cold pod |
| 3 | workload with no requests or limits | arbitrary eviction |
| 4 | zero-downtime claimed with no observed drain | unverified |
| 5 | change touching an immutable field | recreation, not update |
| 6 | rollout strategy unchecked against disruption budget | stalled or unsafe |
| 7 | access boundary taken from intent | discovered in an incident |

## 9. Worked Example
Claim: "the service restarts because it is unstable." Evidence: the
liveness probe allows fewer seconds than the measured warm-up. Path
fires: a probe faster than startup. Verdict: refuted (Known: probe
configuration and startup timing). The workload is healthy and is
being killed before it finishes starting. Fix: use a startup probe,
then observe one clean rollout.
