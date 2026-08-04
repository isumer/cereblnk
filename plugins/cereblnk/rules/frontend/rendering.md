---
name: frontend-rendering
genre: constraint
category: frontend
density: neutral
paths:
  - "**/components/**/*"
  - "**/*.tsx"
  - "**/*.jsx"
---

# Rendering and Performance

Extends [`common/performance.md`](../common/performance.md).

## Lists

- A key identifies the item, and survives reorder and filter
- A list that can grow without bound is virtualised or paginated

Avoid: an index used as a key. A key built from a changing value. Ten
thousand rows rendered because the test data had twenty.

## Work per frame

- Expensive work happens off the render path
- Layout-affecting reads and writes are not interleaved

Avoid: a computation repeated on every render. A measurement taken
inside a render. An animation driven by a property that triggers
layout.

## Loading

- The critical path loads first; the rest is deferred deliberately
- A deferred boundary shows a designed placeholder, not a jump

```text
first      what the user came for
deferred   below the fold, secondary panels, heavy widgets
measured   at the percentile that matters, on real conditions
```

Avoid: a bundle grown without a measurement. A placeholder that shifts
the layout when it resolves. Lazy loading applied to the first thing
the user sees.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a collection is rendered | Lists |
| work happens during render | Work per frame |
| a module or route is loaded | Loading |
