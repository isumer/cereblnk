# Quality Gate Policy

Governs the quality gates. Class: Discipline — gate
blocking is an orchestrator instruction; every rule names its checker.

## Verification levels (risk-scaled)

| Level | Risk | Required gates |
|---|---|---|
| 1 | low | Self-verification by the executing agent only |
| 2 | medium | Verifier + Consistency |
| 3 | high | Verifier + Challenger + Consistency (all mandatory) |

## The three gates

| Gate | Question | Verdicts / output |
|---|---|---|
| Verifier | Is the result technically correct? Re-derives from evidence WITHOUT reading the original reasoning first | confirmed / refuted / weakened / inconclusive |
| Challenger | Can I argue the opposite? Must produce ≥1 concrete counter-scenario or state none could be constructed | surviving counter-scenarios become mandatory RISK entries |
| Consistency | Do agents contradict each other? Mechanical comparison of fact IDs, claims, labels across blocks | direct / epistemic / silent contradictions |

## Blocking rules

1. No user-facing synthesis without the required gate verdicts for the
   run's risk level. (Checker: SynthesizerAgent — it refuses to emit a
   Synthesis Block without them; the orchestrator refuses to relay one.)
2. `refuted` returns the task to the Planner; `inconclusive` requests
   more evidence and never silently passes. (Checker: orchestrator.)
3. Any contradiction found by Consistency blocks synthesis until
   resolved by evidence — never by majority vote. (Checker:
   ConsistencyAgent verdict is a hard input to the SynthesizerAgent.)
4. Confidence discipline: >0.90 requires zero assumed facts in
   the decision chain AND a confirmed Verifier verdict; <0.60 must lead
   with uncertainty. (Checker: SynthesizerAgent self-test.)

## Correction-first outputs

Every synthesis RISK section must contain falsifiers, watch items, and
an assumption ledger. An answer that cannot state its own falsifiers is
not done. (Checker: SynthesizerAgent five-question self-test, Q4.)
