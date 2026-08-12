# Cereblnk

Cereblnk turns engineering discipline into mechanism. This file is the
context Gemini CLI loads for the extension; the host-neutral instructions
every agent works under are in `AGENTS.md` at the repository root, and
that is the file to read first.

## Packaging only, on this host

Skills under `skills/` and sub-agents under `agents/` are discovered by
folder, so they load. The enforcement layer does not: two things block
it, both recorded in `.claude/BACKLOG.md` under CB-141.

Hooks are read from `hooks/hooks.json` inside the extension root and the
manifest offers no field to point elsewhere. That file is Claude Code's
binding, written in Claude Code's shape. Codex and Cursor both hit the
same default and both let a manifest redirect it; here there is nothing
to redirect with.

Extension hook commands substitute `${extensionPath}`, not the plugin
root variable Cereblnk's hooks are written against, and extensions do not
inherit the shell environment — only standard variables and those a
manifest declares. Cereblnk's hooks read several that are declared
nowhere.

So on this host Cereblnk is a skill and sub-agent bundle. The floors do
not arm, and nothing here claims they do.
