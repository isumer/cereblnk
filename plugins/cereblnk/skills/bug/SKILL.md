---
name: cb-bug
description: Cereblnk bug investigation — root-cause-first, hypothesis-driven tracing; no fix ships without a demonstrated root cause
argument-hint: <bug description, failing test, or issue reference>
---

# BugInvestigationWorkflow (/cb-bug)

**Trigger intent:** why is this broken, or fix this bug.

## The iron rule

**No fix without root cause.** A root-cause statement must precede any
fix proposal in the output, and the root cause must be demonstrated
(reproduction or evidence-referenced trace), not narrated. A fix whose
root cause is `assumed` is presented as provisional, in RISK, never as
DECISION.

## Method: one hypothesis at a time

1. **Reproduce first.** Turn the report into a failing test or a
   deterministic reproduction. If it
   cannot be reproduced, that becomes the first investigation target —
   not a reason to guess.
2. **Hypothesize singly.** planner-agent produces a ranked hypothesis
   list (Procedure 3: probability × cost). Exactly one hypothesis is traced at a time, by the fitting
specialist. Backend-agent by default. Security-agent or
performance-agent when the signal points
   there). Each trace ends in a labeled verdict: confirmed / refuted /
   inconclusive — with evidence refs.
3. **Fix minimally.** On a confirmed root cause, in order. A reproducing
test. A minimal fix (Principles 9 and 10). The test passes. Then
qa-agent designs the regression test that would have caught it.
4. **Gate.** verifier-agent re-derives the root-cause claim from the
evidence. Level 2 by default. Level 3 with challenger-agent when the
fix touches the always-level-3 list). EditBoundaryHook is engaged for
   the fix stage when hooks are enabled (see hooks/README.md).

## The 3-strike stop rule

After **3 failed fix attempts**, the workflow STOPS fixing. It invokes architect-agent to question the architecture instead. The recurring failure becomes evidence that the fault is structural.
A wrong boundary, a wrong ownership, a wrong invariant. Thrashing on
a fourth
patch is prohibited. The architectural finding goes to the user as a
decision, not as another silent attempt.

## Agent topology

```
Orchestrator → planner-agent (hypothesis ranking)
            → one specialist per hypothesis, strictly sequential
            → qa-agent (regression design, after confirmed root cause)
            → verifier-agent [→ challenger-agent] → synthesizer-agent
```

## Per-stage budgets

Planner 4K · tracing specialist 8K per hypothesis · QA 6K ·
Verifier 4K · Challenger 4K · Synthesis 6K (policies/budget-policy.md).

## Output (fixed ordering)

```
DECISION    root cause (demonstrated) + the minimal fix — or, after
            3 strikes, the architectural question that must be answered
EVIDENCE    reproduction, trace refs, hypothesis verdicts
REASONING   why this cause and not the refuted hypotheses
RISK        falsifiers, assumption ledger, regression exposure
CONFIDENCE  number + basis + open unknowns
```

## Who traces (this section wins over any older agent list)

**debugger-agent leads** the hypothesis loop — it owns root-cause
methodology (exactly ONE hypothesis per pass, consistent with its
CB-015 definition). The failing surface's specialist joins per selection-policy §3b.
Frontend-agent for interface bugs, database-agent for data bugs, and
so on. It supplies domain knowledge and skill closure;
security-agent joins mandatorily when the bug touches the
always-level-3 list. The conductor never traces in its own context.

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
