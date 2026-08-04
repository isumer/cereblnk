---
name: helm
description: How to reason about Helm charts — the gap between template and render, values as public interface, upgrade paths and subchart drift. Use for chart work.
---

# Helm Skill

## 1. Identity
name: helm · domain: infrastructure
requires: kubernetes
complements: docker · terraform
escalate_to: infra-agent (cluster topology) · release-engineering (upgrade sequencing)

## 2. Mission
Render, then diff. The template describes intent; only the rendered
output describes what the cluster will receive.

## 3. Philosophy

**Reading requests.** "Make it configurable" hides an interface
design question. Which values are contract and which are internal?
Every exposed value is surface someone will set to something untested.
"The upgrade failed" starts at the diff between rendered releases, not
at the template.

**Where risk lives.** The gap between what a template produces and
what its author believes. Upgrade paths where immutable fields, hooks,
or ownership changes orphan or recreate resources. Values merging with
surprising precedence. Third-party charts upgraded unread.

**Verification here.** Render with the real values files and diff
against the running release. Linting checks syntax; rendering with
edge values checks behavior. Empty lists and disabled subcharts are
where templates break. An upgrade claim is verified on a cluster,
including its rollback.

**False-competence traps.** Template constructs that render wrongly on
the one values shape nobody tried. Every field exposed for
flexibility, producing a worse-documented copy of the platform API.
Subchart defaults trusted across a version bump. Linting in CI
reported as testing.

**Instincts.** Keep the values surface small and documented. Render
with edge cases before shipping. Diff upgrades against the running
release. Read subchart changelogs before bumping.

## 4. Decision Strategy — the paths

**A value is exposed**
→ Treat it as public interface. Somebody will set it to a shape you
  never rendered, and removing it later is a breaking change.

**A template grows conditional logic**
→ Render it with the edge shapes: empty lists, absent maps, disabled
  subcharts. Those are where the logic fails.

**An upgrade is planned**
→ Diff the rendered output against the running release. The template
  change and the cluster change are different sizes.

**A subchart version is bumped**
→ Read what changed. Defaults move between versions, and the
  discovery otherwise happens in production.

**The chart is called tested**
→ Ask what ran. Linting proves syntax; only a rendered diff and a
  cluster upgrade prove behavior.

**A resource may be recreated on upgrade**
→ Identify immutable fields before applying. Recreation during peak
  traffic is an outage with a version number.

**Values merge from several files**
→ Trace precedence explicitly. Deep merges produce results that
  nobody predicted and everybody defends.

## 5. Inputs
Chart templates and all real values files. Rendered output for the
target environment. The running release for diffing. Subchart versions
and their changes. Cluster upgrade observation.

## 6. Outputs
ACP Response Block only. Facts labeled. Behavior claims are `known`
only against rendered output or an observed upgrade. Lint results
support syntax claims only.

## 7. Quality Gates
- Every upgrade claim cites a rendered diff against the running release.
- Every exposed value is documented as contract or marked internal.
- Every template is rendered with edge-shaped values before shipping.

## 8. Failure Modes
- A template rendering wrongly for one untried values shape.
- An upgrade recreating a resource because of an immutable field.
- A subchart default change arriving silently in production.
- A green lint reported as a tested chart.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/infrastructure/helm/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | upgrade claim with no rendered diff | intent, not effect |
| 2 | values exposed without contract documentation | untested settings |
| 3 | conditional template never rendered with empty input | shape-specific break |
| 4 | subchart bumped without reading changes | silent default drift |
| 5 | lint offered as test evidence | syntax only |
| 6 | immutable field changed in an upgrade | recreation outage |
| 7 | values merged from many files with unstated precedence | unpredictable result |

## 9. Worked Example
Claim: "the upgrade is a small change, one value moved." Evidence: the
rendered diff shows a changed selector on a workload. Path fires: an
upgrade claim with no rendered diff, hiding an immutable field change.
Verdict: refuted (Known: rendered diff). The upgrade recreates the
workload. Fix: sequence it deliberately, or keep the selector stable.
