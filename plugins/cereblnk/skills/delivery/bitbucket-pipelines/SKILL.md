---
name: bitbucket-pipelines
description: How to reason about Bitbucket Pipelines — fresh containers per step, caches that never invalidate themselves, variable scope, and state that only travels as artifacts. Use for pipeline work.
---

# Bitbucket Pipelines Skill

## 1. Identity
name: bitbucket-pipelines · domain: delivery
complements: git-strategy · artifact-management · devsecops
escalate_to: security-agent (variable exposure) · release-engineering (deploy gating)

## 2. Mission
Every step is a fresh container. State travels as declared artifacts
or it does not travel at all.

## 3. Philosophy

**Reading requests.** "Speed up the pipeline" decomposes into image
pull, cache result, dependency install, and the tests, measured per
step. Each has a different fix. "Add a deploy step" hides the
environment model: which environment, which variable scope, gated how?

**Where risk lives.** Assumptions carried from tools where the
workspace persists. Caches populated once and never invalidated on
their own. Secured variables echoed by a traced command. Configuration
anchors diverging quietly between branches.

**Verification here.** Read the run's step logs and timings. A cache
claim is verified by the restore and save lines, not by the config
existing. An artifact claim is verified by the artifact itself.
Validate the configuration before pushing; invalid files fail after
the queue wait, not before it.

**False-competence traps.** Steps that depend on state a previous step
left behind. Dependency caches keyed by nothing, serving yesterday's
tree as speed. One large step written to avoid artifact plumbing.
Secured variables trusted as unloggable while tracing echoes them.

**Instincts.** Declare artifacts for anything the next step needs. Key
caches by the file that defines the dependencies. Keep steps small
enough to attribute failure. Assume nothing survives a step boundary.

## 4. Decision Strategy — the paths

**A step needs output from an earlier step**
→ Declare it as an artifact. Nothing else crosses the boundary, and
  the failure appears as a missing file much later.

**A cache is configured**
→ Key it on the file that determines the contents. An unkeyed cache
  serves a stale tree and reports it as a fast build.

**A variable holds a secret**
→ Confirm no step traces commands. Tracing prints the expanded value
  and the log outlives the run.

**Steps are merged into one**
→ Ask what attribution is lost. A single large step turns any failure
  into a search rather than a signal.

**A deploy targets an environment**
→ State the environment and the variable scope it draws from. Scope
  confusion deploys the right code with the wrong configuration.

**The pipeline is slow**
→ Time each step from a real run. Image pull and dependency install
  look identical in wall clock and have different fixes.

**Configuration is shared across branches**
→ Check where anchors diverge. Shared structure that drifted is worse
  than duplicated structure that did not.

## 5. Inputs
Pipeline configuration and the run's step logs. Cache restore and save
lines. Declared artifacts. Variable scopes per environment. Step
timings for performance claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Cache and artifact claims are
`known` only against run output lines. Timing claims cite the step.

## 7. Quality Gates
- Every cross-step dependency is a declared artifact.
- Every cache is keyed by its defining file.
- Every secured variable is proven absent from step output.

## 8. Failure Modes
- A step failing on state a previous step was assumed to leave.
- A stale cache serving an old dependency tree for weeks.
- A secret printed by a traced command into a retained log.
- Unattributable failure inside one oversized step.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | step reading files it did not receive as artifacts | vanished state |
| 2 | cache with no key derived from a manifest | stale tree served |
| 3 | command tracing enabled where secrets expand | credential in logs |
| 4 | one step covering many concerns | failure unattributable |
| 5 | deploy step with unstated variable scope | right code, wrong config |
| 6 | performance claim with no per-step timing | wrong fix likely |
| 7 | shared anchors differing per branch | silent divergence |

## 9. Worked Example
Claim: "the build got faster, we added a cache." Evidence: the run
shows a cache restore line and no key derived from the dependency
manifest. Path fires: a cache with no defining key. Verdict: weakened
(Known: restore line; Assumed: contents are current). Speed came from
serving an old tree. Fix: key the cache on the manifest, then compare
timings across two runs.
