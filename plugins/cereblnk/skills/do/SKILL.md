---
name: cb-do
description: Direct execution — analyses the request, selects specialists, and builds through subagents. No spec, no design phase, no plan to approve.
argument-hint: <what you want built, in a sentence or two>
---

# DirectExecutionWorkflow (/cb-do)

**Trigger intent:** "build this." A request, not a spec.

`/cb-implement` consumes an approved spec. This one consumes a
sentence. Everything after the entry is identical: fresh executor per
task, staged review, verify before commit.

## Where the work happens (hard rule)

Every file edit, build, and test run happens inside a specialist
subagent. Never in this conversation. This conversation holds the task
list, digests, and verdicts. It does not open source files. It does
not run build shells. It does not paste diffs.

The reason is arithmetic. A multi-task build in the main conversation
accumulates every tool result. The window fills. The run dies mid-task.
DelegationGuard blocks the edit that would start it.

## Step 1 — Read the request

Read it three ways. Literal: the words. Operational: the job being
done. Constraint: what makes it risky or urgent.

Two readings survive? Ask one question. Then proceed.

## Step 2 — Arm the run flag

Arm at start with this run's id:
`${CLAUDE_PLUGIN_ROOT}/scripts/run-flag arm "" R-YYYY-MM-DD-NNN`.
The id is what every run-reading hook resolves against; without it they
fall back to guessing the newest context directory (CB-147, F-31).
Remove it before any turn that ends awaiting the user. Do not complete
the run at first synthesis; the acceptance gate below decides that.
Full semantics live in `policies/run-discipline.md` §5.

## Step 3 — Select the surface

Run both scripts. Do not reason the routing table by hand.

```
${CLAUDE_PLUGIN_ROOT}/scripts/detect-stack
${CLAUDE_PLUGIN_ROOT}/scripts/select-agents --emit-floor --text "<the request>"
```

Take `specialists` and `gate_level`. `--emit-floor` writes the skill
floor to `context/<run_id>/skills-required.yaml` and the mandated roster
to `agents-required.yaml`. The Task Block points at the skill file
rather than restating it; the plan assigns or explicitly merges every
agent in the roster. Exit 3
means unresolved: the output is the roster, not a specialist. Pick
a role from it and cite the roster line your choice rests on.
Never guess one agent.

## Step 4 — Stop only where the work is irreversible

Risk raises the gate. It does not stop the run. One class does stop
it: work that cannot be undone by editing code again.

| Signal | Action |
|---|---|
| schema migration, data deletion, retention change | confirm, one line, before Task 1 |
| production configuration, credentials, access rules | confirm, one line, before Task 1 |
| money movement, billing, external charges | confirm, one line, before Task 1 |
| everything else at gate level 3 | continue; challenger stage engaged |

The confirmation names what cannot be undone. It is not a risk
warning. A user who wanted a design phase would have asked for one.

## Step 5 — Shape the work

Count the tasks first.

- **One task.** No plan file. Dispatch the executor. Verify. Commit.
- **Two or more.** Write the task list to
  `$CB_DIR/context/<run_id>/plan.md` and start. Do not present it for
  approval. The user asked for work, not a planning phase.

The plan file is not ceremony. It is how the run survives compaction,
and it is what each fresh executor receives. Header for a direct run:

```
- spec: none — direct request (/cb-do)
- goal: <one sentence, from the request>
- out_of_scope: <what this run will not touch>
- recomposition_check: <the one end-to-end command run at the end>
```

Every task carries a `verify:` line that names a behaviour. The
`- agent:` line names its lead and any reviewers. Every specialist in
`context/<run_id>/agents-required.yaml` must appear on one of those task
lines. If one specialist's work is genuinely covered by another, record
one waiver per specialist in the plan header, with a non-empty reason:

```
merged: <missing-agent> into <covering-agent> because <reason text>
```

Run `${CLAUDE_PLUGIN_ROOT}/scripts/plan-lint <plan.md>` before Task 1;
an unassigned and unwaived mandated specialist blocks execution. The
staleness gate does not apply: there is no spec to drift from.

## Step 6 — Execute

`policies/execution-loop-policy.md` binds this run in full. Fresh
executor per task. Stage 1 checks request compliance: does the diff do
exactly what was asked, nothing missing, nothing extra. Stage 2 checks
quality against the surface gates. Stage 3 runs on high-risk tasks
only. A failed review returns to a new executor, never the one that
failed. Two consecutive failures on one task stop the run.

Waves follow `scripts/context-budget`. Independent tasks run in
parallel up to `wave_size`.

## Budgets

Executor 8K per task · reviewer 4K · challenger 4K · synthesis 6K. A
task that will not fit is split, not overrun.

## Output

One line pair per task boundary. No prose between them.

```
[k/N] ✓|✗ <agent> · <task title> · verify: pass|fail · calls=M
      → next: <agent> · <task title>
```

Final synthesis in fixed order: Decision, Evidence, Reasoning, Risk,
Confidence. Decision states what shipped. Risk covers what was
assumed, and what the absent spec would have pinned down.

## Post-synthesis acceptance

After every synthesis, disarm before asking the operator: **Anything to
improve or fix?** A yes keeps `context/<run_id>/` live: re-arm the same
id, run the improvement through the workflow and its gates, synthesize,
then ask again. Only a no calls `scripts/run-flag complete`; completion
hands off `run-completed` and archives the run.

## When not to use this

- The work already has a spec → `/cb-implement`
- The request is a question, not a build → answer it
- The shape is genuinely unclear after Step 1 → `/cb-frame`
- A diff already exists and needs judgment → `/cb-pr-review`

A vague request does not become clear by being executed faster.
