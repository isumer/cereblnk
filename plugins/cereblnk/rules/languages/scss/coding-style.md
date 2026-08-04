---
name: scss-coding-style
genre: constraint
category: languages
paths:
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.module.scss"
---

# SCSS Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md).
Cascade constraints live in [`languages/css/`](../css/coding-style.md).
Judgment lives in `skills/languages/scss/`.

## Loading

- Files are loaded with `@use` and re-exported with `@forward`
- Every member is reached through its module namespace

```scss
@use "sass:map";
@use "tokens" as t;

.order-row {
  padding: t.$spacing-2;
  color: map.get(t.$palette, "danger");
}
```

Avoid: the `@import` rule, removed in the next major release. A global
built-in function call. A member used without its namespace.

## Runtime values

- A value the interface switches is a custom property
- A Sass variable carries only what the build decides

```scss
:root {
  --colour-surface: #{t.$surface-light};
}

[data-theme="dark"] {
  --colour-surface: #{t.$surface-dark};
}

.panel {
  background: var(--colour-surface);
}
```

Avoid: a Sass variable behind a theme toggle. A switched value read
straight from a build-time variable.

## Nesting

- Nesting stops at three levels
- Deeper structure is written as a flat selector

```scss
.order-row {
  &__total {
    font-variant-numeric: tabular-nums;
  }

  &--overdue {
    color: var(--colour-danger);
  }
}
```

Avoid: nesting that mirrors the markup tree. A generated selector no
one would write by hand.

## Sharing declarations

- Shared declarations come from a mixin
- A placeholder is extended only inside the file defining it

```scss
@mixin focus-ring {
  outline: 2px solid var(--colour-focus);
  outline-offset: 2px;
}

.order-row__action:focus-visible {
  @include focus-ring;
}
```

Avoid: `@extend` reaching across files. A placeholder extended from a
module that did not define it.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a file is loaded or re-exported | Loading |
| a themed or switched value | Runtime values |
| a selector is nested | Nesting |
| declarations repeat across rules | Sharing declarations |
