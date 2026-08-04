---
name: frontend-performance
genre: constraint
category: frontend
density: neutral
paths:
  - "**/components/**/*"
  - "**/pages/**/*"
  - "**/*.config.*"
---

# Frontend Performance

Extends [`rendering.md`](rendering.md) and [`../common/performance.md`](../common/performance.md).

## What is measured

- A performance claim names the metric and the device class
- Before and after are measured the same way

```text
    load        time to first meaningful render
    interaction latency from input to visible response
    stability   layout shift after first paint
```

Avoid: an optimisation justified by how the change reads. A measurement
taken only on a development machine.

## Bundle boundaries

- Code that a route does not need is not in the route's bundle
- A dependency is chosen with its transitive weight in view

Avoid: a date or icon library imported whole for one function. A split
point added without checking what moved.

## Rendering work

- Work repeated per frame is bounded and measured
- Memoisation is applied where a profile showed the cost

Avoid: memoising every component because it might help. A list that
re-renders wholly when one row changes.

## Assets

- Images declare dimensions and are served at the size they render
- Fonts state their loading behaviour, so text remains readable

```text
    dimensions  set, so layout does not shift on load
    format      modern format with a fallback
    priority    only what is above the fold is eager
```

Avoid: a full-resolution image scaled down by the browser. A font that
hides text until it arrives.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a performance claim or fix | What is measured |
| an import or a build config change | Bundle boundaries |
| a memo, effect, or animation | Rendering work |
| an image, video, or font | Assets |
