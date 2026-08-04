---
name: common-dependency-management
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Dependency Management

Technology-neutral. A dependency is a permanent commitment made in one
line.

## Adding

- State what it replaces and what writing it ourselves would cost
- Record its licence, maintenance, and release cadence

Avoid: a library added for one helper function · a dependency chosen
by familiarity · an addition with no stated alternative.

## Pinning

- Production builds resolve to the same bytes every time
- Base images and toolchains pinned by digest, not by tag
- The lock file is committed and reviewed like source

Avoid: a version range in a shipped build · a floating tag on a base
image · a lock file excluded from review.

## Updating

- One reason per update, stated

```text
security   a named advisory, applied promptly
feature    a capability the code now needs
hygiene    scheduled, batched, verified by the suite
```

Avoid: a bulk update with no reason · a major bump inside a feature
change · an update applied to make a failing build pass.

## The tree

- The transitive set is the real surface: inspect what arrives with it
- Duplicate versions of one library are resolved, not ignored
- Licences are checked across the tree, not on the direct entry

Avoid: a direct dependency reviewed while its tree is not · a licence
conflict found after release.

## Removing

- An unused dependency goes with the change that removed its last use
- The lock file is regenerated and the suite re-run

Avoid: a dependency left behind after a refactor · an entry kept
because removal was never verified.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a dependency is added | Adding |
| a version is declared | Pinning |
| a dependency is updated | Updating |
| a transitive tree changes | The tree |
| a usage is deleted | Removing |
