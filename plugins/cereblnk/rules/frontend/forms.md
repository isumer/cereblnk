---
name: frontend-forms
genre: constraint
category: frontend
density: neutral
paths:
  - "**/*Form*.*"
  - "**/forms/**/*"
---

# Forms

Extends [`frontend/accessibility.md`](./accessibility.md) and
[`backend/validation.md`](../backend/validation.md).

## Structure

- Every control has a label, associated programmatically
- Related controls are grouped, and the group is named

Avoid: a placeholder used as a label. A field labelled only by
position. A group of options with no accessible name.

## Validation

- The client validates for speed; the server validates for truth
- A message names the field and what would satisfy it

```text
client    immediate feedback, after the field is left
server    the decision, always, regardless of the client
message   what is wrong, and what would be right
```

Avoid: client validation trusted as the rule. A message that only says
invalid. Every error reported one round trip at a time.

## Submission

- A submission is disabled while in flight, and its result is announced
- A repeated submission does not create a second effect

Avoid: a double submission creating two orders. A success shown before
the server confirmed. A failure that loses what the user typed.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a field or group is added | Structure |
| a rule is checked | Validation |
| a form is submitted | Submission |
