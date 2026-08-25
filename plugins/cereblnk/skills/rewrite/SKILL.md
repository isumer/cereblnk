---
name: cb-rewrite
description: Redesign existing code whose structure is wrong — the old behavior is extracted as a ruled contract, then designed fresh; the replaced structure never reaches the design stage
argument-hint: <target path> <what is wrong with the current design>
---

# RewriteWorkflow (/cb-rewrite)

**Trigger intent:** the structure itself is wrong, so behavior may
change. A request that must preserve behavior exactly goes to
/cb-refactor instead. These are not degrees of one job.

## Why this workflow exists

A rewrite fails by reproducing the design it was called to replace.
The old structure is the most concrete thing available, and every
later stage anchors to it. So the old code enters as behavior, never
as structure. The agent that read it leaves before design begins.

## Stage 0 — Does the old system run

Run `scripts/env preflight`. That answer sets every epistemic label.

It runs: characterization tests are possible, and rows can reach
`known`. It does not run: every row stays `derived`, and differential
validation does not exist for this rewrite. Say which case holds in
the contract's first line. A rewrite may proceed either way. It may
not proceed silently.

## Agent topology

```
Orchestrator → legacy-analyst-agent  (per module; code → behavior rows,
                                      domain language, classified)
            → testengineer-agent     (characterization tests against the
                                      OLD system — these are the char:
                                      oracles the ruling stage needs)
            → qa-agent               (is the pinned coverage sufficient)
            → requirements-agent     (rules each row with the user:
                                      keep / fix / drop / deferred)
            → challenger-agent       (attacks the contract before it
                                      freezes: the missed behavior, the
                                      defect that turns out load-bearing)
            ──── firewall: the old structure stops here ────
            → apidesign-agent        (contract artifact — channels, plus
                                      migration rows naming the old
                                      paths as replaced)
            → architect-agent        (+ surface specialists per
                                      agent-selection-policy §1;
                                      designs from the contract)
            → verifier-agent · consistency-agent · synthesizer-agent
```

Budgets: LegacyAnalyst 8K per module · TestEngineer 8K · QA 6K ·
Requirements 6K · Challenger 4K · APIDesign 6K · Architect 8K ·
Verifier 4K · Synthesis 6K.

Level 3, workflow-fixed. The blast radius sets it, not the surface.

## The firewall

Everything above the line reads the old code. Nothing below it does.

The architect's Task Block may reference the contract, the project's
architecture documents, the stack profile and the rule set. It may not
reference the replaced module's source.

That distinction is the point. The host project's conventions are
required input, because the new structure must belong to this project.
The replaced module's structure is not input at all.

## The contract gate

Before the firewall, run `behavior-check <project root>`. Exit 1 means
rows are unruled, or ruled dishonestly. Design does not start on a
finding. Class D — the script is the checker, and no hook blocks the
spawn yet.

Ruling semantics:

- `keep` — the old system is the oracle. Differential parity applies.
- `fix` — the old behavior is pinned, then deliberately changed. Two
  assertions follow: the new expectation holds, and the old one does
  not come back.
- `drop` — no oracle, a recorded decision. Never silence.
- `deferred` — outside this slice, with the reason.

A `suspected-bug` row ruled `keep` is refused. Reclassify it
`intentional` and record why. Keeping a row still labelled a defect
hides the decision.

## Scope discipline

A need discovered during extraction is not in scope. It leaves for
/cb-frame. The refactor's cardinal sin is the smuggled feature. This
workflow's sin is "while we are here". The contract freezes at the
ruling stage, and later stages consume it rather than extend it.

## Acceptance

Every implementation slice traces to a ruled contract row. A slice
whose acceptance criterion names no row is out of scope.
VerifierAgent checks that trace at the gate.

After the surfaces close, `contract-check` reconciles the migration
rows. A replaced path still present anywhere is a finding — that is
the mechanical form of "the rewrite became a transcription".

## Output

DECISION (per row: kept / fixed / dropped) → EVIDENCE (differential
results per row, and which rows had no oracle) → REASONING → RISK
(rows still `derived`, deferred rows, unreached branches) →
CONFIDENCE.

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
Remove it at final synthesis.
Full lifecycle semantics live in `policies/run-discipline.md` §5.
That is the authoritative copy. This section does not restate it.
