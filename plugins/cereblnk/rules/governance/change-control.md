---
name: governance-change-control
genre: constraint
category: governance
density: neutral
applies_when: a change is prepared, reviewed, or released
---

# Change Control

Extends [`common/coding-style.md`](../common/coding-style.md).

## One change, one reason

- A change carries one intent; unrelated work goes to its own change
- Every changed line traces to the stated intent

Avoid: a fix bundled with a rename. A reformatted file inside a small
change. A dependency bump riding along with a feature.

## Review

- A severe finding blocks; it is not an approving comment
- The decision is stated first: merge, or do not

```text
blocking     correctness, security, data loss, irreversibility
non-blocking style, naming, preference
stated       the decision, before the list of observations
```

Avoid: twelve style comments burying one authorisation gap. A blocking
finding softened into a suggestion. An approval with no decision
stated.

## Release

- A release states what is irreversible in it
- A rollback is rehearsed before it is relied on

Avoid: a rollback attempted for the first time during an incident.
Schema and code coupled so neither can return. A release bundling
thirty changes, so a regression has thirty suspects.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a change is prepared | One change, one reason |
| a change is reviewed | Review |
| a release is assembled | Release |
