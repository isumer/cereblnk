# Orchestration Loop

> Binding. The five stages of a full-pipeline run, read by the
> `cb-orchestrate` entry point at Step 3 and by any workflow that
> conducts a medium- or high-risk run.
>
> This text lived inside `skills/orchestrate/SKILL.md` until CB-129.
> It was moved, not rewritten: an adjacent host caps a skill file at
> 8 KB, and the orchestrator was the one file in the tree that inlined
> what everything else references. Nothing here is new, and nothing was
> dropped in the move.

## The five stages

1. **Plan** — invoke the `planner-agent` subagent with one ACP Task
   Block (template: `protocols/acp-task-block.template.yaml`). It
   returns a Task Graph of ACP task blocks, each with a testable
   acceptance criterion and a budget from `policies/budget-policy.md`.
   The Planner also writes the graph to
   `$CB_DIR/context/<run_id>/plan.md` (run plan file). Before planning, check that path. A plan already there means the run
is a resume. Reconcile against the Response Blocks already
   in the ledger and re-issue only the tasks without a completed
   block, never the whole graph.
2. **Execute.** Spawn the assigned specialist subagents, independent
tasks in parallel — up to the `wave_size` returned by
`${CLAUDE_PLUGIN_ROOT}/scripts/context-budget` at run start. More
agents than one wave allows are split across waves, and the next wave
starts only once the previous one's digests are in the ledger.
Synchronously: never background a gate-bearing run. A backgrounded agent's completion does not wake this
   conversation, its result waits for the user's next message and the
   run stalls. On execution start create `$CB_DIR/flags/run-active`. That arms
RunGuardHook's single continue-nudge. Remove it before asking the
user anything and at synthesis — a question asked while
   armed turns the nudge into noise. Specialist choice and skill sets follow
`policies/agent-selection-policy.md`. See §1 for signals, §2 for the
union, §4 for relations closure, §4c for task-scoped skills.
   **Skills are resolved per task, never assumed.** At run start run
`${CLAUDE_PLUGIN_ROOT}/scripts/detect-stack` once, then
`${CLAUDE_PLUGIN_ROOT}/scripts/select-agents` with the changed paths,
or `--text "<the request>"` when nothing has changed yet. Copy its
`skills_required` block verbatim to
`$CB_DIR/context/<run_id>/skills-required.yaml` and write each role's
list into that role's Task Block. Exit 3 means unresolved: supply
`--text` or name the surface. Never route on a silent default. the same tables the dispatch skill routes
   by, so command-invoked and dispatch-invoked runs select identically.
   **File-mediated ACP, the context ledger.** Every subagent writes its
full Response Block to `$CB_DIR/context/<run_id>/<task_id>.yaml`. It then returns a digest of at most ten lines, and nothing else.
That digest carries task_id, role, status, a one-sentence decision,
and fact counts per label, unknown and risk counts, confidence, and the block's
   file path. You keep digests; the disk keeps blocks. Never re-quote a full block into this conversation. Gate agents
receive the file path in their Task Block. They read it inside their
own context. Each receives exactly one Task Block and only the
   context refs listed in it. Never paste raw conversation
   history or whole-repo content into a subagent prompt.
3. **Enforce ACP** — run the ordered checklist
   `${CLAUDE_PLUGIN_ROOT}/policies/acp-validation-checklist.md`
   (V1–V9) on EVERY incoming block. On violation: discard the block
   and re-issue the task once, citing the specific checklist item
   (e.g. "V2: fact without label"). Second violation on the same
   task → return to Planner as `blocked` with the violation history.
   Never patch a malformed block yourself — repair is the producing
   agent's job.
4. **Gate** — per `policies/gate-policy.md`: level 2 → `verifier-agent`
   + consistency check; level 3 → also `challenger-agent`, mandatory.
   Then apply the gate-completeness rule of
`policies/acp-validation-checklist.md`. No synthesis is composed while any required verdict is missing or
failed. A missing Challenger block at level 3 is a failed gate. Never
a waivable one.
   `refuted` → back to planning; `inconclusive` → evidence request;
   contradictions → consensus-policy §3, synthesis stays blocked until
   the prescribed re-verification completes.
5. **Synthesize** — invoke `synthesizer-agent` with the merged, labeled
   fact set and gate verdicts. Relay its Synthesis Block to the user
   unchanged. Do not relay a synthesis missing required gate verdicts.
