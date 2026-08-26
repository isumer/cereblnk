---
name: cb-refactor
description: Behavior-preserving restructuring — invariant checklist before changes, re-verified after; auto-engages the edit boundary for the declared directory
argument-hint: <target path> <restructuring goal>
---

# RefactoringWorkflow (/cb-refactor)

**Trigger intent:** restructure something without changing behavior.
A request smuggling in behavior changes is split out to
/cb-implement
first — a refactor with feature changes is neither.

**Say this first, before the checklist.** One line to the user. This
run preserves behavior. It leaves the structure standing. If the
design itself is wrong, /cb-rewrite is the workflow.

This is a statement, not a question. The explicit command still wins.
It exists because "refactor" is the word users say for both jobs. The
wrong one is cheapest to correct before the first edit.

**Hand over when the target design demands it.** Three closed
triggers. Each is checkable once the target exists, and before any
edit.

- An observable contract must change to reach the target.
- A behavior the checklist marks suspect is load-bearing in it.
- The path will not cut into steps that hold the invariants.

Any one ends this workflow and starts /cb-rewrite. Widening scope in
place is the cardinal sin. Handing over is not.

## Boundary auto-engagement

Before any edit, run
`${CLAUDE_PLUGIN_ROOT}/scripts/run-flag flag boundary arm "" "<target path>"`.
The EditBoundaryHook now blocks writes
outside the declared directory for the session (hooks/README.md; note
honestly: blocks tools, not shell side-effects). On completion, remove
the flag and tell the user.

## Agent topology

```
Orchestrator → refactoring-agent (leads; writes the invariant checklist)
            → qa-agent           (checklist executability: which test
                                  or check covers each invariant; gaps
                                  get a test BEFORE the refactor starts)
            → refactoring-agent  (executes, surgical diffs)
            → verifier-agent     (invariants re-verified post-change,
                                  independently)
            → challenger-agent   (level 3 — this workflow is high risk:
                                  attacks with the interleaving/timing/
                                  init-order scenario the checklist missed)
            → synthesizer-agent
```

Budgets: Refactoring 8K · QA 6K · Verifier 4K · Challenger 4K ·
Synthesis 6K.

## The invariant contract

- The checklist is written and shown before the first edit. It names
  observable behaviors: outputs, side-effect order, error contracts,
  and the performance envelope where relevant) + the concrete check per item.
- An invariant with no executable check gets one first, or the
  refactor scope shrinks to what is checkable.
- After: every item re-verified, results as `known` facts. Any
  invariant that cannot be re-verified downgrades the whole verdict.

## Output

DECISION (behavior preserved: yes/no/except) → EVIDENCE (per-invariant
before/after) → REASONING → RISK (unchecked behaviors, boundary hook
gaps) → CONFIDENCE.

## Execution discipline

`policies/run-discipline.md` binds this run in full. Ledger and
digests, conductor-context budget, synchronous stages, path anchoring,
flag lifecycle, context-error recovery.

## Run flag (RunGuardHook wiring)

Arm at execution start, passing this run's id:
`${CLAUDE_PLUGIN_ROOT}/scripts/run-flag arm "" R-YYYY-MM-DD-NNN`.
It resolves `$CB_DIR` and verifies the flag landed.
A non-zero exit means the run is not guarded.
Do not proceed as though it were.
The id is not decoration.
Eight hooks resolve the run from this flag.
Armed without an id, they guess the newest directory.
That guess is the F-31 defect (CB-147).
The empty second argument holds the cb_dir slot.
Remove it before ANY turn that ends awaiting the user.
Complete it at final synthesis with `scripts/run-flag complete`.
A finished run is handed off, not stripped of its guard.
Plain `disarm` is the pause.
DelegationGuard tells the two apart.
Full lifecycle semantics live in `policies/run-discipline.md` §5.
That is the authoritative copy. This section does not restate it.
