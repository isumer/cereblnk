#!/usr/bin/env bash
# DelegationGuardHook (PreToolUse: Edit|Write|MultiEdit|NotebookEdit)
#
# Enforces, as a MECHANISM, what three PRs of instructions could not:
# while a Cereblnk run is active, file edits belong to surface
# specialist subagents — the conducting conversation never implements.
#
# Decision table (safe under BOTH known platform behaviors):
#   run-active flag absent            -> allow (no run; normal editing)
#   hook input carries agent identity -> allow (a subagent is editing —
#     (top-level agent_id/agent_type)    exactly what delegation wants)
#   flag armed + no agent identity    -> BLOCK (exit 2): the conductor
#                                        tried to implement; stderr
#                                        tells the model to spawn the
#                                        surface specialist instead
# Identity is read from the PARSED hook input's top-level keys — never
# by substring over the raw JSON, because the raw payload contains
# tool_input.content/new_source: any file that merely MENTIONS
# "agent_id" (this hook's own docs, hooks.json, fixtures) would have
# let the conductor through. Found as a planted-bypass in review.
# Old platform versions where subagent tool calls bypass hooks
# entirely are equally safe: those edits never reach this guard.
# Failure semantics, honestly: fail-open only when no project root or
# no armed flag. With a run armed, input whose agent identity cannot
# be determined (unparseable JSON, or no Python — substring fallback
# finding no identity anywhere) is treated as the conductor and
# blocked — conservative for DELEGATION (the model is told exactly how
# to proceed), and it cannot brick a session: it acts only mid-run and
# the escape hatch is the same flag every workflow already manages.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbowner.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0

# Armed state, with staleness bounds on BOTH arming flags (CB-099).
# run-active had none: a flag left behind by an abnormally terminated
# run blocked every conductor edit forever, and the only escape was
# deleting the file by hand — which also removes the protection for the
# NEXT run, and in the reported case the conductor then filled its own
# context, the exact failure this guard exists to prevent. A run is now
# considered live while the flag is recent OR the run ledger is still
# growing; an aged flag with a cold ledger is treated as absent.
# Deliberately an OR: a run resumed after an overnight pause keeps its
# protection as long as it is still writing blocks.
#
# run-active covers the run itself. run-completed covers
# the follow-up window AFTER final synthesis — the seam where the
# dispatch skill's own trap list predicted the failure ("follow-up
# handled freehand because the last workflow finished") while this
# guard was, by trigger scope, switched off. It is TTL-bounded so a
# forgotten flag can never brick a project: past the window it is
# ignored, fail-open, exactly like no flag at all.
# The block must carry its own handoff. A guard that says "delegate"
# without naming the specialist, its skills, and the file leaves the
# model to reconstruct all of it — and the cheapest path out of a block
# is never the one that costs the most work. Computed from the blocked
# path through the same selector the orchestrator uses; silent fallback
# to the generic instruction when anything is unavailable.
# The conductor owns its own control surface. run-discipline §? puts it
# plainly: the conductor holds intent, plan, digests, verdicts and
# synthesis. Blocking it from writing the plan told it to delegate the
# plan to a specialist, which is a category error — and the block
# message said "the conductor holds plan" in the same breath.
#
# The conductor-ownership table lives in scripts/lib/cbowner.sh, because
# the shell path (below) asks the same question about the same files
# and a second copy would drift from the first — which is the defect
# CB-122 fixed. Sourced above with cbenv; if it is missing, every path
# reads as unowned and the guard blocks conductor writes it should
# allow, so the absence is loud rather than silent.

cb_handoff() {
  _p="${CB_BLOCKED_PATH:-}"
  _sel="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/select-agents"
  _out=""
  if [ -n "$_p" ] && [ -x "$_sel" ] && [ -n "${PYBIN:-}" ]; then
    _out="$(bash "$_sel" "$_p" 2>/dev/null || true)"
  fi
  if [ -n "$_out" ]; then
    _role="$(printf '%s' "$_out" | sed -n 's/^  - \([a-z-]*-agent\).*/\1/p' | head -1)"
    _skills="$(printf '%s' "$_out" | sed -n "s/^  ${_role}: \[\(.*\)\].*/\1/p" | head -1)"
  fi
  [ -n "${_role:-}" ] || _role="the surface specialist for this file"
  printf ' NEXT ACTION: spawn %s with a Task Block for %s' "$_role" "${_p:-this edit}"
  [ -n "${_skills:-}" ] && printf ', skills_required: [%s]' "$_skills"
  printf ', and let it write inside its own context.'
}

MODE=""
_active_ttl_h="${CB_ACTIVE_TTL_HOURS:-8}"
_active_cut=$(( _active_ttl_h * 60 ))
_armed=""; _fresh=""
for _f in run-active run-active.nudged; do
  [ -f "$CB_DIR/flags/$_f" ] || continue
  _armed=1
  [ -n "$(find "$CB_DIR/flags" -name "$_f" -mmin "-$_active_cut" 2>/dev/null)" ] && _fresh=1
done
# a live run keeps writing to its ledger; a cold ledger is a dead run
if [ -n "$_armed" ] && [ -z "$_fresh" ] && [ -d "$CB_DIR/context" ]; then
  [ -n "$(find "$CB_DIR/context" -mmin "-$_active_cut" 2>/dev/null | head -1)" ] && _fresh=1
