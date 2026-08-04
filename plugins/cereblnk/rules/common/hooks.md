---
name: common-hooks
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Hooks

What must run when files change. The plugin's own enforcement hooks
are a separate fixed set; this constrains project-level checks.

## Purpose

- Every check names the failure it prevents
- A check whose output nobody reads is removed

Avoid: a check added because a tool offers it · a check nobody can
attribute to a past failure.

## Scope

- A post-edit check touches only what the edit affected

```text
edited file        format and lint that file
affected module    compile and unit-test that module
whole repository   on explicit request, or in the pipeline
```

Avoid: a full build after a one-line edit · the whole suite on every
save · a check ignoring which files changed.

## Timing

- Anything past a few seconds moves to commit or to the pipeline

```text
on edit      format, lint, type-check the file
on commit    affected tests, secret scan
in pipeline  full suite, security scan, coverage
```

Avoid: an end-to-end suite bound to a save · a scan on every keystroke
· a check that trains people to disable hooks.

## Tooling

- A check states its required tool and what happens when it is absent

```text
required   stated, with the failure message
optional   skipped with a warning, never silently
offline    an alternative, or an explicit gap
```

Avoid: a missing-command error as the failure mode · a silent skip
that looks like a pass · a hook assuming a network.

## Blocking

- Blocking is reserved for what cannot be undone later
- Every block states how to proceed deliberately

```text
blocks   destructive commands, a credential leaving the machine
warns    style, formatting, thresholds
```

Avoid: style violations blocking a commit · a block with no escape ·
rules that push a team to disable hooks entirely.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a check is proposed | Purpose |
| a check runs after an edit | Scope |
| a check is slow | Timing |
| a check needs a tool | Tooling |
| a check blocks work | Blocking |
