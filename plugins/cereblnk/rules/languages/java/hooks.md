---
name: java-hooks
genre: constraint
category: languages
paths:
  - "**/*.java"
  - "**/pom.xml"
  - "**/build.gradle"
  - "**/build.gradle.kts"
---

# Java Hooks

Extends [`common/hooks.md`](../../common/hooks.md), which sets scope
and blocking policy.

## On edit

- Format and style-check the edited file only
- Compile the containing module, not the repository
- Seconds, not minutes

```text
format        the edited file
style check   the edited file, committed configuration
compile       the containing module
expect        exit code, and file:line errors only
budget        seconds, not minutes
scope         never the repository, never a packaging phase
```

Avoid: a full multi-module build after one edit · a packaging phase in
an edit hook · formatting applied to untouched files.

## On test edit

- Run the edited test class
- A source edit runs its module's unit tests
- Integration and container-backed suites stay out of edit hooks

```text
edited a test     that test class
edited a source   the module's unit tests
never on edit     integration, container-backed, end-to-end
```

## On build file change

- Re-resolve the dependency tree, offline where possible
- Inspect duplicate versions and new transitive entries
- Confirm the resolution output is committed

```text
resolve   the tree, offline where possible
inspect   duplicate versions, new transitive entries
verify    the resolution output is committed
```

Avoid: a version change merged without resolution · a transitive
entry noticed after release.

## Output

- Build and test output passes through the run-quiet gate
- Full output to the run's log directory; the digest is what returns

```text
returned   exit code, failing test names, first assertion
returned   compile errors as file:line, deduplicated
never      the raw stream into an agent's context
```

Avoid: a build log pasted into a response · a stack trace returned
whole · a second unwrapped run to see more.

## Trigger table

| Situation | Section |
|---|---|
| a source file was edited | On edit |
| a test file was edited | On test edit |
| a build file changed | On build file change |
| output must reach an agent | Output |
