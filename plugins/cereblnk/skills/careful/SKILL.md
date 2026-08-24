---
name: cb-careful
description: Toggle the DestructiveCommandHook for this project — blocks irreversible shell operations until turned off
argument-hint: [on|off]
---

# /cb-careful

Toggle Cereblnk's DestructiveCommandHook (see `hooks/README.md`).

- `$ARGUMENTS` = `on`, or empty. Run
  `${CLAUDE_PLUGIN_ROOT}/scripts/run-flag flag careful arm`.
It resolves `$CB_DIR` and verifies the flag landed.
A non-zero exit means the protection is not active.
Do not confirm it as enabled.
  Then confirm to the user what is now blocked pending their
  confirmation: recursive delete, force-push, hard reset, and
  destructive SQL.
- `$ARGUMENTS` = `off`: `${CLAUDE_PLUGIN_ROOT}/scripts/run-flag flag careful disarm`, then confirm the hook is disengaged.

State the current status after the change. Do not modify anything else.
