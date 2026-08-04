# Execution Loop Policy

Class: D — the per-task execution cycle for `/cb-implement`, with named
checkers. This is the durable, staged-review loop that lets a
minimal-context (weaker) executor produce strong-model-quality results:
the structure carries what the model would otherwise have to supply.

## 1. State discipline (the crash-survival rule)

The plan file's checkboxes are the SINGLE source of truth — not the
conversation, not the orchestrator's memory. **Checker:** `plan-status`.

- Before starting: run
  `${CLAUDE_PLUGIN_ROOT}/scripts/plan-status <plan>` to find the first
  unchecked task and the remaining risk profile.
- A task is done ONLY when `[x]` AND a commit exist (one commit per
  task, task title as message, plan + code together).
- Resume after a dead session/compaction via `plan-status`; NEVER redo
  a checked task; NEVER trust memory over the file.

## 1b. Spec-less runs (/cb-do)

A direct run has no spec, so two rules change and nothing else does.

- The header records `spec: none — direct request (/cb-do)`. The field
  stays present, because the plan format is what `plan-status` and
  `plan-lint` read.
- The staleness gate is skipped. There is no spec version to fall
  behind. Everything it protected against — a plan describing an older
  design — cannot occur when the plan was written from the request in
  the same run.

What does NOT change: the plan file still exists for runs of two or
more tasks, checkboxes are still the source of truth, and the
fresh-executor rule still holds. Dropping the spec is cheap. Dropping
the plan would remove the crash-survival mechanism and the minimal
context each executor depends on. **Checker:** `plan-lint` for the
header, `plan-status` for resume, VerifierAgent for the staged reviews.

## 2. Per-task cycle

```
dispatch a FRESH executor subagent
  → the task's text is its ENTIRE context (minimal context, maximal
    structure — the weak-model lever). No conversation history, no
    whole-repo dump; only the task block + its declared files.
STAGE 1 — spec-compliance review (verifier-agent or code review):
  does the diff do EXACTLY the task — nothing missing, nothing extra?
  (spec compliance FIRST: right-thing-ugly is a refactor; wrong-thing-
   beautiful is a total loss.)
  ── fail → back to a FRESH executor with the review attached
STAGE 2 — quality review: false-competence hunt + the domain
  gates for the task's surface (from agent-selection-policy.md).
  ── fail → fresh executor + review
STAGE 3 — risk-proportional (HIGH tasks only): challenger-agent
  attacks the implementation (adversarial input, concurrent
  interleaving, the boundary the code assumed away).
  ── BREAKS → fresh executor + the counter-scenario
run the task's `verify:` line — the executable check from the plan.
  ── fail → see stop-rule
check the box + commit → next task.
```

**Checker:** orchestrator gate-completeness (CB-043) — no task is
checked without its required stages for its risk; VerifierAgent
confirms the staged reviews actually ran.

## 3. The fresh-executor rule

A failed review NEVER returns to the context that produced the failure
— that context defends its work instead of fixing it. It returns to a
NEW executor with the review attached. This is also why the executor
gets minimal context: a fresh, task-only context is cheap to spawn and
free of the previous attempt's rationalizations.

## 4. Stop-rule (execution twin of the /cb-bug 3-strike rule)

TWO consecutive failures on the SAME task = the plan is wrong, not the
executor. STOP. Return that task to the Planner (`/cb-implement` routes
back to planning for a re-slice) with what was learned. Grinding a
third attempt in a fresh context is prohibited — a "2-minute task"
failing twice is a planning signal, not an effort signal.

## 5. Cadence and scope

- Pause for the user after each HIGH-risk task and at natural
  boundaries (schema applied, endpoint live). LOW/MED tasks may run in
  batches of 3–5. The user may change cadence ("run it all, ping at the
  end") — comply, but still stop on any `verify:` failure or Stage-3
  BREAKS.
- Every mid-execution "while we're here, also…" is checked against the
  plan's `out_of_scope`. In scope → it was a missing task; add it via
  the planner with its own Verify line. Out of scope → decline, cite
  the list, note it for the next requirements/frame pass.

## 6. Recomposition

After the last task: run the plan header's `recomposition_check` (the
one end-to-end command — pieces prove the parts, this proves the
joins). Then the SynthesizerAgent five-question self-test,
then report answer→evidence→reasoning→risk→confidence.
