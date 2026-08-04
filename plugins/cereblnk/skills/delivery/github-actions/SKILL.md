---
name: github-actions
description: How to reason about GitHub Actions — trigger trust levels, token permissions, untrusted input reaching a shell, and unpinned third-party actions. Use for workflow work.
---

# GitHub Actions Skill

## 1. Identity
name: github-actions · domain: delivery
complements: git-strategy · devsecops · artifact-management
escalate_to: security-agent (token and secret exposure) · release-engineering (deploy gating)

## 2. Mission
The trigger decides the trust level. Everything else follows from
which event started the run.

## 3. Philosophy

**Reading requests.** "Add a workflow for this" hides two questions.
Which trigger, and therefore which trust level? What may the token do
here, and why? "The workflow is slow" decomposes into queue, setup,
cache, and the job itself, timed per step from real runs.

**Where risk lives.** Triggers that run with repository privileges on
untrusted contributions. Event data interpolated into a shell.
Third-party actions pinned to a moving tag. Token permissions left at
the default and never narrowed. Secrets reachable from fork-triggered
contexts.

**Verification here.** Read the run, not the file. Job logs, the
permissions the run reports, and the cache lines. An injection claim
is verified by tracing each untrusted input to its sink. A supply
chain claim is verified by resolving what commit a tag points to now.

**False-competence traps.** Five marketplace actions where two
commands would do, each unpinned and unread. Permissions left
unstated while broad access rides along. Event fields interpolated
into shell as if they were data. Reusable workflow towers built for
one repository.

**Instincts.** Pin actions by commit. State permissions explicitly and
minimally in every workflow. Pass untrusted input through the
environment, never into the command text. Prefer a command to an
action when the command is short.

## 4. Decision Strategy — the paths

**A workflow is triggered by outside contributions**
→ Establish what privileges the run holds. A trigger that grants
  repository access to unreviewed code is the whole finding.

**Event data reaches a run step**
→ Pass it through an environment variable. Interpolating it into the
  command text lets a branch name become a command.

**A third-party action is used**
→ Pin it to a commit. A tag can be moved by its owner after review,
  and nothing in the run reports the change.

**Permissions are unstated**
→ State them. The default is broader than most workflows need, and
  unstated breadth is discovered only when it is abused.

**A secret is referenced**
→ Confirm the trigger cannot expose it to untrusted code. Secrets
  reachable from forks are secrets published.

**The workflow is slow**
→ Time each step from a real run. Queue time and setup time have
  different fixes and are often mistaken for each other.

**A matrix is defined**
→ Read the actual fan-out from a run. Intended combinations and
  produced combinations diverge quietly.

## 5. Inputs
Workflow files and the run logs. Reported token permissions. Action
references and their resolved commits. Trigger configuration. Cache
hit lines for performance claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Permission and injection
claims are `known` only against run output and traced sinks. Timing
claims cite the run.

## 7. Quality Gates
- Every workflow states its token permissions explicitly.
- Every third-party action is pinned to a commit.
- Every untrusted input reaches steps through the environment.

## 8. Failure Modes
- A branch name executing as a command in a privileged run.
- A moved tag shipping unreviewed code into every build.
- A secret readable from a fork-triggered run.
- Broad default permissions unnoticed until misused.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | privileged trigger on outside contributions | untrusted code, repo rights |
| 2 | event field interpolated into a command | shell injection |
| 3 | action referenced by tag | supply chain drift |
| 4 | workflow with no permissions block | broad default access |
| 5 | secret reachable in a fork context | published credential |
| 6 | performance claim with no per-step timing | wrong fix likely |
| 7 | matrix intent never checked against a run | silent fan-out drift |

## 9. Worked Example
Claim: "the workflow is safe, it only echoes the title." Evidence: the
pull request title is interpolated directly into a run step. Path
fires: event data reaching the command text. Verdict: refuted (Known:
workflow line). A title containing shell syntax executes with the
run's privileges. Fix: pass it through the environment and quote it.
A test title containing a command substitution must produce no effect.
