#!/usr/bin/env bash
# SessionBootstrapHook (SessionStart) — CB-146, observation only.
#
# A session opens knowing nothing about the run it may be resuming. The
# orchestrator is told to check `context/<run_id>/plan.md` before
# planning, and being told is a D-class guarantee: it holds while the
# model remembers. SessionStart's stdout is injected as context before
# the first prompt, which is the one place that instruction can be
# replaced with a fact.
#
# Three states it reports, all read off disk:
#
#   a plan with unconfirmed tasks   this is a resume, and which task is next
#   an armed flag with no ledger    a run died mid-flight and left its
#                                   guard armed; delegation-guard will
#                                   refuse edits for a run that no longer
#                                   exists
#   nothing                         silence
#
# It reports the stale flag rather than clearing it. A hook that quietly
# removes a guard is a hook that can disarm the platform by being wrong
# once, and the cost of being wrong in the other direction is one line of
# text.
#
# It does not read the `source` field. Distinguishing startup from clear
# is unreliable — at least one host reports `startup` after a clear, so a
# matcher on it never fires there — and disk state answers the question
# the source field was going to be used to guess at.
#
# Never blocks. SessionStart cannot refuse anything on any bound host, and
# a bootstrap that errors must not be the first thing a user sees.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0

RUN="$(ls -1dt "$CB_DIR"/context/*/ 2>/dev/null | head -1)"
FLAG="$CB_DIR/flags/run-active"

# nothing to say
[ -n "$RUN" ] || [ -f "$FLAG" ] || exit 0

if [ -n "$RUN" ] && [ -f "$RUN/plan.md" ]; then
  BLOCKS="$(ls -1 "$RUN"/*.yaml 2>/dev/null | wc -l | tr -d ' ')"
  RUN_ID="$(basename "$RUN")"
  if [ -f "$FLAG" ]; then
    printf 'Cereblnk: run %s is active with %s response block(s) on disk. This session is a resume — reconcile %s/plan.md against the ledger and re-issue only the tasks without a completed block, never the whole graph.\n' \
      "$RUN_ID" "$BLOCKS" "$RUN"
  else
    printf 'Cereblnk: run %s left %s response block(s) on disk and its run-active flag is down, so the last run completed or was disarmed. A follow-up re-enters routing at the top rather than continuing that graph.\n' \
      "$RUN_ID" "$BLOCKS"
  fi
  exit 0
fi

if [ -f "$FLAG" ]; then
  printf 'Cereblnk: the run-active flag is armed but no run ledger exists under %s/context/. A run ended without completing, and DelegationGuard will refuse conductor edits until this is resolved. Finish the run through its workflow, or remove flags/run-active deliberately.\n' \
    "$CB_DIR"
fi

exit 0
