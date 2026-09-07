#!/usr/bin/env bash
# GateFloorHook (Stop): required risk-scaled verification must exist before finish.
# Presence proves gates ran, not that they passed; verdict values are intentionally ignored.
set -uo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" 2>/dev/null && pwd)" || exit 0
. "$SCRIPTS/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -f "$CB_DIR/flags/run-active" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0
MAX_NUDGES=3

INPUT="$(cat 2>/dev/null || true)"
INPUT_STATE="$(printf '%s' "$INPUT" | $PYBIN -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
if not isinstance(data, dict):
    sys.exit(1)
print("active" if data.get("stop_hook_active") is True else "ready")
' 2>/dev/null)" || exit 0
[ "$INPUT_STATE" = "ready" ] || exit 0

PIN="$(head -n 1 "$CB_DIR/flags/run-active" 2>/dev/null | tr -d ' \t\r\n')"
[ -n "$PIN" ] || exit 0
RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0
RUN_NAME="${RUN%/}"; RUN_NAME="${RUN_NAME##*/}"
[ "$RUN_NAME" = "$PIN" ] || exit 0
RISK=""
if [ -f "$RUN/plan.md" ] && [ -r "$RUN/plan.md" ]; then
  . "$SCRIPTS/lib/run-lifecycle.sh" 2>/dev/null || exit 0
  type _completion_plan_metadata >/dev/null 2>&1 || exit 0
  METADATA="$(_completion_plan_metadata "$RUN/plan.md" 2>/dev/null)" || exit 0
  case "$METADATA" in *$'\t'*) RISK="${METADATA#*$'\t'}" ;; esac
fi
if [ -z "$RISK" ] || [ "$RISK" = "-" ]; then
  # CB-177: a plan-less /cb-do has no plan to carry risk; select-agents
  # persists the gate level it chose, so the floor is not blind there.
  LEVEL="$(sed -n 's/^gate_level:[[:space:]]*\([0-9]\{1,\}\).*/\1/p' \
    "$RUN/agents-required.yaml" 2>/dev/null | head -n 1)"
  case "$LEVEL" in
    2) RISK="medium" ;;
    3) RISK="high" ;;
  esac
fi
case "$RISK" in
  medium) REQUIRED="verifier-agent consistency-agent" ;;
  high) REQUIRED="verifier-agent consistency-agent challenger-agent" ;;
  *) rm -f "$RUN/gate-floor.state" 2>/dev/null || true; exit 0 ;;
esac

OUTPUT="$(CB_RUN="$RUN" CB_REQUIRED="$REQUIRED" CB_MAX="$MAX_NUDGES" $PYBIN -c '
import json, os, pathlib, re, sys

run = pathlib.Path(os.environ["CB_RUN"])
required = os.environ["CB_REQUIRED"].split()
maximum = int(os.environ["CB_MAX"])

def top(text, key):
    match = re.search(r"^%s[ \t]*:[ \t]*(.*)$" % re.escape(key), text, re.M)
    if not match:
        return ""
    value = match.group(1).split("#", 1)[0].strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("\"", chr(39)):
        value = value[1:-1]
    return value

def norm(value):
    return re.sub(r"[^a-z0-9]", "", value.rsplit(":", 1)[-1].lower())

present = set()
try:
    for path in sorted(run.glob("*.yaml")):
        if not path.is_file():
            continue
        body = path.read_text(encoding="utf-8", errors="strict")
        if top(body, "kind").lower() == "verification" and top(body, "role"):
            present.add(norm(top(body, "role")))
except Exception:
    sys.exit(0)

missing = [role for role in required if norm(role) not in present]
state = run / "gate-floor.state"
if not missing:
    try:
        state.unlink(missing_ok=True)
    except OSError:
        pass
    sys.exit(0)

count = 0
previous = set()
if state.exists():
    try:
        saved = json.loads(state.read_text(encoding="utf-8"))
        count = saved["count"]
        saved_missing = saved["missing"]
        if (not isinstance(count, int) or count < 0
                or not isinstance(saved_missing, list)
                or not all(isinstance(item, str) for item in saved_missing)):
            raise ValueError
        previous = set(saved_missing)
    except Exception:
        sys.exit(0)

current = set(missing)
if previous and current < previous:
    count = 0
if count >= maximum:
    sys.exit(0)

count += 1
try:
    state.write_text(json.dumps({"count": count, "missing": missing}) + "\n",
                     encoding="utf-8")
except Exception:
    sys.exit(0)

reason = ("Required verification gate roles are missing: %s. Dispatch each "
          "missing gate agent, then re-attempt the stop (nudge %d/%d)."
          % (", ".join(missing), count, maximum))
print(json.dumps({"decision": "block", "reason": reason}, separators=(",", ":")))
' 2>/dev/null)" || exit 0
[ -n "$OUTPUT" ] && printf '%s\n' "$OUTPUT"
exit 0
