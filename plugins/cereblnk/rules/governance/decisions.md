---
name: governance-decisions
genre: constraint
category: governance
density: neutral
applies_when: a lasting choice is made or superseded
---

# Decisions

Extends [`common/documentation.md`](../common/documentation.md).

## What is recorded

- A decision with lasting consequence is written where it binds
- The record names the context, the options, the choice, and its cost

```text
context      the pressure that forced a choice
options      what was considered, and why each was set aside
decision     what was chosen, and what it rules out
reversal     the evidence that would change this
```

Avoid: a decision living only in a review thread. A record listing the
choice with no alternatives. A rationale that exists only in one
person's memory.

## Deviations

- A deviation from a stated standard is recorded, not silently taken
- The record states whether it is temporary, and what ends it

Avoid: one module following a different pattern with no note. An
exception granted verbally. A standard nobody can tell is still in
force.

## Currency

- A decision that no longer holds is superseded, not deleted
- The superseding record names what changed

Avoid: a document describing an architecture that was replaced. Two
records disagreeing with no order between them.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a lasting choice is made | What is recorded |
| a standard is not followed | Deviations |
| a prior decision changes | Currency |
