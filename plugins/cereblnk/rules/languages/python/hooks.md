---
name: python-hooks
genre: constraint
category: languages
paths:
  - "**/*.py"
  - "**/*.pyi"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---

# Python Hooks

Extends [`common/hooks.md`](../../common/hooks.md), which sets scope
and blocking policy.

## On edit

```text
format        the edited file
sort imports  the edited file
lint          the edited file, repo configuration
type-check    the package containing it
expect        exit code, and file:line diagnostics only
budget        seconds, not minutes
```

Avoid: a repository-wide lint after one edit · a type check from cold
on every save.

## On test edit

```text
edited a test     that test module
edited a source   the tests covering it
never on edit     container-backed or network-dependent suites
```

## On requirement change

```text
resolve   with the lock file respected
audit     the tree for advisories
verify    the lock change is part of the diff
```

Avoid: an install that rewrites the lock as a side effect · a
transitive addition noticed after release.

## Output

```text
returned   exit code, failing test node ids, first assertion
returned   type and lint errors as file:line, deduplicated
never      the raw stream into an agent's context
```

Avoid: a traceback returned whole · a second unwrapped run to see
more.

## Trigger table

| Situation | Section |
|---|---|
| a source file was edited | On edit |
| a test file was edited | On test edit |
| a requirement or lock file changed | On requirement change |
| output must reach an agent | Output |
