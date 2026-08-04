---
name: docker
description: How to reason about images and containers — what the layers actually contain, signal handling at process one, and reproducibility by digest. Use for Dockerfile and runtime work.
---

# Docker Skill

## 1. Identity
name: docker · domain: infrastructure
complements: kubernetes · linux-ops · artifact-management
escalate_to: security-agent (image and secret exposure) · infra-agent (runtime topology)

## 2. Mission
Inspect the artifact, not the file that built it. A deleted secret is
still in the layer that added it.

## 3. Philosophy

**Reading requests.** "Containerize this" hides the operational
questions. What is configuration and what is code? Where does state
live? Which signal stops it cleanly? What must the image never
contain? "The build is slow" is a layer-ordering question before it is
a hardware one.

**Where risk lives.** Secrets baked into layers, where deletion does
not remove them. Wide or moving tags making deploys unrepeatable.
Signal handling at process one, where a container ignores termination
and is killed mid-write. Processes running as root, widening every
escape.

**Verification here.** Inspect the built image, not the intent. Read
the layer history for contents. Run the container and send the real
signals. Compare digests across builds for a reproducibility claim.
"The ignore file handles it" is verified by listing the build context.

**False-competence traps.** Multi-stage ceremony with build-time
secrets still present in the final stage. A small base image chosen as
virtue while the runtime behaves differently. A health check that
proves the process answers, not that it works. A local compose run
offered as a deployment claim.

**Instincts.** Pin base images by digest. Keep secrets out of the
build, not merely deleted afterwards. Handle termination explicitly.
Run as a non-root user. Order layers so the volatile ones come last.

## 4. Decision Strategy — the paths

**A secret is needed during the build**
→ Keep it out of the layers entirely. Deleting it in a later step
  leaves it readable in the earlier one.

**A base image is referenced**
→ Pin it by digest. A tag moves upstream, and the build that passed
  review is not the build that ships.

**The container must stop cleanly**
→ Confirm the main process receives and handles termination. A
  process that ignores it is killed abruptly, mid-write.

**A health check is defined**
→ Ask what it proves. Answering on a root path proves the socket is
  open, not that the application works.

**The image runs as root**
→ Ask why. Root inside the container widens the consequence of every
  escape and is rarely required.

**The build is slow**
→ Read the layer order. Frequently changing content placed early
  invalidates the cache for everything after it.

**Reproducibility is claimed**
→ Rebuild and compare digests. Identical inputs producing different
  images is a finding, not a curiosity.

## 5. Inputs
Dockerfile and the built image's layer history. Build context listing.
Runtime signal behavior. Base image references and digests. Registry
metadata for reproducibility claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Image content claims are
`known` only against layer inspection. Reproducibility claims cite
compared digests.

## 7. Quality Gates
- No secret appears in any layer of the final image.
- Every base image is pinned by digest.
- Every container handles termination explicitly.

## 8. Failure Modes
- A credential readable in a layer it was deleted from later.
- A container killed mid-write because it ignored termination.
- A moving base tag changing behavior between identical builds.
- A health check green while the application is deadlocked.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | secret added then deleted in a later layer | still readable |
| 2 | base image referenced by tag | unrepeatable build |
| 3 | main process ignoring termination | abrupt kill mid-write |
| 4 | health check on a trivial path | liveness unproven |
| 5 | process running as root with no reason | widened escape |
| 6 | volatile content in an early layer | cache invalidated |
| 7 | reproducibility claimed with no digest comparison | assumed |

## 9. Worked Example
Claim: "the token is not in the image, we delete it." Evidence: one
layer adds the file and a later layer removes it. Path fires: a secret
added then deleted. Verdict: refuted (Known: layer history). The
earlier layer remains in the image and in the registry. Fix: pass it
as a build secret, then rebuild and inspect the history to confirm.
