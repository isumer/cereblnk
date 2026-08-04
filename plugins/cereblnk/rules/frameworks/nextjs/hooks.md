---
name: nextjs-hooks
genre: constraint
category: frameworks
paths:
  - "**/app/**/*.tsx"
  - "**/app/**/*.ts"
  - "**/pages/**/*.tsx"
  - "**/next.config.*"
  - "**/middleware.ts"
---

# Next.js Hooks

Extends [`languages/typescript/hooks.md`](../../languages/typescript/hooks.md).

## On component edit

```text
lint       the edited file, with the framework's rule set
boundary   verify no server-only import crosses a client directive
type       check the project, incrementally
```

Avoid: a boundary violation found at build time in the pipeline.

## On route change

```text
list      the routes the build produces
diff      against the previous list
verify    each new route declares its strategy
```

Avoid: a route added with no strategy stated. A dynamic route made
static by a default nobody read.

## On build

```text
scan      the client bundle for known secret names
report    exit code and the matching file only
never     the full build log into an agent's context
```

Avoid: a build log pasted whole into a response.

## Trigger table

| Situation | Section |
|---|---|
| a component was edited | On component edit |
| a route file changed | On route change |
| a production build runs | On build |
