---
name: yaml-coding-style
genre: constraint
category: languages
paths:
  - "**/*.yml"
  - "**/*.yaml"
---

# YAML Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md).
Judgment lives in `skills/languages/yaml/`.

## Quoting

- Anything a parser could retype is quoted: versions, country codes,
  times, leading-zero numbers, `yes`, `no`, `on`, `off`
- One quoting style per repository

```yaml
version: "3.11"
region: "no"
enabled: true
port: 8080
started_at: "09:30"
```

Avoid: an unquoted token that is not the type it reads as. Two quoting
styles in one file. A number quoted where arithmetic is expected.

## Structure

- Two spaces per level, never tabs
- One document per concern; multi-document files state why
- Keys ordered by meaning, not alphabetically by accident

```yaml
metadata:
  name: settlement-api
  labels:
    app: settlement
spec:
  replicas: 3
```

Avoid: a tab anywhere. A block indented one level from where it
belongs, which still parses. A file mixing unrelated concerns.

## Comments and length

- A comment states why a value is what it is
- A long scalar uses a block form rather than a wrapped line

```yaml
# the gateway rejects bursts above this, measured 2026-07
rate_limit_per_minute: 600

startup_probe_command: |
  curl --fail --silent http://localhost:8080/health
```

Avoid: a comment restating the key. A folded block where newlines
matter. A value line long enough to wrap in review.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a scalar value | Quoting |
| indentation or a new document | Structure |
| a comment or a long value | Comments and length |
