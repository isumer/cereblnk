# ACP Validation Checklist

Enforces the ACP hard failures and field rules. Class: D — executed by the orchestrator
on EVERY incoming Response/Verification Block, in this order, before
the block enters the Evidence Graph. On any violation the action is
uniform: **discard the block, re-issue the task once with the violated
item cited**. A second violation on the same task → the task
returns to the Planner as `blocked` with the violation history.

## The ordered checklist

| # | Check (detection step) | Violated rule |
|---|---|---|
| V1 | Block parses as a single ACP YAML block of `kind: response/verification/challenge` — no free-form prose outside it | free-form output |
| V2 | Every fact sits under exactly one label key (known/derived/estimated/assumed/speculative) and carries an `id` | unlabeled claims |
| V3 | Every `known` fact has a resolvable `evidence:` reference (`CTX-*#L*`) | known without evidence |
| V4 | Every `derived` fact names its `from:` chain; every `estimated` fact states a `basis` | |
| V5 | The `decision` does not rest on `speculative` facts alone; if it rests on any `assumed` fact, the decision text says so | / §4.1 |
| V6 | `budget_report.tokens_used ≤ tokens_received`, OR `status: blocked` | budget overrun |
| V7 | Any fact imported from another agent carries that agent's evidence reference (no conclusion travels without its evidence) | / the evidence rule |
| V8 | `confidence` present with `confidence_basis`; >0.90 only with zero assumed facts in the decision chain | |
| V9 | Verification/challenge blocks: `target_task` + `verdict` present; Challenger blocks contain ≥1 concrete counter-scenario OR the explicit none-constructed statement | |

## Gate-completeness rule (blocks synthesis, not blocks)

After all blocks validate, before ANY synthesis is composed:

| Level | Required verdicts present and passing |
|---|---|
| 1 | executing agent's self-test noted in its block |
| 2 | Verifier verdict + Consistency verdict, both ≠ refuted/missing |
| 3 | Verifier + Challenger + Consistency, all present; Consistency `confirmed`; Verifier ≠ `refuted`; a missing Challenger block is treated as a failed gate, never waived |

Missing or failed → NO synthesis: the run returns to the pipeline
stage the gate names (refuted → Planner; inconclusive → evidence
request; contradiction → consensus-policy §3). Checker of this rule
itself: SynthesizerAgent independently refuses composition without
the verdict set (its quality gate 1) — two locks, one door.
