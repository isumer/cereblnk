---
name: cb-resume
description: Resume the currently pinned incomplete Cereblnk run from its on-disk plan, re-arming the same run id and continuing at the first unchecked task
---

# /cb-resume

Resume a crashed or interrupted run from its ledger. This is recovery,
not a new workflow. Do not dispatch or allocate a new run id. Never repeat
checked work.

1. Read the first line of `$CB_DIR/flags/run-active`. It must be a bare run
   id with a matching `$CB_DIR/context/<run_id>/`. Otherwise, stop and
   report no pinned live run. This includes an absent or malformed flag,
   a dead pin, and an archived run. Never guess the newest directory.
2. Require `$CB_DIR/context/<run_id>/plan.md`, then run:

   `${CLAUDE_PLUGIN_ROOT}/scripts/plan-status "$CB_DIR/context/<run_id>/plan.md"`

   The plan checkboxes are the source of truth. Stop if `plan-status`
   reports no tasks. This entry point cannot reconstruct a plan-less run.
3. Re-arm the validated same id with
   `${CLAUDE_PLUGIN_ROOT}/scripts/run-flag arm "" <run_id>`. This is the
   CB-171 idempotent resume path. A non-zero exit blocks recovery. Do not
   replace the pin or create a run.
4. Read the plan and the evidence needed to reconcile it. That includes
   existing Response Blocks and gate verdicts. Continue the original
   workflow at `plan-status`'s first unchecked task. Never redo a checked
   task. Apply `policies/execution-loop-policy.md` and the plan's workflow.
   Never infer an unresolved or failed gate from conversation history.
5. If every task is checked, run the plan's recomposition check. Then run
   required final gates and synthesis. Apply the workflow's post-synthesis
   **Anything to improve or fix?** gate. Only an operator answer of no
   permits `run-flag complete`, which archives the run.

Before continuing, report the run id and `plan-status` progress. Name the
task being resumed. Recovery changes durable state only by continuing that
same run.
