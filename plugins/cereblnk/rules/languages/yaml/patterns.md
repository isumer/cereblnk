---
name: yaml-patterns
genre: constraint
category: languages
paths:
  - "**/*.yml"
  - "**/*.yaml"
  - "**/values*.yaml"
---

# YAML Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Composition

- A base file holds what every environment shares
- An environment file is a diff against the base, and reads as one
- The final composition is rendered and read before it applies

```yaml
# values.yaml — the base
replicas: 2
resources:
  requests:
    memory: 256Mi

# values-production.yaml — only what differs
replicas: 6
```

Avoid: an environment file duplicating the base. A value defined in
three places. A precedence claim made without rendering.

## Anchors

- An anchor is defined next to its first use and named for its meaning
- A shared block that both files need lives in the base, not an anchor
  reaching across concerns

```yaml
defaults: &probe_defaults
  periodSeconds: 10
  failureThreshold: 3

livenessProbe:
  <<: *probe_defaults
  httpGet:
    path: /health
```

Avoid: an anchor resolved far from where it is read. An alias whose
target changed meaning. An anchor used to avoid designing a base.

## Schemas

- A document with a schema is validated in the pipeline
- A field the schema does not know is a finding, not a convenience

Avoid: a schema committed and never run. A typo'd key silently
ignored by the consumer. Validation performed only after deployment.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an environment file changes | Composition |
| an anchor or alias appears | Anchors |
| a new key is introduced | Schemas |
