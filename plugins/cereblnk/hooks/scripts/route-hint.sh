#!/usr/bin/env bash
# RouteHintHook (UserPromptSubmit) — CB-149/F-57. Host matching produced zero routes.
# Nudge toward dispatch without deciding a workflow or blocking.
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

case "$PROMPT" in *"/cb-"*) exit 0 ;; esac

[ -f "$CB_DIR/flags/run-active" ] && exit 0

[ -f "$CB_DIR/flags/no-route-hint" ] && exit 0

SEL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/select-agents"
[ -x "$SEL" ] || exit 0

# Use the workflow selector; the keystroke path needs a timeout.
OUT="$(timeout 10 "$SEL" --text "$PROMPT" 2>/dev/null || true)"
[ -n "$OUT" ] || exit 0

# Unresolved means silence, not a guess; the selector exits 3 with a roster.
case "$OUT" in *"unresolved: true"*) exit 0 ;; esac

# Log the triggering text so a wrong route is traceable.
if [ -n "${CB_DIR:-}" ]; then
  mkdir -p "$CB_DIR/telemetry" 2>/dev/null || true
  printf '%s\tprompt=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    "$(printf '%s' "$PROMPT" | tr '\n\t' '  ' | cut -c1-300)" \
    >> "$CB_DIR/telemetry/route-hint.log" 2>/dev/null || true
fi

# A heredoc preserves the parser's own single quotes; a quoted -c block would not.
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
    "Cereblnk routing signal: this request resolves to the AGENT role(s) "
    "%s at gate level %s%s. Those are agents, spawned with the Agent "
    "tool — not skills; passing one to the Skill tool fails with "
    "'Unknown skill'. This is the case cb-dispatch exists for: it owns "
    "the intent table and this hook deliberately does not, so invoke it "
    "before editing files yourself. If the request is a question rather "
    "than work on the codebase, answer it directly and ignore this line."
) % (", ".join(specs), gate, (" (signals: %s)" % "; ".join(why)) if why else "")

print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit", "additionalContext": note}}))
PY
exit 0
