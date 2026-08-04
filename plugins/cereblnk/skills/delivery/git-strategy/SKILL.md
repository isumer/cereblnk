---
name: git-strategy
description: How to reason about branching and history — the variables that decide a strategy, rewrites on shared branches, merges that drop a side. Use for workflow and history work.
---

# Git Strategy Skill

## 1. Identity
name: git-strategy · domain: delivery
complements: release-engineering · github-actions · bitbucket-pipelines
escalate_to: release-engineering (release and hotfix paths)

## 2. Mission
Strategy follows the variables, not the fashion. Ask what ships
concurrently before naming any model.

## 3. Philosophy

**Reading requests.** "Set up a branching strategy" hides the real
variables. How many versions ship at once? How urgent are fixes? How
much is CI trusted? How large is the team? Naming a model before those
answers is fashion. "Fix this merge mess" starts by reconstructing
what both sides intended, from commits and reviews.

**Where risk lives.** History rewritten on shared branches. Long-lived
branches accumulating conflict debt. Merges that silently drop one
side while tests stay green. Release and fix paths that bypass the
checks the main branch enforces.

**Verification here.** Interrogate the graph. Use the merge base and
containment checks for any "released in" claim. A "this is in
production" claim is verified against the deployed reference, never a
branch name. A conflict resolution is verified by re-reading both
parents against the result.

**False-competence traps.** Ceremony-heavy models for a team shipping
weekly from one branch. Squashing everything, erasing the trail a
bisect would follow. Rebasing shared branches for cleanliness.
Resolving conflicts by taking one side wholesale.

**Instincts.** Keep branches short-lived. Never rewrite shared
history. Resolve conflicts by reading both intents. Let the deployed
reference, not a name, answer what is running.

## 4. Decision Strategy — the paths

**A strategy is requested**
→ Ask the four variables first: concurrent versions, fix urgency, CI
  trust, team size. The model falls out of the answers.

**History would be rewritten**
→ Confirm nobody else holds the branch. A rewrite under a colleague
  costs more than the tidiness it buys.

**A conflict is resolved**
→ Read both parents against the result. Taking one side wholesale
  reverts the other side's fix silently, and tests rarely notice.

**A branch has lived a long time**
→ Treat the conflict debt as the finding. Every day adds resolution
  risk that no review can fully check.

**Someone claims a change is in production**
→ Check the deployed reference. Branch names describe intent, and
  intent is not deployment.

**A fix path bypasses the main branch**
→ Ask which checks it skips. Urgency is exactly when the skipped
  check would have mattered.

**Commits are squashed**
→ Ask whether the change is one idea. Squashing a complex change
  removes the bisect trail that finds its regression later.

## 5. Inputs
The commit graph and merge bases. Deployed references for production
claims. Branch ages and divergence. Review history for intent
reconstruction. Protection rules on the main branch.

## 6. Outputs
ACP Response Block only. Facts labeled. Containment claims are `known`
only against graph queries. Deployment claims cite the deployed
reference.

## 7. Quality Gates
- Every conflict resolution is checked against both parents.
- Every production claim cites a deployed reference.
- No shared branch has its history rewritten.

## 8. Failure Modes
- A colleague's work lost to a force push.
- A fix reverted by a conflict resolution nobody re-read.
- A regression that cannot be bisected after a wholesale squash.
- A hotfix shipping around the checks it most needed.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | force push to a shared branch | others' work at risk |
| 2 | conflict resolved by taking one side wholly | silent revert |
| 3 | branch alive far longer than its peers | conflict debt |
| 4 | production claim from a branch name | intent, not reality |
| 5 | fix path skipping main branch checks | urgency removes the net |
| 6 | complex change squashed to one commit | bisect trail erased |
| 7 | strategy chosen before the four variables | fashion |

## 9. Worked Example
Claim: "the fix is in production, it is on the release branch."
Evidence: the deployed reference points at a commit that predates the
fix. Path fires: a production claim taken from a branch name. Verdict:
refuted (Known: deployed reference and containment check). Fix: verify
against the deployed reference, then deploy or cherry-pick
deliberately.
