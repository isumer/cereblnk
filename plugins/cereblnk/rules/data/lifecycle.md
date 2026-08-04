---
name: data-lifecycle
genre: constraint
category: data
density: neutral
paths:
  - "**/entity/**/*"
  - "**/model/**/*"
---

# Data Lifecycle

Extends [`common/security.md`](../common/security.md).

## Classification

- Data is classified before it is stored: public, internal, personal,
  secret
- The classification decides encryption, retention and access

```text
public      no restriction
internal    access-controlled, logged
personal    minimised, retained for a stated period, exportable
secret      never logged, never exported, rotated
```

Avoid: personal data stored because it was available. A field whose
classification nobody decided. Secrets and business data in one store.

## Retention

- Every dataset has a retention period and something that enforces it
- Deletion means deleted, including from backups on their own schedule

Avoid: data kept indefinitely by default. A deletion that leaves rows
in an archive nobody tracks. A retention policy with no job behind it.

## Access

- Reading personal data is recorded: who, what, when, why
- Bulk export requires an approval and leaves a record

Avoid: an unaudited query against a personal-data table. An export run
from a developer machine. A support tool with unrestricted read.

## Migration and residency

- Where data may live is established before it is placed
- Moving data across a boundary is a decision, not a deployment detail

Avoid: a residency constraint discovered after the data landed. A
replica created in a region nobody approved.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a field is added or stored | Classification |
| a dataset is created | Retention |
| data is read in bulk | Access |
| storage location changes | Migration and residency |
