---
name: angular-hooks
genre: constraint
category: frameworks
paths:
  - "**/*.component.ts"
  - "**/*.service.ts"
  - "**/*.spec.ts"
  - "**/angular.json"
---

# Angular Hooks

Extends [`languages/typescript/hooks.md`](../../languages/typescript/hooks.md).

## On edit

```text
lint       the edited file, with the framework's rule set
template   type-check templates, not only the class
build      the affected project, incrementally
expect     exit code, and file:line diagnostics only
```

Avoid: a template error found at runtime. A full workspace build after
one component edit.

## On test edit

```text
edited a spec     that spec file, headless
edited a source   the specs covering it
never on edit     end-to-end suites, real browsers
```

## On workspace change

```text
verify   project configuration parses
verify   budgets still hold for the affected project
```

Avoid: a bundle budget exceeded and noticed after release.

## Trigger table

| Situation | Section |
|---|---|
| a component or service was edited | On edit |
| a spec was edited | On test edit |
| workspace configuration changed | On workspace change |
