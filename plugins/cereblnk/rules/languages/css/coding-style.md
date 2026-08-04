---
name: css-coding-style
genre: constraint
category: languages
paths:
  - "**/*.css"
  - "**/*.less"
---

# CSS Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md).
Judgment lives in `skills/languages/css/`.

## Selectors

- The lowest specificity that works; a class over an element or an id
- Nesting stops at three levels, or the selector is flattened

```css
.order-row { }
.order-row__total { }
.order-row--overdue { }
```

Avoid: an id used for styling. A selector chain mirroring the markup
tree. An importance flag added to win an argument.

## Values

- A colour, spacing, radius or duration comes from a token
- A literal value states why no token fits

```css
:root {
  --spacing-2: 0.5rem;
  --colour-danger: #b3261e;
}

.order-row--overdue {
  padding: var(--spacing-2);
  color: var(--colour-danger);
}
```

Avoid: a hex value repeated at three call sites. A spacing number that
happens to line up. A duration chosen without reference to the motion
scale.

## Units

- Type and spacing scale with the user's root size
- Fixed pixel values are reserved for what must not scale

```css
.panel {
  padding: 1rem;
  font-size: 1rem;
  border-width: 1px;
}
```

Avoid: a font size in pixels, ignoring the user's setting. A fixed
height on text content. A viewport unit used where a container query
belongs.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a selector is written | Selectors |
| a colour, spacing, or duration | Values |
| a size or length | Units |
