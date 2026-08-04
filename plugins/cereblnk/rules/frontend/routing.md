---
name: frontend-routing
genre: constraint
category: frontend
density: neutral
paths:
  - "**/routes/**/*"
  - "**/*.routes.ts"
  - "**/router/**/*"
  - "**/app/**/page.tsx"
---

# Routing

Extends [`common/patterns.md`](../common/patterns.md).

## The URL is state

- Anything a user would bookmark or share lives in the URL
- Filters, pagination and selected tabs are restorable from it

Avoid: a filtered view that cannot be linked. A back button that loses
the user's place. State in memory that the URL contradicts.

## Guards

- A protected route decides before it renders anything
- The client guard is convenience; the server decides

Avoid: a route rendered then hidden. Authorisation enforced only in
the router. A redirect loop between two guards.

## Transitions

- A navigation shows its progress, and preserves scroll intent
- A failed navigation leaves the user somewhere valid

Avoid: a blank screen during a route change. A scroll position lost on
back. An error route that cannot be left.

## Trigger table

| Seen in the diff | Section |
|---|---|
| view state changes | The URL is state |
| a route is protected | Guards |
| navigation happens | Transitions |
