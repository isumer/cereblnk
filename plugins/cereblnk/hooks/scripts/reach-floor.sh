#!/usr/bin/env bash
# ReachFloorHook (SubagentStop) — CB-114. Exit 2 catches unwired declarations CB-113 misses.
# Favor precision; ignore configured APIs/decorators, bound re-entry, and fail open.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0
[ -n "${CB_ROOT:-}" ] || exit 0

RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0
[ -f "$RUN/edited-files.log" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

REACH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/reachability"
[ -f "$REACH" ] || exit 0

REASON="$(printf '%s' "$INPUT" | CB_RUN="$RUN" CB_ROOT="$CB_ROOT" CB_REACH="$REACH" \
  CB_PY="$PYBIN" CB_MAX="${CB_REACH_NUDGES:-2}" $PYBIN -c '
import json, os, pathlib, subprocess, sys

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)

run = pathlib.Path(os.environ["CB_RUN"])
root = os.environ["CB_ROOT"]

files = []
for line in (run / "edited-files.log").read_text(encoding="utf-8").splitlines():
    parts = line.split("\t")
    if len(parts) == 3 and parts[1] == agent and parts[2] not in files:
        files.append(parts[2])
if not files:
    sys.exit(0)

cmd = os.environ["CB_PY"].split() + [os.environ["CB_REACH"], root] + files[:200]
try:
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
except Exception:
    sys.exit(0)
if r.returncode != 1 or not r.stdout.strip():
    sys.exit(0)
orphans = [l for l in r.stdout.strip().splitlines() if l.strip()][:10]

state = run / ("reach-floor.%s.state" % agent)
count = 0
if state.exists():
    try:
        count = int(state.read_text(encoding="utf-8").strip() or 0)
    except ValueError:
        count = 0
if count >= int(os.environ["CB_MAX"]):
    sys.exit(0)
state.write_text(str(count + 1), encoding="utf-8")

print("%s defined code that nothing in this project calls:\n  %s\n"
      "Wire each one into the path that should reach it, or delete it — "
      "an unreferenced symbol is not a finished change, it is a change "
      "that was never connected. If a symbol is a deliberate public "
      "surface with no in-repo consumer, add its name to "
      "config/reachability-ignore and say so in your Response Block."
      % (agent, "\n  ".join(orphans)))
' 2>/dev/null || true)"

if [ -n "$REASON" ]; then
  echo "$REASON" >&2
  exit 2
fi
exit 0
