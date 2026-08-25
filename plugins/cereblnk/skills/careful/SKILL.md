---
name: cb-careful
description: Toggle the DestructiveCommandHook for this project — blocks irreversible shell operations until turned off
argument-hint: [on|off]
---

# /cb-careful

Toggle Cereblnk's DestructiveCommandHook (see `hooks/README.md`).

## The direction is parsed, never inferred (F-17)

Do not compare `$ARGUMENTS` yourself. Do not paraphrase it. Run one
command, with the argument substituted verbatim:

```
${CLAUDE_PLUGIN_ROOT}/scripts/run-flag flag careful "$ARGUMENTS"
```

If `$ARGUMENTS` is empty, substitute the literal `on`. That is the
only substitution you make.

`run-flag` accepts exactly `on`, `off`, `arm`, `disarm`, `status`. It
resolves `$CB_DIR`. It then verifies the flag landed on disk.

- **exit 0** — the flag is in the reported state. Say which.
- **exit 2** — the argument was not a direction. Nothing changed.
  Report the current state. Quote what the user passed. Ask them for
  `on` or `off`. Never pick one for them. This toggle decides whether
  irreversible commands are blocked. A guessed direction is a
  silently disabled protection.
- **exit 1** — the protection is *not* active. Do not confirm it as
  enabled. Report the stderr line as-is.

## After a successful `on`

Confirm what is now blocked pending the user's confirmation:
recursive delete, forced delete, force-push, hard reset,
`git clean -f`, destructive SQL, destructive Docker operations, and
disk-level writes. Build-artifact cleanups stay allowed
(`node_modules`, `dist`, `build`, `target`, `.next`, `coverage`).

Two things the hook does *not* block. Tell the user both.

- Text that only mentions a destructive command. A heredoc body, a
  quoted string, a doc, a fixture: none of these is a command. None
  is blocked (F-18).
- Turning the protection off again. `/cb-careful off` runs
  `run-flag flag careful disarm`, which is not a delete. Deleting
  `$CB_DIR/flags/careful` by hand is allowlisted too (F-19). An
  escape the block prescribes must not be blocked by that block.

State the current status after the change. Do not modify anything
else.
