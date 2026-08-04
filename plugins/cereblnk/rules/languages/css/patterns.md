---
name: css-patterns
genre: constraint
category: languages
paths:
  - "**/*.css"
  - "**/*.module.css"
---

# CSS Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Containment

- A component's styles reach that component and nothing else
- Global rules live in one named place, and are few

```css
/* scoped to the component that owns it */
.order-row { }

/* global, and stated as such */
:root { }
```

Avoid: a component stylesheet setting an element selector globally. A
utility class defined in three files. A reset applied more than once.

## Layout

- Layout comes from the layout systems, not from offsets
- A container grows with its content; a fixed size states why

```css
.order-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(16rem, 1fr));
  gap: var(--spacing-2);
}
```

Avoid: absolute positioning used for ordinary layout. A negative
margin correcting another rule. A height that assumes the text length.

## States

- Interactive states are defined together: rest, hover, focus, active,
  disabled
- A visible focus indicator exists, or a designed replacement does

```css
.button:focus-visible {
  outline: 2px solid var(--colour-focus);
  outline-offset: 2px;
}
```

Avoid: a hover state with no focus equivalent. An outline removed with
nothing in its place. A disabled state conveyed only by colour.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a stylesheet is added | Containment |
| positioning or sizing changes | Layout |
| an interactive element is styled | States |
