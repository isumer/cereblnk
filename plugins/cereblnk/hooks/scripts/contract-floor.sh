#!/usr/bin/env bash
# ContractFloorHook (SubagentStop) — CB-116 gates cross-surface agreement at close.
# Parallel starts survive; no contract/errors fail open and re-entry is bounded.

# CB-113/CB-114 cover execution and reachability, not cross-surface agreement.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0
[ -n "${CB_ROOT:-}" ] || exit 0
[ -d "$CB_DIR/memory/contracts" ] || exit 0

RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0
[ -f "$RUN/exec.log" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/contract-check"
[ -f "$CHECK" ] || exit 0

RESULT="$(printf '%s' "$INPUT" | CB_RUN="$RUN" CB_ROOT="$CB_ROOT" CB_CHECK="$CHECK" \
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
findings = sorted(set(l.strip() for l in r.stdout.splitlines() if l.strip()))

baseline_path = run / "contract-baseline.txt"
try:
    baseline = set(l.strip() for l in baseline_path.read_text(
        encoding="utf-8").splitlines() if l.strip())
except (OSError, UnicodeError):
    shown = findings[:10]
    print("NOTE\nContract-floor could not compare this run with its starting "
          "state because contract-baseline.txt is missing or unreadable. "
          "Failing open; current contract risk:\n  %s"
          % "\n  ".join(shown))
    sys.exit(0)

preexisting = [f for f in findings if f in baseline]
new = [f for f in findings if f not in baseline]

def risk_note(rows):
    if not rows:
        return ""
    return ("Pre-existing contract risk (present when this run was armed; "
            "reported, not blocking):\n  %s" % "\n  ".join(rows[:10]))

note = risk_note(preexisting)
if not new:
    if note:
        print("NOTE\n" + note)
    sys.exit(0)

state = run / ("contract-floor.%s.state" % agent)
count = 0
if state.exists():
    try:
        count = int(state.read_text(encoding="utf-8").strip() or 0)
    except ValueError:
        count = 0
if count >= int(os.environ["CB_MAX"]):
    if note:
        print("NOTE\n" + note)
    sys.exit(0)
state.write_text(str(count + 1), encoding="utf-8")

message = ("%s is closing a surface that introduced contract findings "
      "during this run:\n  %s\n"
      "Each line names one side and one channel. Carry the missing channel "
      "on this surface, or remove the path the contract replaced. If a row "
      "is genuinely later work, mark its migration status deferred in the "
      "contract and say why in your Response Block — an unmatched surface "
      "is not a finished change, it is a change the other leg cannot meet."
      % (agent, "\n  ".join(new[:10])))
if note:
    message += "\n\n" + note
print("BLOCK\n" + message)
' 2>/dev/null || true)"

case "$RESULT" in
  BLOCK$'\n'*) printf '%s\n' "${RESULT#*$'\n'}" >&2; exit 2 ;;
  NOTE$'\n'*)  printf '%s\n' "${RESULT#*$'\n'}" >&2 ;;
esac
exit 0
