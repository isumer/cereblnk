---
name: shell-hooks
genre: constraint
category: languages
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/Makefile"
---

# Shell Hooks

Extends [`common/hooks.md`](../../common/hooks.md), which sets scope
and blocking policy.

## On edit

```text
lint        the edited script, shell-aware
format      the edited script
parse       syntax check without executing
expect      exit code, and file:line diagnostics only
```

Avoid: a lint that ignores the shebang's dialect · a syntax check that
executes the script.

## Before it runs anywhere

```text
verify      the executable bit matches intent
verify      strict mode is present
verify      no unquoted expansion on a destructive line
```

Avoid: a script committed without a permission review · a destructive
line reaching the repository unquoted.

## Output

```text
returned   exit code, first diagnostic per file
returned   the failing line and its rule
never      the raw stream into an agent's context
```

Avoid: a lint report pasted whole into a response.

## Trigger table

| Situation | Section |
|---|---|
| a script was edited | On edit |
| a script is committed | Before it runs anywhere |
| output must reach an agent | Output |
