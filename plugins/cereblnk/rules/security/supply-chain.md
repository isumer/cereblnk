---
name: security-supply-chain
genre: constraint
category: security
density: neutral
paths:
  - "**/package.json"
  - "**/pom.xml"
  - "**/go.mod"
  - "**/requirements*.txt"
  - "**/Dockerfile*"
  - "**/.github/workflows/*"
---

# Supply Chain

Extends [`common/dependency-management.md`](../common/dependency-management.md).

## What enters

- Every dependency, base image and action is pinned to a digest
- The transitive tree is the surface, and it is audited on change

Avoid: a range in a shipped build. A tag that can move after review. A
direct dependency reviewed while its tree is not.

## What is built

- The artefact deployed is the artefact reviewed, compared by digest
- Provenance links artefact to commit and to the build that made it

```text
identity      a content digest, never a name
provenance    commit, build, and inputs, recorded at build time
verified      the deployed digest equals the reviewed digest
```

Avoid: deployment by a movable name. A version number treated as an
identity. An incident where nobody can say what is running.

## The pipeline as a target

- Build credentials reach production, so the pipeline is production
- Untrusted contributions never run with repository privileges

Avoid: a workflow granting write access to unreviewed code. A build
secret readable from a fork. An unpinned third-party step in a
privileged job.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a dependency or image is referenced | What enters |
| an artefact is published or deployed | What is built |
| a pipeline definition changes | The pipeline as a target |
