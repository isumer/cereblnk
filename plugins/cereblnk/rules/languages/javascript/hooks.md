---
name: javascript-hooks
genre: constraint
category: languages
paths:
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/package.json"
---

# JavaScript Hooks

Extends [`common/hooks.md`](../../common/hooks.md), which sets scope
and blocking policy.

## On edit

```text
format        the edited file
lint          the edited file, repo configuration
type-check    the project, incrementally
expect        exit code, and file:line diagnostics only
budget        seconds, not minutes
```

Avoid: a full type-check from cold on every save · a lint run across
the repository after one edit.

## On test edit

```text
edited a test     that test file
edited a source   the tests covering it
never on edit     browser suites, container-backed tests
```

## On dependency change

```text
install    with the lock file respected, never regenerated silently
audit      the tree for advisories
verify     the lock file change is part of the diff
```

Avoid: an install that rewrites the lock file as a side effect · an
advisory noticed after release.

## Output

```text
returned   exit code, failing test names, first diagnostic per file
returned   type errors as file:line, deduplicated
never      the raw stream into an agent's context
```

Avoid: a compiler log pasted into a response · a stack trace returned
whole.

## Trigger table

| Situation | Section |
|---|---|
| a source file was edited | On edit |
| a test file was edited | On test edit |
| a manifest or lock file changed | On dependency change |
| output must reach an agent | Output |
