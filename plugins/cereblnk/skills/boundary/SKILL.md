---
name: cb-boundary
description: Declare (or clear) an edit boundary — blocks Write/Edit outside the given directory during focused work
argument-hint: <path | off>
---

# /cb-boundary

Manage Cereblnk's EditBoundaryHook (see `hooks/README.md`).

- `$ARGUMENTS` = a path: verify the path exists, then
  `${CLAUDE_PLUGIN_ROOT}/scripts/run-flag flag boundary arm "" "<path>"`.
It resolves `$CB_DIR` and verifies the flag landed.
A non-zero exit means the boundary is not enforced.
  Confirm to the user that Write/Edit is now restricted to that
  directory subtree. Multiple allowed prefixes = one per line in the
  flag file.
- `$ARGUMENTS` = `off`: `${CLAUDE_PLUGIN_ROOT}/scripts/run-flag flag boundary disarm`, confirm
  disengaged.

Honest note: this blocks editing tools, not shell side-effects —
accident prevention, not a sandbox. Do not modify anything else.