fi
# Human escape hatch. Deliberate, separately named, and absent from
# every model-facing message on purpose: the previous message ended by
# naming the flag to delete, and a blocked model reads the last
# sentence as the instruction. It took the bypass instead of
# delegating. The way out now costs an explicit act by the person.
if [ -f "$CB_DIR/flags/conductor-override" ] && \
   [ -n "$(find "$CB_DIR/flags" -name conductor-override -mmin "-${CB_OVERRIDE_TTL_MIN:-60}" 2>/dev/null)" ]; then
  exit 0
fi

if [ -n "$_armed" ] && [ -n "$_fresh" ]; then
  MODE="active"
elif [ -z "$_armed" ] && [ ! -f "$CB_DIR/flags/run-completed" ] && \
     [ -f "$CB_DIR/flags/run-active.witness" ] && \
     [ -n "$(find "$CB_DIR/flags" -name run-active.witness -mmin "-$_active_cut" 2>/dev/null)" ] && \
     [ -d "$CB_DIR/context" ] && \
     [ -n "$(find "$CB_DIR/context" -mmin "-$_active_cut" 2>/dev/null | head -1)" ]; then
  # The arming flag vanished while the ledger was still being written.
  # A run does not end by deleting its own flag — workflows write
  # run-completed. This is the disarm-and-continue path, observed live.
  MODE="disarmed"
elif [ -f "$CB_DIR/flags/run-completed" ]; then
  _ttl_h="${CB_COMPLETED_TTL_HOURS:-8}"
  _cutoff=$(( _ttl_h * 60 ))
  if [ -n "$(find "$CB_DIR/flags" -name run-completed -mmin "-$_cutoff" 2>/dev/null)" ]; then
    MODE="completed"
  fi
fi
[ -n "$MODE" ] || exit 0

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
  # conductor edit: capture the target so the block can name its owner
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
  # CB-123 — the shell reaches the same files. A Bash call carries no
  # file_path, so without this branch the guard would either wave every
  # command through (the hole a blocked run announced it would use) or
  # block all of them, including the detect-stack / select-agents /
  # run-quiet / git calls run-discipline requires the conductor to make.
  # So: ask what the command writes. Nothing -> allow. Targets the
  # conductor owns -> allow. Anything else, including a write whose
  # target cannot be resolved -> block, on the same terms as an edit.
  CB_SHELL_WRITES=""
  if [ "$(printf '%s' "$INPUT" | $PYBIN -c '
import json, sys
try:
    print((json.load(sys.stdin) or {}).get("tool_name") or "")
except Exception:
    print("")
' 2>/dev/null || true)" = "Bash" ]; then
    _sw="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/shellwrite.py"
    CB_SHELL_WRITES="$(printf '%s' "$INPUT" | $PYBIN "$_sw" 2>/dev/null || true)"
    [ -n "$CB_SHELL_WRITES" ] || exit 0   # a read-only command
    _unowned=""
    while IFS= read -r _t; do
      [ -n "$_t" ] || continue
      cb_is_conductor_owned "$_t" || { _unowned="$_t"; break; }
    done <<EOF
$CB_SHELL_WRITES
EOF
    [ -n "$_unowned" ] || exit 0          # every target is the conductor's own
    CB_BLOCKED_PATH="$_unowned"
    export CB_BLOCKED_PATH
    [ "$CB_BLOCKED_PATH" = "?" ] && CB_BLOCKED_PATH="" && export CB_BLOCKED_PATH
    echo "Cereblnk DelegationGuard: a run is active — this command writes, and file edits belong to the surface specialist subagent (agent-selection-policy §1/§3b), not the conducting conversation. Reaching the file through the shell is the same edit under another tool.$(cb_handoff)" >&2
    exit 2
  fi
  if cb_is_conductor_owned "$CB_BLOCKED_PATH"; then
    exit 0   # the conductor's own plan/state/flags/telemetry
  fi
else
  # Degraded fallback without Python: substring check. Weaker (a file
  # body mentioning the keys passes), but never blocks a legitimate
  # subagent — and cbenv-equipped installs always have PYBIN.
  case "$INPUT" in
    *'"agent_id"'*|*'"agent_type"'*) exit 0 ;;
  esac
  # Without Python the path cannot be extracted cleanly. A conductor
  # blocked from writing its own plan cannot run at all, so this errs
  # toward allowing: a body that merely mentions the plan passes, which
  # is the cheaper mistake.
  case "$INPUT" in
    *cereblnk*plan.md*|*cereblnk*state.md*) exit 0 ;;
  esac
  # The shell branch needs a parser it does not have here. Blocking
  # every command instead would stop the conductor running the scripts
  # run-discipline requires of it, so this path fails open and the
  # shell boundary is simply unenforced without Python. Stated, not
  # implied: cbenv-equipped installs always have PYBIN.
  case "$INPUT" in
    *'"tool_name"'*'"Bash"'*|*'"command"'*) exit 0 ;;
  esac
fi

if [ "$MODE" = "disarmed" ]; then
  echo "Cereblnk DelegationGuard: the run-active flag was removed while the run ledger was still being written. A run ends by completing, not by disarming its own guard. Finish the run through its workflow.$(cb_handoff)" >&2
elif [ "$MODE" = "completed" ]; then
  echo "Cereblnk DelegationGuard: the last run completed — this is a follow-up, and follow-ups re-enter routing at the top (dispatch step 1), they are not handled freehand.$(cb_handoff)" >&2
else
  touch "$CB_DIR/flags/run-active.witness" 2>/dev/null || true
  echo "Cereblnk DelegationGuard: a run is active — file edits belong to the surface specialist subagent (agent-selection-policy §1/§3b), not the conducting conversation. The conductor holds plan, digests, and verdicts only.$(cb_handoff)" >&2
fi
exit 2
