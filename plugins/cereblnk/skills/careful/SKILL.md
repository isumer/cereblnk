---
name: cb-careful
description: Toggle the DestructiveCommandHook for this project — blocks irreversible shell operations until turned off
argument-hint: [on|off]
---

# /cb-careful

Toggle Cereblnk's DestructiveCommandHook (see `hooks/README.md`).

- `$ARGUMENTS` = `on`, or empty. Run
  `mkdir -p .claude/cereblnk/flags && touch .claude/cereblnk/flags/careful`.
  Then confirm to the user what is now blocked pending their
  confirmation: recursive delete, force-push, hard reset, and
  destructive SQL.
- `$ARGUMENTS` = `off`: `rm -f .claude/cereblnk/flags/careful`, then confirm the hook is disengaged.

State the current status after the change. Do not modify anything else.
