#!/usr/bin/env bash
# RouteHintHook (UserPromptSubmit) — CB-149, F-57.
#
# TOPOLOGY.md says cb-dispatch routes automatically when a request
# touches a codebase without naming a /cb- command. Measured over a
# whole session of codebase work: zero automatic invocations —
# description matching is the host model's discretion, not a
# mechanism, and nothing else pushed.
#
# Supplies the push and only the push. It does NOT decide the workflow:
# that table lives in skills/dispatch, and a second copy would diverge.
#
# Never blocks — a routing hint that can stop a turn is worse than the
# problem it solves.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"

PROMPT="$(printf '%s' "$INPUT" | CEREBLNK_HOOK_INPUT="$INPUT" $PYBIN -c '
import json, os, sys
try:
    d = json.loads(os.environ.get("CEREBLNK_HOOK_INPUT") or "{}")
except Exception:
    sys.exit(0)
p = d.get("prompt") or ""
# One line, bounded: a pasted file is not a routing signal.
sys.stdout.write(" ".join(p.split())[:600])
' 2>/dev/null || true)"

[ -n "$PROMPT" ] || exit 0

# ---- silence conditions, in order of authority --------------------------
# 1. An explicit command wins (dispatch rule 4).
case "$PROMPT" in *"/cb-"*) exit 0 ;; esac

# 2. A run is armed: a workflow already owns this turn.
[ -f "$CB_DIR/flags/run-active" ] && exit 0

# 3. Opt-out, same shape as the careful/boundary flags.
[ -f "$CB_DIR/flags/no-route-hint" ] && exit 0

SEL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/select-agents"
[ -x "$SEL" ] || exit 0

# The same selector every workflow runs, so a hint cannot disagree with
# the routing it points at. Timeout: this is the keystroke path.
OUT="$(timeout 10 "$SEL" --text "$PROMPT" 2>/dev/null || true)"
[ -n "$OUT" ] || exit 0

# 4. Unresolved is silence, never a guess: `inferred: true` means no
#    rule matched and the selector fell back.
case "$OUT" in *"inferred: true"*) exit 0 ;; esac

# Heredoc, not -c: the parser below needs single quotes of its own, and
# a -c block wrapped in them ends at the first one it contains.
CEREBLNK_SEL_OUT="$OUT" $PYBIN - <<'PY' 2>/dev/null || true
import json, os, re, sys
out = os.environ.get("CEREBLNK_SEL_OUT") or ""
specs = re.findall(r"^\s+-\s+(\S+)\s*$", out.split("specialists:", 1)[-1].split("gate_level:")[0], re.M)
specs = [s.rsplit(":", 1)[-1] for s in specs if "agent" in s]
if not specs:
    sys.exit(0)
m = re.search(r"gate_level:\s*(\d+)", out)
gate = m.group(1) if m else "?"
why = re.findall(r'"([^"]+)"', out.split("signals:", 1)[-1])[:3]

note = (
    "Cereblnk routing signal: this request resolves to %s at gate level %s"
    "%s. This is the case cb-dispatch exists for — it owns the intent "
    "table and this hook deliberately does not. Invoke it before editing "
    "files yourself. If the request is a question rather than work on "
    "the codebase, answer it directly and ignore this line."
) % (", ".join(specs), gate, (" (signals: %s)" % "; ".join(why)) if why else "")

print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit", "additionalContext": note}}))
PY
exit 0
