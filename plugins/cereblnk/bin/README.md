# `bin/` — no executables, on purpose

Claude Code puts `<plugin>/bin` on `PATH` for an installed plugin.
Cereblnk ships nothing runnable here. That is a decision, not an
omission (F-12), and this note exists at the path someone looking for
the missing directory would look.

## Why nothing lives here

Every script this plugin runs is invoked by absolute path:
`${CLAUDE_PLUGIN_ROOT}/scripts/select-agents`,
`${CLAUDE_PLUGIN_ROOT}/hooks/scripts/delegation-guard.sh`. Hooks and
library scripts resolve their siblings relative to their own location.
No caller anywhere reads `PATH` to find a Cereblnk script, so a name
placed here would be found by nobody.

Adding the scripts here would give each of them a second name that
resolves through `PATH` instead of through the plugin root. A bare
`select-agents` is then whichever copy the search order reaches first —
another plugin's, an older install's, a user's own. The absolute form
names the copy that shipped with this version. That property is worth
more than the convenience of a short name.

The directory itself is kept so the `PATH` entry points at something
real rather than at nothing.

## If you add an executable here

It must carry the exec bit. A file on `PATH` that cannot be executed
fails the way this repository has been bitten by before: silently.
`scripts/check-exec-bit` rule X-4 enforces that, and it also fails if
this directory disappears, so the tree and the claim stay in agreement.

Adding one also makes a `PATH`-resolved name part of the plugin's
public surface, which is the thing the rule above exists to avoid.
Prefer `scripts/`.
