---
name: security-threat-surface
genre: constraint
category: security
density: neutral
applies_when: an entry point, trust boundary, or risk is assessed
---

# Threat Surface

Judgment lives in `skills/practices/owasp-threat-modeling/`.

## Entry points

- Every entry point is enumerated, including the undocumented ones
- A surface with no owner is the finding, before any category is opened

```text
enumerated   endpoints, webhooks, uploads, queues, batch jobs
enumerated   debug routes, admin paths, internal interfaces
owned        each one, by a named component
```

Avoid: a debug endpoint reachable in production. An internal interface
that is not. A surface discovered during an incident.

## Trust boundaries

- Every crossing names what validates it
- Data from another service is external until proven otherwise

Avoid: a boundary crossed with no named validator. Trust granted by
network position. A service trusted because it is internal.

## Findings

- A finding cites a traced path from entry to sink
- A mitigation cites the artefact that enforces it

Avoid: a finding with no traced path, which can be neither fixed nor
disproved. A mitigation claimed from intent. A category marked not
applicable with no reason.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an entry point is added | Entry points |
| data crosses a boundary | Trust boundaries |
| a risk is reported | Findings |
