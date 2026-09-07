---
name: cb-catchup
description: Review unacknowledged shipping runs from the Cereblnk review ledger, oldest first, without loading diffs unless requested
---

# /cb-catchup

Catch up on shipping runs the operator has not yet reviewed.

Run this utility in the conductor. Do not spawn subagents or specialists.
Do not re-enter dispatch or another workflow.

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/review-ledger list --unreviewed`.
   If it prints nothing, say there are no unreviewed runs and stop.
2. Parse the ledger fields (`date · run_id · reviewed=no · files=... ·
   summary`). Report `N unreviewed runs since <oldest date>`. Then give
   compact counts by leading directory prefix, such as `M touched plugins/`.
   Ignore `+N more` file-list markers when grouping.
3. Present only the oldest run: its id, date, files, and one-sentence
   summary. Preserve ledger order when dates tie. Offer its commit log or
   diff on request. Do not run `git log` or `git show` by default. Load no
   diff unless the operator asks about that run.
4. Wait for explicit acknowledgement that the run is understood. Only then
   run:

   `${CLAUDE_PLUGIN_ROOT}/scripts/review-ledger mark <run_id>`

   Do not infer acknowledgement from a question or a request for more
   evidence. After marking, present the next oldest run, one at a time.
   This marker flip is the skill's only write.
5. End each response with the number of unreviewed runs still outstanding.

This is a utility report, not a gated workflow. The fixed Decision →
Evidence → Reasoning → Risk → Confidence ending does not apply.
