---
name: kotlin-hooks
genre: constraint
category: languages
paths:
  - "**/*.kt"
  - "**/*.kts"
  - "**/build.gradle.kts"
---

# Kotlin Hooks

Extends [`common/hooks.md`](../../common/hooks.md), which sets scope
and blocking policy.

## On edit

```text
format      the edited file
lint        the edited file, repo configuration
compile     the containing module
expect      exit code, and file:line diagnostics only
budget      seconds, not minutes
```

Avoid: a full project build after one edit · a daemon-cold compile on
every save.

## On test edit

```text
edited a test     that test class
edited a source   the module's unit tests
never on edit     integration and container-backed suites
```

## On build file change

```text
resolve   the dependency tree, offline where possible
inspect   duplicate versions and new transitive entries
verify    the lock or resolution output is committed
```

Avoid: a version change merged without resolution.

## Output

```text
returned   exit code, failing test names, first assertion
returned   compile errors as file:line, deduplicated
never      the raw stream into an agent's context
```

Avoid: a build log pasted into a response · a stack trace returned
whole.

## Trigger table

| Situation | Section |
|---|---|
| a source file was edited | On edit |
| a test file was edited | On test edit |
| a build file changed | On build file change |
| output must reach an agent | Output |
