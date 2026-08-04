---
name: architecture-boundaries
genre: constraint
category: architecture
density: neutral
applies_when: a system is split, or a contract between parts is defined
---

# Boundaries

Extends [`common/patterns.md`](../common/patterns.md).

## Where one is drawn

- A boundary separates things that change for different reasons
- Components that always change together belong on one side

Avoid: a boundary along a technical layer where the change crosses it.
A split justified by a diagram rather than by change history. A
boundary added before any pain existed.

## What crosses it

- A boundary exposes a contract, never an internal type
- Data crossing it is validated once, on entry

```text
exposed      a contract type, versioned and documented
kept inside  entities, storage rows, framework types
crossing in  parsed, validated, converted to the contract
```

Avoid: a storage row returned from an interface. A framework
annotation on a type that crosses. Re-validation on the inner side.

## Data ownership

- One component owns a piece of data and its invariants
- Others read through the owner, never around it

Avoid: two components writing one table. A shared schema between
services. A read path that bypasses the owner for speed.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a module or service is split | Where one is drawn |
| a type is exposed across a boundary | What crosses it |
| data is read or written | Data ownership |
