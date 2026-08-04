---
name: infrastructure-containers
genre: constraint
category: infrastructure
density: neutral
paths:
  - "**/Dockerfile*"
  - "**/*.dockerfile"
  - "**/docker-compose*.yml"
---

# Containers

Judgment lives in `skills/infrastructure/docker/`.

## Image contents

- A secret never enters a layer, not even one deleted later
- Base images are pinned by digest, and the build is reproducible

```text
build secret   passed as a build secret, never copied in
base image     pinned by digest, not by a moving tag
final stage    runtime only, no compilers, no build caches
```

Avoid: a credential added and removed in a later layer. A tag that
moved between review and deploy. A build toolchain shipped to
production.

## Runtime

- The process runs as a non-root user
- Termination is handled, so a stop drains rather than kills

Avoid: a container running as root without a reason. A process that
ignores the stop signal and dies mid-write. A health check that only
proves the socket is open.

## Layers

- Volatile content sits last, so the cache survives
- Each layer has a reason; none exists to work around another

Avoid: a dependency install after a source copy. A layer added to
patch the one before it. An image whose size nobody looked at.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a build stage or copy is added | Image contents |
| the entrypoint or user changes | Runtime |
| instruction order changes | Layers |
