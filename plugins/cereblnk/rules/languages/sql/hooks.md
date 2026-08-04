---
name: sql-hooks
genre: constraint
category: languages
paths:
  - "**/*.sql"
  - "**/db/migration/**"
  - "**/changelog*.xml"
---

# SQL Hooks

Extends [`common/hooks.md`](../../common/hooks.md), which sets scope
and blocking policy.

## On edit

```text
format      the edited file
lint        the edited file, dialect-aware
parse       against the target engine's grammar
expect      exit code, and file:line diagnostics only
```

Avoid: a lint configured for a different dialect · formatting settled
by hand.

## On migration edit

```text
apply       forward, against a disposable database
apply       the rollback, against the same database
compare     the resulting schema with the expected one
never       against a shared or production database
```

Avoid: a migration applied only forward · a rollback exercised for the
first time during an incident.

## On query change

```text
capture   the plan on production-shaped data
compare   estimated against actual rows
flag      a sequential scan on a large table
```

Avoid: a performance claim with no captured plan · a plan read on
development volume.

## Output

```text
returned   exit code, first diagnostic per file
returned   plan summary: rows, cost, scan types
never      the full plan or the raw log into an agent's context
```

Avoid: an execution plan pasted whole into a response.

## Trigger table

| Situation | Section |
|---|---|
| a statement file was edited | On edit |
| a migration was edited | On migration edit |
| a query changed | On query change |
| output must reach an agent | Output |
