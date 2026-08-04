---
name: security-secrets
genre: constraint
category: security
density: neutral
paths:
  - "**/*.env*"
  - "**/config/**/*"
  - "**/*Secret*.*"
---

# Secrets

Extends [`common/security.md`](../common/security.md).

## Where they live

- Secrets arrive at runtime from a secret store or the environment
- Presence is checked at startup, so a missing secret fails immediately

Avoid: a credential in source, a fixture, a build layer, or an image. A
secret in a configuration file committed for convenience. A key
distributed by message.

## Rotation

- Every secret has a rotation period and a rotation that has been run
- A possibly-exposed secret is rotated, not assessed

```text
scheduled    rotation, tested at least once
supported    two valid credentials during a rotation window
recorded     where each secret is used, so rotation is complete
```

Avoid: a secret nobody can rotate without downtime. A rotation
procedure never executed. An exposure debated instead of rotated.

## Detection

- A scan runs before a commit leaves the machine, and in the pipeline
- A detection is proven by planting a test credential

Avoid: a scanner configured and never triggered. A finding suppressed
without rotating. History rewritten as the only response.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a credential is referenced | Where they live |
| a secret is created | Rotation |
| scanning is configured | Detection |
