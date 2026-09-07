#!/usr/bin/env bash
# DelegationGuardHook: IDLE allows, COMPLETED routes source, and ARMED blocks conductor edits.
# Parse top-level identity: raw checks once let content mentioning `agent_id` bypass it.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbowner.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ "$(type -t cb_run_state 2>/dev/null || true)" = "function" ] || exit 0

# COMPLETED routes only repository source; block messages compute a concrete handoff.
# CB-122: edit and shell ownership drifted, so both source cbowner; its absence is loud.

cb_handoff() {
  _p="${CB_BLOCKED_PATH:-}"
  _sel="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/select-agents"
  _out=""
  if [ -n "$_p" ] && [ -x "$_sel" ] && [ -n "${PYBIN:-}" ]; then
    _out="$(bash "$_sel" "$_p" 2>/dev/null || true)"
  fi
  if [ -n "$_out" ]; then
    # CB-132: a bare role caused four failed spawns; keep the qualified API name.
    _role="$(printf '%s' "$_out" | sed -n 's/^  - \([a-z:-]*-agent\).*/\1/p' | head -1)"
    _skills="$(printf '%s' "$_out" | sed -n "s/^  ${_role}: \[\(.*\)\].*/\1/p" | head -1)"
  fi
  [ -n "${_role:-}" ] || _role="the surface specialist for this file"
  printf ' NEXT ACTION: spawn %s with a Task Block for %s' "$_role" "${_p:-this edit}"
  [ -n "${_skills:-}" ] && printf ', skills_required: [%s]' "$_skills"
  printf ', and let it write inside its own context.'
}

# Keep the human-only override out of model messages: naming it previously
# taught a blocked model to bypass delegation.
if [ -f "$CB_DIR/flags/conductor-override" ] && \
   [ -n "$(find "$CB_DIR/flags" -name conductor-override -mmin "-${CB_OVERRIDE_TTL_MIN:-60}" 2>/dev/null)" ]; then
  exit 0
fi

INPUT="$(cat 2>/dev/null || true)"
if [ -n "${PYBIN:-}" ]; then
  if printf '%s' "$INPUT" | $PYBIN -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(3)  # unparseable while armed: treat as conductor
sys.exit(0 if isinstance(d, dict) and ("agent_id" in d or "agent_type" in d) else 3)
'; then
    exit 0   # subagent editing: allowed
  fi
  CB_BLOCKED_PATH="$(printf '%s' "$INPUT" | $PYBIN -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
ti = d.get("tool_input") or {}
for k in ("file_path", "path", "notebook_path"):
    v = ti.get(k)
    if isinstance(v, str) and v.strip():
        print(v.strip())
        break
' 2>/dev/null || true)"
  export CB_BLOCKED_PATH
  # CB-123: Bash carries no file_path, and a blocked run announced this bypass.
  # Parse writes; allow read-only/owned targets and block unresolved/unowned ones.
  CB_SHELL_WRITES=""
  if [ "$(printf '%s' "$INPUT" | $PYBIN -c '
import json, sys
try:
    print((json.load(sys.stdin) or {}).get("tool_name") or "")
except Exception:
    print("")
' 2>/dev/null || true)" = "Bash" ]; then
    RUN_STATE="$(cb_run_state)"
    [ "$RUN_STATE" != "IDLE" ] || exit 0
    _sw="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/shellwrite.py"
    CB_SHELL_WRITES="$(printf '%s' "$INPUT" | $PYBIN "$_sw" 2>/dev/null || true)"
    [ -n "$CB_SHELL_WRITES" ] || exit 0   # a read-only command
    _unowned=""
    while IFS= read -r _t; do
      [ -n "$_t" ] || continue
      cb_is_conductor_owned "$_t" && continue
      if [ "$RUN_STATE" = "COMPLETED" ]; then
        # An unresolved shell target is not proof of a source-tree write.
        [ "$_t" = "!" ] || [ "$_t" = "?" ] || cb_is_repo_source "$_t" || continue
      fi
      _unowned="$_t"; break
    done <<EOF
$CB_SHELL_WRITES
EOF
    [ -n "$_unowned" ] || exit 0          # every target is the conductor's own
    if [ "$_unowned" = "!" ]; then
      # An unparseable command is unknown, not a known write to an unowned target.
      echo "Cereblnk DelegationGuard: a run is active — this command could not be parsed, so whether it writes is unknown. NEXT ACTION: simplify or split the command so it can be parsed, then retry." >&2
      exit 2
    fi
    CB_BLOCKED_PATH="$_unowned"
    export CB_BLOCKED_PATH
    [ "$CB_BLOCKED_PATH" = "?" ] && CB_BLOCKED_PATH="" && export CB_BLOCKED_PATH
    if [ "$RUN_STATE" = "COMPLETED" ]; then
      echo "Cereblnk DelegationGuard: the last run completed — this is a follow-up, and follow-ups re-enter routing at the top (dispatch step 1), they are not handled freehand.$(cb_handoff)" >&2
    else
      echo "Cereblnk DelegationGuard: a run is active — this command writes, and file edits belong to the surface specialist subagent (agent-selection-policy §1/§3b), not the conducting conversation. Reaching the file through the shell is the same edit under another tool.$(cb_handoff)" >&2
    fi
    exit 2
  fi
  RUN_STATE="$(cb_run_state)"
  [ "$RUN_STATE" != "IDLE" ] || exit 0
  if cb_is_conductor_owned "$CB_BLOCKED_PATH"; then
    exit 0   # the conductor's own plan/state/flags/telemetry
  fi
  if [ "$RUN_STATE" = "COMPLETED" ] && ! cb_is_repo_source "$CB_BLOCKED_PATH"; then
    exit 0   # follow-up routing owns repository source, not control notes or scratch
  fi
else
  # Without Python, substring identity checks can be bypassed by file content;
  # installed environments normally provide PYBIN.
  case "$INPUT" in
    *'"agent_id"'*|*'"agent_type"'*) exit 0 ;;
  esac
  RUN_STATE="$(cb_run_state)"
  [ "$RUN_STATE" = "ARMED" ] || exit 0
  # Path extraction is unavailable, so plan mentions fail open to avoid deadlock.
  case "$INPUT" in
    *cereblnk*plan.md*|*cereblnk*state.md*) exit 0 ;;
  esac
  # Shell writes are unenforced without Python; blocking all Bash would prevent
  # required conductor scripts, so this rejected fallback fails open.
  case "$INPUT" in
    *'"tool_name"'*'"Bash"'*|*'"command"'*) exit 0 ;;
  esac
fi

if [ "$RUN_STATE" = "COMPLETED" ]; then
  echo "Cereblnk DelegationGuard: the last run completed — this is a follow-up, and follow-ups re-enter routing at the top (dispatch step 1), they are not handled freehand.$(cb_handoff)" >&2
else
  touch "$CB_DIR/flags/run-active.witness" 2>/dev/null || true
  echo "Cereblnk DelegationGuard: a run is active — file edits belong to the surface specialist subagent (agent-selection-policy §1/§3b), not the conducting conversation. The conductor holds plan, digests, and verdicts only.$(cb_handoff)" >&2
fi
exit 2
