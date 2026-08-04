---
name: data-migrations
genre: constraint
category: data
density: neutral
paths:
  - "**/migration/**/*"
  - "**/changelog*.xml"
  - "**/db/**/*.sql"
---

# Migrations

Judgment lives in `skills/data/liquibase-migrations/`.

## History

- An applied change is never edited; a new change corrects it
- Every change is small enough that a half-application is still valid

Avoid: an applied script edited in place. Checksums cleared to silence
an error. One change carrying four unrelated alterations.

## Reversibility

- Every migration's rollback is executed, not merely written
- A destructive step states plainly whether the data returns

```text
executed    forward, then rollback, on production-shaped data
recorded    the lock taken, and how long it held
gated       a destructive step, behind a verified backup
```

Avoid: a rollback that restores the schema and not the data. A drop
whose rollback re-adds an empty column. A migration proven on an empty
table.

## Live systems

- A change runs while the system serves traffic, or says why it cannot
- Code and schema deploy separately: expand, migrate, contract

Avoid: a rewrite locking a large table at peak. A breaking change
deployed ahead of the code that needs it. A step that assumes both
deploys land together.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a change script is added | History |
| a change alters or removes data | Reversibility |
| a change touches a live table | Live systems |
