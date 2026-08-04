---
name: frontend-accessibility
genre: constraint
category: frontend
density: neutral
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.html"
  - "**/*.component.html"
---

# Accessibility

Judgment lives in `skills/practices/accessibility/`.

## Semantics first

- The semantic element is used before any attribute is added
- A custom control restores focus, keyboard activation and role — all three

```text
button     focusable, activated by keyboard, announced
link       navigates, opens in place, announced as a link
heading    conveys structure a screen reader navigates by
```

Avoid: a generic element acting as a control. An attribute added over
an element that already had the semantics. A control reachable by
mouse only.

## Focus

- Focus moves deliberately on open, and returns on close
- The focus indicator is visible, or a designed replacement is

Avoid: focus stranded at the page top after a dialog closes. A focus
outline removed with nothing in its place. A trap the keyboard cannot
escape.

## Announcements

- A state change that matters is announced, not only rendered
- Errors, results and loading are all state changes

Avoid: an error shown silently. A result updated with no announcement.
A live region so chatty it is ignored.

## Perception

- Meaning carried by colour has a second channel: text, shape, position
- Contrast is measured, never judged

Avoid: a status conveyed only by red and green. Contrast approved on
one bright monitor. Text over an image with no tested fallback.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a control is built | Semantics first |
| a dialog, route or overlay changes | Focus |
| content changes without navigation | Announcements |
| colour or contrast conveys meaning | Perception |
