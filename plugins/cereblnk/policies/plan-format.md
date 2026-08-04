# Plan Format Policy

Class: M (the linter + status scripts) + D (this format). The plan is
the durable, crash-recoverable execution artifact — the mechanism that
lets a weaker executor (or a compacted session) resume correctly:
**state lives in the file's checkboxes, never in the conversation.**
Consumed by PlannerAgent (emits it), `/cb-implement` (executes it),
`plan-lint` (refuses malformed plans), `plan-status` (reports state).

## 1. Location and lifecycle

`.claude/cereblnk/memory/plans/<slug>-<date>.md`, committed. One commit per
completed task (task title as message), plan + code together. A task is
done ONLY when its checkbox is `[x]` AND its commit exists.

## 2. Header (linter-enforced — all fields required)

```markdown
# Plan: <slug>
- spec: .claude/cereblnk/memory/specs/<slug>-<date>.md   # or requirements/… ; the source of truth
#        a direct run (/cb-do) has no spec: write `none — direct request (/cb-do)`
- goal: <one sentence>
- out_of_scope: <explicit list — scope creep is measured against this>
- recomposition_check: <the ONE end-to-end command run after all tasks pass>
```

## 3. Task format (linter-enforced)

```markdown
### [ ] Task N: <imperative title>
- risk: HIGH | MED | LOW — <one-line why, from the domain risk maps>
- files: exact/path/One.java, exact/path/Two.sql
- verify: <executable check or concrete observable — `mvn test -Dtest=X`,
           "endpoint returns 409 on duplicate"; NOT "code compiles">
- rollback: <REQUIRED if the task touches persistent data or is otherwise
             destructive; omit only for non-destructive tasks>

<complete code / SQL / config — no placeholders, no "similar to above">
```

## 4. Rules the linter enforces (exit 1, violation named)

- **R1** every task has a `verify:` line (the verification seam).
- **R2** every task whose `files:` or body signals persistent-data /
  destructive change has a `rollback:` line.
- **R3** no placeholder markers anywhere: `TODO`, `...`, "similar to",
  "same as above", "implement similarly".
- **R4** header has all four fields (spec, goal, out_of_scope,
  recomposition_check).
- **R5** every task has a `risk:` rank (HIGH/MED/LOW).
- **R6** `verify:` is not a compile-only check ("compiles", "builds"
  alone are rejected — name the behavior).

## 5. Rules that are D-class (checker = agent, not script)

- Risk ranking REORDERS execution: the highest-risk *verifiable* task
  runs early, so a fatal assumption fails on task 2, not task 12.
  Dependency order is kept only where it genuinely binds, and noted.
  **Checker:** PlannerAgent applies it; VerifierAgent confirms the
  ordering rationale exists.
- Sizing: one task = one sitting for a context-free executor (~2–5 min,
  code section under ~80 lines). Two tasks verifiable only together are
  one task. **Checker:** PlannerAgent; oversize tasks are re-split.
- Every `verify:` is a *real* check. **Checker:** VerifierAgent
  re-derives that the check actually fails when the behavior is absent.

## 6. Why file-based (the weak-model lever)

A plan held in conversation dies with the session and cannot be handed
to a fresh, minimal-context executor. A plan on disk with checkbox
state means: (a) any model can resume via `plan-status` after
compaction; (b) each task can be dispatched to a fresh executor whose
entire world is that one task's text — minimal context, maximal
structure, which is exactly what lets a weaker model match a stronger
one's workflow.
