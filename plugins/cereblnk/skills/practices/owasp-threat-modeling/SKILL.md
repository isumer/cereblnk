---
name: owasp-threat-modeling
description: How to model threats for a specific system — trust boundaries, traced paths from entry to sink, mitigations proven by their enforcing evidence. Use for security analysis.
---

# Threat Modeling Skill

## 1. Identity
name: owasp-threat-modeling · domain: practices
complements: devsecops · api-design · code-review-craft
escalate_to: security-agent (findings and severity decisions)

## 2. Mission
Walk the system, then report in the category's language. A category
walk finds what the categories already knew.

## 3. Philosophy

**Reading requests.** "Threat-model this" hides scope decisions. Which
assets matter: data, availability, money, reputation? Who are the
realistic adversaries? What risk is already accepted? "Are we
compliant" asks for a category walk; a threat model is a system walk.
Do the second and report in the first's language.

**Where risk lives.** Every crossing where data changes trust level.
User to application, application to store, service to service, admin
paths, webhooks, uploads. And every place identity is established or
merely assumed. The dangerous gaps are unmapped flows: the debug
endpoint, the batch job, the internal interface that is not.

**Verification here.** A threat is verified by tracing its concrete
path in evidence: entry point, then validation or its absence, then
sink. A mitigation is `known` only with its enforcing evidence — the
filter, the policy, the constraint. "We validate input" without the
validator's location is Assumed. Categories with no applicable surface
are recorded as such, with the reason.

**False-competence traps.** A filled table with no system-specific
paths. Elaborate adversaries crowding out the unauthenticated
endpoint. Mitigations claimed from intent. Findings without a traced
path, which cannot be fixed or disproved.

**Instincts.** Map flows before listing threats. Trace to a sink or do
not claim. Record non-applicable categories with reasons. Rank by
reachable damage, not by category severity.

## 4. Decision Strategy — the paths

**A model is requested**
→ Establish the assets and the accepted risk first. Everything after
  that is prioritization, and without it the list has no order.

**A trust boundary is crossed**
→ Trace what validates the crossing. A boundary with no named
  validator is the finding, before any category is consulted.

**A mitigation is claimed**
→ Cite the enforcing artifact. Filters, policies, and constraints are
  evidence; descriptions of intent are not.

**A category has no applicable surface**
→ Record it with the reason. Silent omission is indistinguishable
  from an oversight when the model is read later.

**An entry point is undocumented**
→ Treat it as the priority. Debug endpoints, batch jobs, and internal
  interfaces are where the unmapped flow lives.

**A threat has no traced path**
→ It stays Speculative. Untraceable threats cannot be fixed or
  disproved, and they crowd the list.

**Severity is assigned**
→ Rank by reachable damage in this system. Category severity
  describes the class, not this instance.

## 5. Inputs
Data flow map with trust boundaries. Entry points including
undocumented ones. Validation and authorization code with line refs.
Existing accepted risks. Configuration for enforcement claims.

## 6. Outputs
ACP Response Block only. Facts labeled. A threat is `known` only with
a traced entry-to-sink path. A mitigation is `known` only with its
enforcing evidence.

## 7. Quality Gates
- Every threat cites a traced path from entry to sink.
- Every mitigation cites its enforcing artifact.
- Every non-applicable category is recorded with its reason.

## 8. Failure Modes
- A complete-looking table with no system-specific findings.
- A mitigation believed present and never enforced anywhere.
- An unauthenticated endpoint missed while exotic threats were listed.
- Findings that cannot be fixed because no path was traced.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | category table with no traced paths | compliance prose |
| 2 | mitigation claimed without an artifact | intent, not enforcement |
| 3 | trust boundary with no named validator | unguarded crossing |
| 4 | category omitted silently | oversight or decision, unknown |
| 5 | threat with no entry-to-sink path | unfixable and undisprovable |
| 6 | severity taken from the category | this instance unassessed |
| 7 | undocumented entry point in the system | unmapped flow |

## 9. Worked Example
Claim: "injection is mitigated, we validate input." Evidence: the
validator exists on one controller; the batch importer writes the same
store directly. Path fires: a trust boundary with no named validator.
Verdict: weakened (Known: controller validator; Assumed: coverage of
all writers). Fix: enforce at the store boundary, then trace both
paths to the same sink.
