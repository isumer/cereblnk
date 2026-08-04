---
name: frontend-component-design
genre: constraint
category: frontend
density: neutral
paths:
  - "**/components/**/*"
  - "**/*.component.*"
  - "**/*.tsx"
  - "**/*.vue"
---

# Component Design

Extends [`common/patterns.md`](../common/patterns.md). Framework rules
refine these.

## One job

- A component renders, or it decides — rarely both
- Shared behavior moves into a shared unit, not a wrapper hierarchy

Avoid: a component fetching, deciding and rendering in one body. A
provider added to pass one value two levels. A component that grows a
second reason to change.

## Inputs and outputs

- Inputs are typed and required unless a default is meaningful
- A component emits domain events, not the events of its widgets

```text
input     the data the component renders, typed
input     the callbacks it invokes, named for the domain
output    settleRequested, not buttonClicked
```

Avoid: a boolean input selecting a different component. An input the
component mutates. A callback named after the DOM event.

## Every state

- Empty, loading, error and filled are all designed and all rendered
- The error state is broken once, to prove it appears

Avoid: only the filled path implemented. An error rendered as an empty
list. A loading flicker nobody chose.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a component is created or grows | One job |
| a prop or event is added | Inputs and outputs |
| a component reads remote data | Every state |
