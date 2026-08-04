---
name: cb-implement
description: Spec-driven build — Planner slices the approved spec, specialists implement, Verifier confirms each slice before the next starts
argument-hint: <spec slug or path under .claude/cereblnk/memory/specs/>
---

# ImplementationWorkflow (/cb-implement)

**Trigger intent:** "build what we designed." Requires an approved spec
from /cb-design; without one, route to /cb-frame → /cb-design.

## Where the work happens (hard rule)

Every slice's file edits, builds, and test runs happen INSIDE the
building specialist's subagent — never in this conversation. This
conversation is the conductor: it holds the plan, slice digests
(≤10 lines each), gate verdicts, and nothing else. It does not open
source files, does not run build/test shells, does not paste diffs.
The rationale is arithmetic, not style. A multi-slice build in the
main conversation accumulates every tool result. Input plus output reserve exceeds the model window. The run then
dies mid-slice. That is the observed failure this rule prevents. It has now happened
  at two different window sizes, so the ceiling is computed at run
  start by `scripts/context-budget`, never quoted from a document.
- **Waves follow the computed budget.** Independent tasks run in
  parallel up to `wave_size`, and the next wave starts only after the
  previous one's digests are in the ledger. A plan wanting more agents
  than one wave allows is split, not run at once.

A context-length error is not retried. Tell the user to run
`/compact`. Then resume from the run ledger (`context/<run>/plan.md` + completed blocks), re-issuing
only the slices without a confirmed verdict.

Before a run of three or more slices, remind the user once, in one
line. Headroom rises via `CLAUDE_CODE_MAX_OUTPUT_TOKENS` (README,
Context Headroom).

## The slice discipline

```
planner-agent: spec → ordered slices (ACP task blocks; acceptance
               criteria lifted from the spec's test matrix)
for each slice, strictly in order:
    surface specialist builds — selected per agent-selection-policy
    §1 + §3b from the slice's domain signals (frontend-agent for UI
    slices, backend-agent for server-side, database-agent for
    schema/query, infra-agent for deployment/pipeline), skill closure
    loaded per §4; a slice built by the wrong specialist or by the
    conductor is a selection violation (VerifierAgent checks)
    qa-agent: slice tests exist and run
    verifier-agent: slice conclusion re-derived from evidence
    ── verdict confirmed → next slice
    ── verdict refuted/weakened/inconclusive → slice returns to its
       specialist with the verdict attached; the NEXT SLICE DOES NOT
       START. A failed verification blocks progression — never
       silently continues.
```

Escalation: any slice touching the always-level-3 list runs gate
level 3 (challenger-agent added) regardless of the spec's overall risk.

## Budgets

Planner 4K · building specialist 8K per slice · QA 6K · Verifier 4K ·
Challenger 4K (when engaged) · Synthesis 6K. A slice that cannot fit
its budget is re-sliced by the planner, not overrun.

## Conduct

Goal-driven loops: each slice's acceptance is executable before code is
written. Simplicity first; surgical changes; every changed line traces
to the spec. Deviations from the spec are surfaced as decisions
("the spec assumed X; reality shows Y") — never silently implemented.

## Durable execution loop (CB-052)

Execution follows `policies/execution-loop-policy.md`:

- **State is the plan file.** Start by running
  `${CLAUDE_PLUGIN_ROOT}/scripts/plan-status <plan>`; resume at the
  first unchecked task. Checkboxes are the source of truth, not this conversation. A
compacted session or a weaker model then resumes correctly. The plan must be `plan-lint`-clean before any task runs.
- **Staleness gate (memory-policy R-4).** Before Task 1: read the
  plan header's `derived_from_spec: <path>@v<N>` and the spec head's
  `spec_version`. Plan behind spec → HALT, both versions named; the
  fix is plan reconstruction, never proceeding. A run that proceeds
  on a stale plan is a protocol violation (VerifierAgent).
- **Fresh executor per task.** Each task goes to a subagent whose
  entire context is that task's text and its declared files. Minimal context, maximal structure. This is the weak-model lever:
  the plan supplies what the model would otherwise have to infer.
- **Staged review, risk-proportional.** Stage 1 checks spec
  compliance: does the diff do exactly the task? Stage 2 checks
  quality. Stage 3 runs for high tasks (challenger-agent attacks the
  implementation). A failed review returns to a FRESH executor with the
  review attached, never the context that just failed.
- **Verify, then commit.** Run the task's `verify:` line. Only on
  pass, check the box and commit. One commit per task.
- **Stop-rule.** Two consecutive failures on one task means stop. The
  plan is wrong. Route that task back to the planner. No third attempt in a
  fresh context.
- **Input intake (input-policy §3).** At every task boundary, before
  starting the next task: run `scripts/run-status`. A nonzero
  *blocking* count halts the loop — corrections fold into the plan via
  reconstruction, invalidations surface as REWORK. Clarifications are
  answered and closed; they never hold the loop. Reclassifying an
  entry downward to keep moving is a violation, not a judgment call.
- **Recomposition.** After the last task, run the header's
  `recomposition_check`, then synthesize.

## Output

Per-slice progress: exactly one fixed-format line pair per task
boundary, with no prose between them.

```
[k/N] ✓|✗ <agent> · <slice title> · verify: pass|fail · calls=M
      → next: <agent> · <slice title>
```

Free-form progress narration is Part II trap #4 (volume burying the
finding); the format is the rule, not a suggestion. Build and test
shells inside executors run through `scripts/run-quiet`
(run-discipline §7); the `calls=M` field is the §9 ceiling made
visible.

Final synthesis in fixed order. DECISION is what shipped, slice by
slice. EVIDENCE is test runs and verifier verdicts. Then REASONING,
then RISK, covering deviations, assumptions, deferred slices)
→ CONFIDENCE.

## Execution discipline

`policies/run-discipline.md` binds this run in full — ledger +
digests, conductor-context budget, synchronous stages, path
anchoring, flag lifecycle, context-error recovery.

## Run flag (RunGuardHook wiring)

Arm at execution start:
`mkdir -p "$CB_DIR/flags" && touch "$CB_DIR/flags/run-active"`.
Here `$CB_DIR` is `<project root>/.claude/cereblnk`.
Remove it before ANY turn that ends awaiting the user.
Remove it at final synthesis.
Full lifecycle semantics live in `policies/run-discipline.md` §5.
That is the authoritative copy. This section does not restate it.
