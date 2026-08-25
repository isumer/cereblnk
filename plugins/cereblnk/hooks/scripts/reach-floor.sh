#!/usr/bin/env bash
# ReachFloorHook (SubagentStop) — CB-114, hard enforcement.
#
# ExecFloorHook (CB-113) asks whether a changed surface was run. This
# asks the question running does not answer: is the new code reached at
# all. Unwired code fails by silence — no exception, no console error,
# nothing to see in a smoke run. A client module whose connect function
# is written, exported, and never called passes review, passes the skill
# floor, runs clean, and reports complete.
#
# Precision over recall. scripts/reachability reports a symbol only when
# its identifier appears nowhere in the project outside its own
# declaration line, and exempts anything carrying a decorator or
# annotation, where a framework may be the caller. A report is therefore
# near-certain; a clean result is weak evidence. That is the correct
# trade for a check that gets switched off the first time it cries wolf.
#
# Escape hatch: $CB_DIR/config/reachability-ignore, one symbol per line.
# A public API surface with no in-repo consumer is a real thing and the
# agent must not be trapped arguing with a hook about it.
#
# Loop safety and fail-open in skill-floor.sh's shape:
#   1. stop_hook_active in stdin -> always allow the stop.
#   2. Nudge state keyed to run dir + agent.
#   3. Hard cap MAX_NUDGES per agent per run, then allow.
#   4. Fail open on every error path.
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
