---
name: jenkins-pipelines
description: How to reason about Jenkins pipelines — agent and workspace state, credential hygiene, pipes eating exit codes, retries hiding flake. Use for Jenkinsfile work.
---

# Jenkins Pipelines Skill

## 1. Identity
name: jenkins-pipelines · domain: delivery
complements: git-strategy · artifact-management · devsecops
escalate_to: security-agent (credential exposure) · infra-agent (agent topology)

## 2. Mission
Replay the run, not the file. The Jenkinsfile describes intent; the
console log and the workspace describe what happened.

## 3. Philosophy

**Reading requests.** "The build is red" decomposes by layer first.
Agent environment. Workspace state. Dependency fetch. The test itself.
Pipeline logic. Each layer leaves different evidence. "Add a stage"
hides three questions: which agent, which credentials, and is it safe
to run concurrently with itself?

**Where risk lives.** Credentials echoed into logs or archived with
artifacts. Pipeline code that reads fine and serializes badly. Shared
agents carrying a dirty workspace between runs. Shell steps that
continue after a failure because a pipe consumed the exit code.

**Verification here.** Replay the actual run with its agent and
workspace. A hermetic claim is verified by two consecutive runs, one
clean and one dirty, producing identical results. Credential hygiene
is verified by searching the logs and artifacts a run actually
produced.

**False-competence traps.** Shared-library ceremony wrapping a
two-line shell step. Piped commands reporting success while the first
one failed. Stages retried until green. "It passed on my agent," with
toolchain drift never read.

**Instincts.** Declarative until genuinely impossible. Every shell
step fails loudly. Treat workspaces as dirty by default. Scope
credentials to the stage that needs them.

## 4. Decision Strategy — the paths

**A build fails intermittently**
→ Name the layer before touching anything. Agent, workspace,
  dependency, test, or pipeline logic leave different evidence.

**A shell step pipes commands**
→ Make the pipeline fail on the first failure. Otherwise the last
  command's success reports the whole step as green.

**A stage is retried automatically**
→ Ask what the retry hides. A retry converts a flake into
  configuration and removes the pressure to fix it.

**A credential is used**
→ Scope it to the stage and confirm it never reaches a log or an
  archived file. Search a real run's output to prove it.

**The workspace is assumed clean**
→ Prove it. Shared agents carry state, and the build that passes only
  on a dirty workspace passes for the wrong reason.

**Pipeline logic grows**
→ Prefer declarative structure. Procedural pipeline code fails in
  ways that read correctly and serialize incorrectly.

**A build passes on one agent**
→ Compare toolchains across agents. Drift presents as a flaky test
  and resists every test-level fix.

## 5. Inputs
Jenkinsfile and the console log of the run in question. Agent and
workspace identity. Archived artifacts for credential checks. Toolchain
versions per agent. Retry and timeout configuration.

## 6. Outputs
ACP Response Block only. Facts labeled. Build behavior claims are
`known` only against a replayed run. Hermeticity claims cite the clean
and dirty comparison.

## 7. Quality Gates
- Every shell step fails on the first failing command.
- Every credential is scoped and proven absent from logs.
- Every retry states what it is hiding, or is removed.

## 8. Failure Modes
- A green stage whose real work failed inside a pipe.
- A credential archived alongside build output.
- A build passing only because the workspace was dirty.
- Flake preserved as retry configuration for a year.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | piped shell step with no failure propagation | success theater |
| 2 | stage with automatic retry | flake institutionalized |
| 3 | credential used outside a scoped block | log and artifact exposure |
| 4 | clean workspace assumed on a shared agent | wrong-reason pass |
| 5 | procedural pipeline code where declarative fits | serialization surprise |
| 6 | failure diagnosed with no layer named | wrong fix likely |
| 7 | agent-specific pass with no toolchain comparison | drift unread |

## 9. Worked Example
Claim: "the build is green, the tests pass." Evidence: the stage runs
two piped commands and the pipeline does not propagate failure. Path
fires: a piped step with no failure propagation. Verdict: refuted
(Known: stage definition and console log). The first command failed
and the second succeeded. Fix: enable failure propagation, then re-run
and read the real result.
