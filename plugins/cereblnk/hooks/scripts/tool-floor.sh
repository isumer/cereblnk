#!/usr/bin/env bash
# ToolFloorHook blocks in-place shell edits and replacement Writes for agents denied edit tools.
# Write-shaped redirection stays allowed; shellwrite covers ordinary forms, not bypasses.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"
. "$HERE/lib/cbenv.sh" 2>/dev/null || true
. "$HERE/lib/cbowner.sh" 2>/dev/null || true
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
if not isinstance(d, dict) or d.get("tool_name") not in {"Bash", "Write"}:
    sys.exit(0)

# F-10: qualified and bare agent names resolve by last segment; opaque IDs do not.
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

if d.get("tool_name") == "Write":
    ti = d.get("tool_input") or {}
    target = ti.get("file_path") if isinstance(ti, dict) else None
    if not isinstance(target, str) or not target.strip():
        sys.exit(0)
    print("\x1f".join(("WRITE", key, ", ".join(sorted(denied)), target.strip())))
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
  WRITE$'\037'*)
    IFS=$'\037' read -r _kind _role _denied _where <<< "$REASON"
    # Only the Write branch needs a repo root; requiring it earlier would
    # have silently disarmed the shell branch too.
    [ -n "${CB_ROOT:-}" ] || exit 0
    [ -e "$_where" ] || exit 0
    [ "$(type -t cb_is_repo_source 2>/dev/null || true)" = "function" ] || exit 0
    cb_is_repo_source "$_where" || exit 0
    echo "Cereblnk ToolFloor: $_role is declared \`disallowedTools: $_denied\`, and Write would replace existing repository source $_where. This role decides and records: put the change in your Response Block as a finding, or hand the edit to the surface specialist that owns the file." >&2
    exit 2
    ;;
esac
exit 0
