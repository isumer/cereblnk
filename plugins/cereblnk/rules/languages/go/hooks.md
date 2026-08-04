---
name: go-hooks
genre: constraint
category: languages
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go Hooks

Extends [`common/hooks.md`](../../common/hooks.md), which sets scope
and blocking policy.

## On edit

```text
format      the edited file, imports included
vet         the containing package
build       the containing package
expect      exit code, and file:line diagnostics only
budget      seconds, not minutes
```

Avoid: a repository-wide build after one edit · a linter suite bound
to every save.

## On test edit

```text
edited a test     that package's tests
concurrency work  the race detector, on that package
never on edit     integration tags, container-backed suites
```

## On module change

```text
tidy      verify the module files are consistent
verify    the checksum database agrees
confirm   both files are part of the diff
```

Avoid: a dependency added without tidying · a checksum mismatch
noticed in the pipeline.

## Output

```text
returned   exit code, failing test names, first failure per package
returned   vet and build errors as file:line, deduplicated
never      the raw stream into an agent's context
```

Avoid: a build log pasted into a response · a panic trace returned
whole.

## Trigger table

| Situation | Section |
|---|---|
| a source file was edited | On edit |
| a test file was edited | On test edit |
| a module file changed | On module change |
| output must reach an agent | Output |
