---
name: backend-configuration
genre: constraint
category: backend
density: neutral
paths:
  - "**/application*.yml"
  - "**/application*.properties"
  - "**/config/**/*"
---

# Configuration

Extends [`../common/dependency-management.md`](../common/dependency-management.md)
and [`../security/secrets.md`](../security/secrets.md).

## What is configurable

- A value differs between environments, or it is a constant in code
- Every configurable value has one owner and one name

Avoid: a setting introduced for a case that never varies. The same
value spelled differently per environment file.

## Validation at startup

- Configuration is bound to a typed object and validated on boot
- A missing or invalid required value stops the application

```text
    required     absent means the process does not start
    defaulted    absent means the stated default, written down
    derived      computed from others, never set directly
```

Avoid: a required value defaulting to something that works locally. A
misconfiguration discovered by the first request that needs it.

## Secrets

- Secrets arrive from the platform's secret store, never from a file in the repository
- A secret is read once and never logged

Avoid: a credential in a properties file, even for a test environment.
Configuration printed at startup for debugging.

## Changing behaviour

- A feature flag states its default, its owner, and its removal condition
- Behaviour that varies by tenant is data, not configuration

Avoid: a flag with no plan to remove it. Tenant-specific values
accumulating in an environment file.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new setting or property | What is configurable |
| a config class or binding | Validation at startup |
| a credential, key, or token | Secrets |
| a feature flag or toggle | Changing behaviour |
