---
name: cb-qa
description: Diff-aware test pass — identifies affected surfaces from the branch diff, executes the applicable test plan, generates a regression test for every confirmed fix
argument-hint: [branch or diff range; defaults to current branch vs main]
---

# QAWorkflow (/cb-qa)

**Trigger intent:** "test what changed." Evidence-based only: tests +
diff analysis. No browser/live-device EXECUTION — that mechanism is F-class until
the execution-mechanism map confirms one. Browser tests may be written and their run command named. But a
passes claim requires real CI output. Without it the result is `assumed` (assumed-until-
CI). This workflow must not claim to have executed a browser test.

## Agent topology

```
Orchestrator → testengineer-agent (designs the pyramid split: which
                behavior at which layer with which tool; writes tests —
                selects the fitting test skill by context)
            → qa-agent (JUDGES sufficiency: does coverage catch the
                failure mode? TestEngineer proposes, QA decides
                enough-ness)
            → planner-agent only when the affected surface spans >3
              modules (slicing the test pass)
            → verifier-agent on the coverage verdict (level 2 default)
```

Budgets: QA 6K per surface · Planner 4K (when engaged) · Verifier 4K ·
Synthesis 6K.

## Method

1. **Read the diff, not the repo.** Affected surfaces = changed files +
   their direct dependents (imports/call sites in the diff's blast
   radius). List them as facts with refs.
2. **Map surfaces to the plan.** A /cb-design test matrix may exist in
`.claude/cereblnk/memory/specs/`. Execute its applicable rows.
Otherwise
   derive the minimal plan from the diff (each changed behavior → the
   check that would fail without the change).
3. **Run.** Execute the applicable test subset; results are `known`
   facts with command + output refs. Ask traps's question of every
   green suite: what would these tests FAIL on? Missing failure-mode
   coverage is a finding, not a footnote.
4. **Regression per confirmed fix.** Every fix confirmed in the diff
gets a regression test. It fails before and passes after. Generated,
run, and cited.

## Output

DECISION (surface-by-surface pass/fail + the coverage gaps that matter)
→ EVIDENCE (runs, refs) → REASONING → RISK (untested surfaces,
assumed-equivalent behaviors) → CONFIDENCE.

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
