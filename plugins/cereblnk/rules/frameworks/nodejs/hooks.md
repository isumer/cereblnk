---
name: nodejs-hooks
genre: constraint
category: frameworks
paths:
  - "**/server/**/*.ts"
  - "**/server/**/*.js"
  - "**/src/**/*.server.ts"
  - "**/api/**/*.ts"
  - "**/*.route.ts"
---

# Node.js Hooks

Extends [`languages/javascript/hooks.md`](../../languages/javascript/hooks.md).

## On edit

```text
lint      the edited file
type      check the project where types exist
verify    no synchronous filesystem or crypto call on a request path
```

Avoid: a blocking call found under load rather than by a hook.

## On dependency change

```text
install   with the lock file respected
audit     the tree for advisories
inspect   install scripts of newly added packages
```

Avoid: an install that rewrites the lock as a side effect.

## On start-up path change

```text
run     the process starts and reports ready
verify  the shutdown path drains before exit
expect  exit code and the first failure only
```

Avoid: a start-up failure found in an environment.

## Trigger table

| Situation | Section |
|---|---|
| a source file was edited | On edit |
| a manifest or lock changed | On dependency change |
| a server or signal handler changed | On start-up path change |
