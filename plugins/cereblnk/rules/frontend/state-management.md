---
name: frontend-state-management
genre: constraint
category: frontend
density: neutral
paths:
  - "**/store/**/*"
  - "**/state/**/*"
  - "**/*.slice.ts"
---

# State Management

Extends [`common/patterns.md`](../common/patterns.md).

## Where it lives

- State lives at the lowest place that needs it
- Server data is owned by a data layer, not copied into local state

```text
local      one component's concern
lifted     the nearest shared ancestor of its readers
global     genuinely application-wide, or persisted
remote     owned by the data layer, never duplicated
```

Avoid: a global store holding what one subtree uses. A fetch result
mirrored into local state. State lifted three levels for one reader.

## Derivation

- A derived value is computed from its sources, never stored beside them
- Two fields that must agree are one field and a computation

Avoid: a total kept in sync by hand. A flag derived from data and also
written. A cache of a computation nobody measured.

## Updates

- An update describes what happened, and produces a new value
- One user action produces one state change

Avoid: three writes to express one event. A mutation on shared state.
An update whose order with another decides correctness.

## Trigger table

| Seen in the diff | Section |
|---|---|
| state is introduced or lifted | Where it lives |
| a value depends on another | Derivation |
| state is written | Updates |
