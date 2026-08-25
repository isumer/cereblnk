---
name: cb-qa
description: Diff-aware test pass — identifies affected surfaces from the branch diff, executes the applicable test plan, generates a regression test for every confirmed fix
argument-hint: [branch or diff range; defaults to current branch vs main]
---

# QAWorkflow (/cb-qa)

**Trigger intent:** "test what changed." Evidence-based: tests, diff
analysis, and the runtime stage below when it is configured.

Two mechanisms, kept apart. Bringing the system up and polling its
health is real, through the env script. Driving a browser or a live
device is not. Browser tests may be written and their run command
named. A passes claim for one requires real CI output. Without it the
result is assumed. This workflow must not claim to have executed a
browser test.

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
5. **Runtime stage, when the project configures one.** The env
   script under `plugins/cereblnk/scripts/` owns it. Ask its preflight
   action first. Exit 3 is a skip and the stage ends there, reported as
   a skip rather than a pass. Preflight refuses to start when something
   already answers the health URL. That stack belongs to somebody else
   and is never touched.

   Then ask env to bring the system up. Exit 4 is an ENVIRONMENT
   verdict. The stage stops. Report the environment and say nothing
   about the application. A check against a stack that never started is
   evidence of nothing, and reporting it as an application failure is
   the error this separation exists to prevent.

   On exit 0 the surfaces are up together. Run the checks that cross
   them, which is the whole reason to pay for an environment: the paths
   one surface alone cannot prove. Then ask env to take it down. The
   teardown hook reclaims a leaked environment at session end, but the
   stage takes it down itself and does not lean on the hook.

## Output

DECISION (surface-by-surface pass/fail + the coverage gaps that matter)
→ EVIDENCE (runs, refs) → REASONING → RISK (untested surfaces,
assumed-equivalent behaviors) → CONFIDENCE.

## Execution discipline

`policies/run-discipline.md` binds this run in full — ledger +
digests, conductor-context budget, synchronous stages, path
anchoring, flag lifecycle, context-error recovery.

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
Complete it at final synthesis with `scripts/run-flag complete` — a
finished run is handed off to `run-completed`, not stripped of its
guard. Plain `disarm` is the PAUSE, and DelegationGuard tells the two
apart: a removed flag over a warm ledger is its disarm-and-continue
violation, which is what a conductor following the old wording hit.
Full lifecycle semantics live in `policies/run-discipline.md` §5.
That is the authoritative copy. This section does not restate it.
