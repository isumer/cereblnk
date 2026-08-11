#!/usr/bin/env bash
# ContractFloorHook (SubagentStop) — CB-116, hard enforcement.
#
# CB-113 asks whether a changed surface was run. CB-114 asks whether new
# code is reached. Both are single-surface questions, and the failure
# that costs a migration is not: each leg is internally correct, each
# runs clean, and they disagree with each other.
#
# This asks the cross-surface question at the only moment it is cheap —
# before the specialist closes — and asks it of the specialist's OWN
# surface only. The UI is asked whether the UI carries every channel the
# contract names, never whether the backend is finished. Two developers
# or two agents work in parallel and neither waits for the other. What
# neither may do is close while its own side is silent about a channel.
#
# This is a closing gate on purpose. A starting gate — refusing to let
# the UI begin until the contract exists — would serialise the work and
# is the wrong trade: the failure was never that a leg started early, it
# was that a leg finished unmatched.
#
# No contract, no floor. A project that has not written one is not in
# scope, and a hook that demanded contracts of every task would be a
# tax on single-surface work.
#
# Loop safety and fail-open in skill-floor.sh's shape.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
# shellcheck source=../lib/hostio.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/hostio.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0
[ -n "${CB_ROOT:-}" ] || exit 0
[ -d "$CB_DIR/memory/contracts" ] || exit 0

RUN="$(ls -1dt "$CB_DIR"/context/*/ 2>/dev/null | head -1)"
[ -n "$RUN" ] || exit 0
[ -f "$RUN/exec.log" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/contract-check"
[ -f "$CHECK" ] || exit 0

REASON="$(printf '%s' "$INPUT" | CB_RUN="$RUN" CB_ROOT="$CB_ROOT" CB_CHECK="$CHECK" \
  CB_PY="$PYBIN" CB_MAX="${CB_CONTRACT_NUDGES:-2}" $PYBIN -c '
import json, os, pathlib, subprocess, sys

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)

run = pathlib.Path(os.environ["CB_RUN"])
edited = []
for line in (run / "exec.log").read_text(encoding="utf-8").splitlines():
    parts = line.split("\t")
    if len(parts) == 4 and parts[1] == agent and parts[2] == "edit" \
            and parts[3] not in edited:
        edited.append(parts[3])
if not edited:
    sys.exit(0)

cmd = os.environ["CB_PY"].split() + [os.environ["CB_CHECK"], os.environ["CB_ROOT"]] + edited
try:
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
except Exception:
    sys.exit(0)
if r.returncode != 1 or not r.stdout.strip():
    sys.exit(0)
findings = [l for l in r.stdout.strip().splitlines() if l.strip()][:10]

state = run / ("contract-floor.%s.state" % agent)
count = 0
if state.exists():
    try:
        count = int(state.read_text(encoding="utf-8").strip() or 0)
    except ValueError:
        count = 0
if count >= int(os.environ["CB_MAX"]):
    sys.exit(0)
state.write_text(str(count + 1), encoding="utf-8")

print("%s is closing a surface that does not match its contract:\n  %s\n"
      "Each line names one side and one channel. Carry the missing channel "
      "on this surface, or remove the path the contract replaced. If a row "
      "is genuinely later work, mark its migration status deferred in the "
      "contract and say why in your Response Block — an unmatched surface "
      "is not a finished change, it is a change the other leg cannot meet."
      % (agent, "\n  ".join(findings)))
' 2>/dev/null || true)"

if [ -n "$REASON" ]; then
  cb_block "$REASON"
fi
exit 0
