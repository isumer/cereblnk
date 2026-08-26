---
name: cb-pr-review
description: Cereblnk PR review — production-incident hunting across a diff with specialist agents, risk-scaled gates, and a decision-first verdict
argument-hint: [PR number, branch, or diff path]
---

# PRReviewWorkflow (/cb-pr-review)

**Trigger intent:** review this PR, diff, or branch. Can it merge?
The operational objective is almost always this: is there production
risk here (09 Procedure 1)? The output therefore leads with merge or
do-not-merge.

## Agent topology

```
Orchestrator (this command; applies /cb-orchestrate rules)
  → planner-agent            (slice the diff into verifiable review tasks)
  → specialists, parallel:   architect-agent · backend-agent ·
                             security-agent · qa-agent ·
                             performance-agent · docs-agent
      (each invoked ONLY if the diff touches its domain; each gets one
       ACP Task Block with diff-scoped context refs — never the whole repo)
  → gates: verifier-agent  → challenger-agent (level 3 only)
           → consistency check (mechanical fact-set comparison)
      allowed feedback loop: architect ↔ security (one round max) when a
      structural finding changes the trust-boundary picture
  → synthesizer-agent        (five-question self-test, then Synthesis Block)
```

## Per-stage budgets (policies/budget-policy.md)

Planner 4K · Architect 8K · Backend 8K · Security 6K · QA 6K ·
Performance 6K · Docs 4K · Verifier 4K · Challenger 4K · Synthesis 6K.
Overrun without `blocked` = discard and re-issue.

## Gate level policy

Default **level 2** (Verifier + Consistency). Escalate to **level 3**, adding a mandatory Challenger, when the diff
touches the always-level-3 list (`policies/risk-model.md`). That list
covers auth, money, deletion,
migrations, prod config, security surface. Risk is never downgraded.

## What the specialists hunt (Procedure 3 — spend depth where risk lives)

N+1 queries · race conditions and cross-instance locking · trust
boundary changes · stale reads · missing enum/branch handlers · retry
logic bounds · tests that pass while missing the failure mode ·
silently unbounded complexity · doc drift caused by this diff.

## Fix handling

- **Mechanical fixes** may be auto-applied, one conventional commit per fix, each traceable to a finding.
- **Judgment calls** are never auto-applied — they surface in the
  synthesis as decisions for the user.
- Principles 9–10 bind: no improvements beyond the findings.

## Output (fixed ordering, the cognitive contract)

```
DECISION    merge / do-not-merge / merge-after-listed-fixes — one paragraph
EVIDENCE    known/derived findings with diff line references
REASONING   how the evidence forces the decision
RISK        falsifiers, watch items, assumption ledger,
            surviving Challenger counter-scenarios
CONFIDENCE  calibrated number + basis + open unknowns
```

Epistemic labels survive into this output verbatim.

## Specialist selection is signal-driven

The specialist list above is the common core, not a ceiling. The
diff's surfaces add their specialists per selection-policy §1 and
§3b. A UI-touching diff without frontend-agent, a migration diff without
database-agent, or a pipeline/IaC diff without infra-agent is a
selection violation VerifierAgent must flag.

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
Complete it at final synthesis with `scripts/run-flag complete`.
A finished run is handed off, not stripped of its guard.
Plain `disarm` is the pause.
DelegationGuard tells the two apart.
Full lifecycle semantics live in `policies/run-discipline.md` §5.
That is the authoritative copy. This section does not restate it.
