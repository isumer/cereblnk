---
name: backend-validation
genre: constraint
category: backend
density: neutral
paths:
  - "**/*Request.*"
  - "**/dto/**/*"
  - "**/validation/**/*"
---

# Validation

Extends [`common/security.md`](../common/security.md).

## Where

- Validation happens once, at the boundary, producing a checked type
- Inside the boundary the type is trusted; a failure there is a bug

Avoid: defensive re-validation in inner layers. Raw input travelling
past the edge. Two validators disagreeing about the same field.

## What

- Presence, type, range, format and cross-field rules, in that order
- A rule the database can also hold is held in both places

```text
presence     required fields, before anything else
type         parsed, not cast
range        bounds that reflect the domain, not the storage type
format       validated against a stated pattern
relations    cross-field rules the domain requires
```

Avoid: a range taken from the column width. A format rule that rejects
valid data from another locale. A cross-field rule enforced only in a
form.

## Reporting

- Every violated rule is reported, not just the first
- A message names the field and what would satisfy it

Avoid: a caller fixing one error per round trip. A message exposing an
internal field name. A validation failure returned as a server error.

## Trigger table

| Seen in the diff | Section |
|---|---|
| external input is accepted | Where |
| a rule is written | What |
| a failure reaches a caller | Reporting |
