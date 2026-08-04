---
name: frontend-internationalisation
genre: constraint
category: frontend
density: neutral
paths:
  - "**/locales/**/*"
  - "**/i18n/**/*"
  - "**/components/**/*"
---

# Internationalisation

Extends [`component-design.md`](component-design.md) and
[`accessibility.md`](accessibility.md).

## Text

- User-visible text comes from a message catalogue, with a stable key
- A key names the meaning, not the English wording

Avoid: a sentence assembled from concatenated fragments. A key renamed
whenever the copy changes.

## Plurals and interpolation

- Plural forms come from the locale's rules, not from a count check
- Interpolated values are named, so translators can reorder them

```text
    key         order.items_selected
    values      named, never positional
    plural      resolved by locale rules, all categories present
```

Avoid: an `if (count === 1)` branch around two strings. A message whose
word order is fixed by concatenation.

## Formatting

- Dates, numbers and currency are formatted by locale, at render time
- The time zone used for a displayed date is explicit

Avoid: a date formatted with a hardcoded pattern. A currency symbol
prefixed by string concatenation.

## Layout

- Layout tolerates text expansion and right-to-left direction
- Directional spacing uses logical properties

Avoid: a fixed-width control sized to the English label. A layout that
mirrors incorrectly because it uses left and right.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a user-visible string | Text |
| a count, quantity, or template value | Plurals and interpolation |
| a date, number, or money value | Formatting |
| spacing, alignment, or a fixed width | Layout |
