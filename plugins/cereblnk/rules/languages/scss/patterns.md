---
name: scss-patterns
genre: constraint
category: languages
paths:
  - "**/*.scss"
  - "**/*.module.scss"
---

# SCSS Patterns

Judgment lives in `skills/languages/scss/`.
Style constraints live in [`coding-style.md`](coding-style.md).

## Module entry point

- A directory exposes one index that forwards its public members
- Consumers load the index, never the partials behind it

```scss
// tokens/_index.scss
@forward "colour";
@forward "spacing";
@forward "type";
```

Avoid: a consumer reaching past the index into a partial. Two entry
points for one directory.

## Configurable modules

- A module declares its overridable members with `!default`
- Configuration happens once, at the first load

```scss
// _tokens.scss
$radius: 4px !default;

// entry.scss
@use "tokens" with ($radius: 8px);
```

Avoid: configuring a module already loaded elsewhere. An overridable
member with no default value.

## Private members

- A member the module does not export is prefixed with a hyphen
- Forwarded surfaces list what leaves the module

```scss
$-grid-base: 4px;

@function step($n) {
  @return $-grid-base * $n;
}
```

Avoid: an internal member reachable by consumers. A forward that
exposes everything a directory happens to contain.

## Component stylesheets

- A component stylesheet loads tokens and owns only its own class
- Layout of children belongs to the children

```scss
@use "tokens" as t;

.order-row {
  display: grid;
  gap: t.$spacing-2;
}
```

Avoid: a component styling a descendant it does not own. Tokens
redeclared per component file.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a directory of partials | Module entry point |
| an overridable value | Configurable modules |
| a helper not meant for consumers | Private members |
| a per-component stylesheet | Component stylesheets |
