# Consensus Resolution Policy

Governs contradiction resolution: the three contradiction types and the
evidence-not-majority rule, over ACP fact sets. Class: D — mechanical steps with named checkers:
**ConsistencyAgent detects; the orchestrator blocks.**

## 1. Scope

Applies to every full-pipeline run (level 2+) across all Response
Blocks of the run, AND — via the evidence index
(`.claude/cereblnk/memory/evidence/`) — against prior recorded decisions.

## 2. Detection rules (mechanical, per contradiction type)

**Direct** — two facts assert incompatible claims.
Detect: same subject (matching evidence target or explicit `from`
linkage) with negating/incompatible predicates, e.g. F-3
(SecurityAgent) "expiry is validated on refresh" vs F-7 (BackendAgent)
"refresh path skips expiry validation".

**Epistemic** — same claim, different labels.
Detect: claim-text/subject match across blocks where labels differ in
decision force (e.g. `known` in one block, `speculative` in another).

**Silent** — one agent's `assumed` fact is another agent's disproven
claim. Detect: every `assumed` fact is searched against all `known`/
`derived` facts and verification verdicts of the run and the evidence
index; a hit where the evidence contradicts the assumption is a silent
contradiction.

## 3. Resolution rules (evidence beats assertion — never majority)

Ordered, per detected contradiction:

1. **Rank by evidence class.** A claim WITH a resolvable evidence
   reference outranks a claim without one (an unlabeled or
   unreferenced "known" is already a protocol violation — discard that
   block, contradiction may dissolve).
2. **Evidence vs evidence → re-verification, never vote.** If BOTH
   claims carry evidence references, neither wins by count or by
   seniority of role: the orchestrator issues verification tasks for
   BOTH evidence references to the VerifierAgent (independent
   re-derivation). The surviving claim wins; both surviving →
   escalate risk one level and put the conflict itself in RISK.
3. **Label reconciliation (epistemic type).** The weaker label
   governs until re-verification: a claim simultaneously `known` and
   `speculative` is treated as `speculative` for decision purposes
   until the Verifier confirms the evidence, at which point the
   labels are corrected at the source blocks (no in-place history
   edits in memory — supersession per memory-policy P-5).
4. **Assumption update (silent type).** The disproven `assumed` fact
   is marked contradicted; every decision resting on it is re-opened
   (the producing task returns to the Planner with the contradiction
   attached).

## 4. Blocking rule

**No synthesis while any detected contradiction is unresolved.**
The SynthesizerAgent refuses composition when the ConsistencyAgent
verdict is `refuted` (contradictions listed); the orchestrator refuses
to relay any synthesis lacking a `confirmed` consistency verdict at
level 2+. Resolution happens by the §3 rules only — a contradiction
"resolved" by dropping one side without re-verification is itself a
violation (checker: VerifierAgent sees no verification task for the
dropped claim and flags it).

## 5. Cross-run consensus

Before synthesis, ConsistencyAgent queries the evidence index for
prior facts on the touched subjects. A contradiction with a
`repository/` or `evidence/` record follows the same §3 rules, with
one addition: current-run evidence outranks archived evidence of equal
class ONLY after re-verification of the archived reference confirms
it is stale; the supersession is then recorded (memory-policy P-5),
never silently ignored.
