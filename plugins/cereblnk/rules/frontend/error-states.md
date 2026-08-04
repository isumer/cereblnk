---
name: frontend-error-states
genre: constraint
category: frontend
density: neutral
paths:
  - "**/components/**/*"
  - "**/pages/**/*"
  - "**/screens/**/*"
---

# Frontend Error States

Extends [`../common/error-handling.md`](../common/error-handling.md).

## Every surface has four states

- Empty, loading, error and content are designed, not improvised
- A state that cannot occur is stated as impossible, with the reason

```text
    loading   what the user sees while waiting
    empty     nothing yet, and how to get something
    error     what failed, and what to do next
    content   the working case
```

Avoid: a spinner standing in for both loading and empty. An error
rendered as a blank region.

## What an error says

- The message names what failed in the user's terms
- A retry is offered where retrying can help

Avoid: a status code shown to the user. A generic apology that leaves
the next step unknown.

## Containment

- A failing region fails alone; the page around it keeps working
- Boundaries sit where a partial view is still useful

Avoid: one failed widget replacing the whole screen. A boundary so wide
that any error blanks the application.

## Reporting

- A caught error is reported with the context needed to find it
- Personal data is excluded from what is reported

Avoid: an error swallowed to keep the console clean. A report carrying
the form values that triggered it.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new view or screen | Every surface has four states |
| an error message | What an error says |
| an error boundary or try/catch | Containment |
| a logging or monitoring call | Reporting |
