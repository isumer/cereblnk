#!/usr/bin/env bash
# ToolFloorHook (PreToolUse: Bash) — the shell half of a tool denial.
#
# `disallowedTools` closes the tools it names, not the shell, and the
# shell reaches the same files. Twelve agents deny `Edit, NotebookEdit`:
# they decide and record, they never modify existing source. `sed -i`,
# `patch`, `ed` and an editor invocation do exactly that.
#
# Decision table:
#   no agent identity in the payload   -> allow (the conductor;
#                                         DelegationGuard owns it)
#   identity is not a Cereblnk agent   -> allow
#   agent denies no edit tool          -> allow
#   command rewrites no existing file  -> allow
#   otherwise                          -> BLOCK (exit 2)
#
# Scope: it asks `shellwrite.py --in-place`, so it sees the ordinary
# in-place forms and not a determined bypass. It does NOT block
# redirection — an agent holding Write may replace a whole file with the
# tool, so blocking `> file` would be stricter than the grant it has.
#
# Fails open on every error path: no project root, no interpreter, no
# roster, unparseable input -> exit 0.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"
. "$HERE/lib/cbenv.sh" 2>/dev/null || true
[ -n "${PYBIN:-}" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
[ -n "$INPUT" ] || exit 0

AGENTS="$(cd "$HERE/../agents" 2>/dev/null && pwd || true)"
[ -n "$AGENTS" ] || exit 0

REASON="$(printf '%s' "$INPUT" | CB_AGENTS="$AGENTS" CB_SW="$HERE/lib/shellwrite.py" $PYBIN -c '
import json, os, pathlib, re, subprocess, sys

raw = sys.stdin.read()
try:
    d = json.loads(raw)
except Exception:
    sys.exit(0)
if not isinstance(d, dict) or d.get("tool_name") != "Bash":
    sys.exit(0)

# Identity on the last segment, as every other floor reads it (F-10):
# the harness hands back `cereblnk:engineering:architect-agent`, a bare
# `architect-agent`, or an opaque id. Only the first two resolve.
agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)                      # the conductor: not this hook s business
key = agent.rsplit(":", 1)[-1]

defn = None
for p in pathlib.Path(os.environ["CB_AGENTS"]).rglob("*.md"):
    if p.stem == key:
        defn = p
        break
if defn is None:
    sys.exit(0)

fm = defn.read_text(encoding="utf-8", errors="replace").split("---")
m = re.search(r"^disallowedTools:\s*(.*)$", fm[1] if len(fm) > 1 else "", re.M)
if not m:
    sys.exit(0)
denied = {t.strip() for t in m.group(1).split(",") if t.strip()}
if not denied & {"Edit", "MultiEdit", "NotebookEdit"}:
    sys.exit(0)

out = subprocess.run([sys.executable, os.environ["CB_SW"], "--in-place"],
                     input=raw, capture_output=True, text=True)
hits = [t for t in out.stdout.splitlines() if t.strip()]
if not hits:
    sys.exit(0)

t = hits[0]
where = "a file it cannot name" if t == "?" else t
print("BLOCK:Cereblnk ToolFloor: %s is declared `disallowedTools: %s`, and "
      "this command rewrites %s in place. Reaching the file through the "
      "shell is the same edit under another tool. This role decides and "
      "records: put the change in your Response Block as a finding, or "
      "hand the edit to the surface specialist that owns the file."
      % (key, ", ".join(sorted(denied)), where))
' 2>/dev/null || true)"

case "$REASON" in
  BLOCK:*) echo "${REASON#BLOCK:}" >&2; exit 2 ;;
esac
exit 0
