#!/usr/bin/env bash
# RouteHintHook (UserPromptSubmit) — CB-149, F-57.
#
# TOPOLOGY.md says cb-dispatch "routes engineering work to the right
# Cereblnk workflow automatically", triggered by its own frontmatter
# description when a request touches a codebase without naming a /cb-
# command. Measured across a full session of codebase work — branch
# edits, a release, a PR — that never happened once:
#
#   skills-loaded.log, whole session:
#     1787657616  main  dispatch      <- typed by the user
#     1787667468  main  orchestrate   <- typed by the user
#
# Zero automatic invocations. The reason is that description matching is
# the host model's discretion, not a mechanism, and nothing else pushed.
# The plugin's only UserPromptSubmit hook was context-monitor, which
# injects a token warning and says nothing about routing. So the
# platform's own entry point was REGISTERED and never ENGAGED — the same
# distinction the rest of this codebase is built to respect.
#
# This hook supplies the missing push, and only the push. It does NOT
# decide the workflow. That table lives in skills/dispatch (Step 3) and
# a second copy of it would diverge from the first — which is exactly
# the defect CB-148 just closed one layer down. The hint carries
# signals; dispatch carries the decision.
#
# Never blocks. UserPromptSubmit CAN block a prompt; a routing hint that
# can stop a user's turn is worse than the problem it solves.
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
# One line, bounded. A prompt that pastes a file is not a routing signal
# and running the selector over it would price this hook at the cost of
# the thing it is trying to save.
sys.stdout.write(" ".join(p.split())[:600])
' 2>/dev/null || true)"

[ -n "$PROMPT" ] || exit 0

# ---- silence conditions, in order of authority --------------------------
# 1. An explicit command wins and always has (dispatch rule 4). Saying
#    anything here would be arguing with the user's own choice.
case "$PROMPT" in *"/cb-"*) exit 0 ;; esac

# 2. A run is already armed: a workflow owns this turn, the conductor is
#    mid-flight, and a routing hint is noise in the middle of routing.
[ -f "$CB_DIR/flags/run-active" ] && exit 0

# 3. Opt-out, same shape as the careful/boundary flags.
[ -f "$CB_DIR/flags/no-route-hint" ] && exit 0

SEL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/select-agents"
[ -x "$SEL" ] || exit 0

# The selector is the single source of routing signal — the same script
# dispatch and every workflow already run, so a hint can never disagree
# with the routing it is pointing at. Timeout: this runs on the user's
# keystroke path and must never be felt.
OUT="$(timeout 10 "$SEL" --text "$PROMPT" 2>/dev/null || true)"
[ -n "$OUT" ] || exit 0

# 4. Unresolved is silence, not a guess. `inferred: true` means no rule
#    matched and the selector fell back to architect-agent; routing on
#    that would be the "never route on a silent default" violation the
#    selector's own output warns about. Measured: "make it nicer" lands
#    here, and should.
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
