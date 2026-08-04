---
name: artifact-management
description: How to reason about build artifacts — identity by content rather than name, provenance to a commit, unpinned dependencies, retention that fails in both directions. Use for publishing and dependency work.
---

# Artifact Management Skill

## 1. Identity
name: artifact-management · domain: delivery
complements: release-engineering · devsecops · github-actions
escalate_to: security-agent (supply-chain exposure) · compliance-agent (license obligations)

## 2. Mission
A name is not an identity. Only content decides whether what runs is
what was reviewed.

## 3. Philosophy

**Reading requests.** "Publish the build" hides the identity
questions. What uniquely names these bytes? Can they be reproduced?
How does anyone verify the running artifact is the reviewed one?
"Update the dependency" hides the supply chain question: what exactly
was pulled in, and from where?

**Where risk lives.** Movable names. A tag that moved between test and
deploy means nobody can say what ran. Dependency ranges resolving
differently per build. Missing provenance from artifact back to
commit. Retention failing in both directions: unbounded cost, or the
deleted artifact needed for a rollback.

**Verification here.** Identity is verified by content digest, not by
tag. A "we deployed the tested build" claim is verified by comparing
digests. Reproducibility is verified by rebuilding and comparing.
Provenance is verified by the metadata that links artifact, commit,
and build, checked for the artifact actually running.

**False-competence traps.** Deploying by a movable name. A version
bumped in a manifest while the artifact came from another commit.
Dependency ranges in production builds. Retention decided by neglect.

**Instincts.** Deploy by digest. Pin dependencies exactly for
production builds. Attach provenance at build time. Decide retention
deliberately, in both directions.

## 4. Decision Strategy — the paths

**An artifact is deployed**
→ Reference it by content digest. A name can move after the review
  that approved it, and nothing reports the change.

**A build is claimed identical to the tested one**
→ Compare digests. Equal version numbers are a claim about intent,
  not about bytes.

**A dependency is added or updated**
→ Pin it exactly for production builds. A range ships unreviewed code
  on the day the upstream publishes.

**An artifact reaches a registry**
→ Attach provenance linking it to a commit and a build. Later
  incidents ask what this is, and the answer must not be a guess.

**Retention is configured**
→ Decide both directions. Keeping everything costs money; keeping too
  little removes the rollback target.

**Reproducibility is claimed**
→ Rebuild and compare. A build described as reproducible and never
  rebuilt is Assumed.

**A base image or toolchain is referenced**
→ Pin it too. The dependency you did not declare is the one that
  changes underneath the build.

## 5. Inputs
Artifact digests and registry metadata. Dependency manifests and lock
files. Provenance records linking artifact to commit. Retention
policy. Rebuild output for reproducibility claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Identity claims are `known`
only against digests. Reproducibility claims cite a comparison
rebuild, otherwise they stay `assumed`.

## 7. Quality Gates
- Every deployment references a content digest.
- Every production dependency is pinned exactly.
- Every published artifact carries provenance to a commit.

## 8. Failure Modes
- A moved tag putting untested bytes into production.
- A transitive update shipping unreviewed code silently.
- An incident where nobody can say which commit is running.
- A rollback blocked by an artifact already pruned.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | deployment referencing a movable name | unknown running bytes |
| 2 | production dependency declared as a range | unreviewed updates |
| 3 | artifact published with no provenance | unanswerable in an incident |
| 4 | version equality used as identity | intent, not content |
| 5 | retention unset in either direction | cost or missing rollback |
| 6 | reproducibility claimed with no rebuild | assumed |
| 7 | unpinned base image or toolchain | build changes underneath |

## 9. Worked Example
Claim: "production runs the build we tested, same version." Evidence:
the deployment references a tag; the registry shows the tag now points
at a later digest. Path fires: deployment by a movable name. Verdict:
refuted (Known: tag history and digests). Fix: deploy by digest and
record it in the release notes, so the question has an answer next
time it is asked.
