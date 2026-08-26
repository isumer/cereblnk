#!/usr/bin/env bash
# RunGuardHook (Stop) — bounded, progress-aware continuation.
#
# A workflow whose subagent result lands between turns leaves the
# session idle. This nudges it, but only while the run demonstrably
# progresses:
#   - progress metric: Response Block count in the pinned run dir
#   - up to MAX_NUDGES, and each nudge after the first requires the
#     count to have GROWN since the previous one
#   - no growth, or cap reached -> disarm (rename to .nudged) and allow
#     the stop
#
# The message names three cases and attaches the disarm advice to the
# one where disarming is correct. No host signal reports a live
# subagent, so it must not assume which case it is in.
#
# Loop safety, in order:
#   1. stop_hook_active true in stdin -> always allow the stop.
#   2. State is keyed to the run dir, so a stale file never
#      insta-disarms a fresh run.
#   3. Progress requirement is strictly monotonic; equal counts disarm.
#   4. Hard cap MAX_NUDGES; then disarm.
#   5. Fail open on every error path.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0

FLAG="$CB_DIR/flags/run-active"
STATE="$CB_DIR/flags/run-active.state"
MAX_NUDGES=3
[ -f "$FLAG" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

# progress metric from the newest run ledger
NEWEST="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
BLOCKS=0; TASKS=0; PENDING=""
if [ -n "$NEWEST" ]; then
  # Response Blocks only; the run's own inputs are not progress.
  BLOCKS=$(ls -1 "$NEWEST"*.yaml 2>/dev/null \
    | grep -Ev '/(skills-required|stack-profile|plan)\.yaml$' \
    | wc -l | tr -cd '0-9'); BLOCKS=${BLOCKS:-0}
  if [ -f "$NEWEST/plan.md" ]; then
    TASKS=$(grep -c "task_id" "$NEWEST/plan.md" 2>/dev/null | tr -cd '0-9'); TASKS=${TASKS:-0}
    PENDING=" ($BLOCKS/$TASKS task blocks on disk in ${NEWEST#$CB_DIR/})"
  fi
fi

COUNT=0; LAST=-1; RUNKEY="${NEWEST:-none}"
if [ -f "$STATE" ]; then
  # state format: <count> <last_block_count> <runkey>
  read -r COUNT LAST SAVEDKEY < "$STATE" 2>/dev/null || { COUNT=0; LAST=-1; SAVEDKEY=""; }
  [ "$SAVEDKEY" = "$RUNKEY" ] || { COUNT=0; LAST=-1; }   # different run: reset
fi

if [ "$COUNT" -ge "$MAX_NUDGES" ] || { [ "$COUNT" -gt 0 ] && [ "$BLOCKS" -le "$LAST" ]; }; then
  # cap reached, or no progress since the previous nudge: stop looping
  mv -f "$FLAG" "$FLAG.nudged" 2>/dev/null || rm -f "$FLAG" 2>/dev/null
  rm -f "$STATE" 2>/dev/null
  exit 0
fi

COUNT=$((COUNT+1))
printf '%s %s %s\n' "$COUNT" "$BLOCKS" "$RUNKEY" > "$STATE" 2>/dev/null || true
printf '{"decision":"block","reason":"A Cereblnk run is still active%s — continue nudge %s/%s. Three cases, and they are not the same. SPECIALISTS STILL OUT: this nudge is informational — do NOT disarm, the flag is what judges them when they return, and waiting is the normal state of a multi-agent run. WAITING ON THE USER: disarm first (scripts/run-flag disarm), then ask. NEITHER: reconcile the run ledger (plan.md vs Response Blocks), execute the NEXT unconfirmed task, then gates and synthesis. Nudges continue only while the ledger grows."}\n' "$PENDING" "$COUNT" "$MAX_NUDGES"
exit 0
