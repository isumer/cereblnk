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
# shellcheck source=../lib/hostio.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/hostio.sh" 2>/dev/null || true
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
# Exempt, because the conductor writes these BY DEFINITION:
#   $CB_DIR/state.md                  run state
#   $CB_DIR/context/<run>/plan.md     the plan
#   $CB_DIR/flags/*                   run lifecycle flags
#   $CB_DIR/telemetry/*               run summaries
#
# NOT exempt, and deliberately so:
#   $CB_DIR/context/<run>/<task>.yaml a subagent's Response Block — a
#                                     conductor writing one is
#                                     fabricating a specialist's output
#   $CB_DIR/memory/**                 promoted knowledge and authored
#                                     deliverables have their own owners
#
# Separators are normalised: the path arrives as the platform wrote it,
# and on Windows that means backslashes.
cb_is_conductor_owned() {
  [ -n "${1:-}" ] || return 1
  _n="$(printf '%s' "$1" | tr '\\' '/')"
  case "$_n" in
    */cereblnk/context/*/[Pp]lan.md) return 0 ;;
    */cereblnk/state.md)             return 0 ;;
    */cereblnk/flags/*)              return 0 ;;
    */cereblnk/telemetry/*)          return 0 ;;
  esac
  return 1
}

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
fi

if [ "$MODE" = "disarmed" ]; then
  CB_REASON="Cereblnk DelegationGuard: the run-active flag was removed while the run ledger was still being written. A run ends by completing, not by disarming its own guard. Finish the run through its workflow.$(cb_handoff)"
elif [ "$MODE" = "completed" ]; then
  CB_REASON="Cereblnk DelegationGuard: the last run completed — this is a follow-up, and follow-ups re-enter routing at the top (dispatch step 1), they are not handled freehand.$(cb_handoff)"
else
  touch "$CB_DIR/flags/run-active.witness" 2>/dev/null || true
  CB_REASON="Cereblnk DelegationGuard: a run is active — file edits belong to the surface specialist subagent (agent-selection-policy §1/§3b), not the conducting conversation. The conductor holds plan, digests, and verdicts only.$(cb_handoff)"
fi
cb_block "$CB_REASON"
