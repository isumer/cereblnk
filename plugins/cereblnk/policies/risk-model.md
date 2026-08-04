# Risk Model Policy

Governs risk scoring and its consequences: risk drives verification
depth, agent count, and budget. Class: Discipline — every rule below
names its checker.

## Risk levels

| Risk | Signals | Consequence |
|---|---|---|
| low | read-only questions, isolated edits, no prod impact | Fast path; verification level 1 |
| medium | multi-file changes, API changes, data-model touches | Full pipeline; verification level 2 |
| high | security surface, migrations, auth, money, deletion, prod config | Full pipeline; verification level 3; Challenger mandatory |

## Always level 3, regardless of apparent simplicity

Security surface · authn/authz · data deletion · schema migrations ·
anything touching money · production configuration.
(Checker: the orchestrator's routing step re-checks task objectives
against this list before the fast path is allowed.)

## Fast-path abort

The fast path is a bet on the pre-score. The agent doing the work sees
what the orchestrator could not. Four findings lose the bet:

| Trigger | Observable |
|---|---|
| `level-3-surface` | The work reaches auth, money, deletion, migration, prod config, or a security boundary the pre-score never named |
| `scope-growth` | Correctness now depends on a file outside the task's declared set |
| `claim-not-rederivable` | A load-bearing claim falls from `known` to `assumed` (09 Procedure 4) |
| `confidence-below-floor` | The answer would ship under 0.60 — provisional (04 §6) and unverified at once |

The list is closed. Anything else is a RISK entry in the answer, not an
abort. An open list turns every fast-path task into a pipeline run and
inverts Principle 3.

On a trigger the agent stops. It does not finish the answer. It returns
`status: escalated`, names the trigger, and attaches the evidence that
fired it. A conclusion shipped with a warning attached is not an abort.

**What the orchestrator then does.**

1. Drop the fast-path conclusion. Keep its facts.
2. Re-route to the full pipeline. `level-3-surface` forces level 3;
   the other three triggers force level 2 or higher.
3. Never re-enter the fast path in this run.
4. Plan fresh. The escalation block reaches the Planner as evidence,
   never as a finding — the fresh-executor rule
   (`execution-loop-policy.md` §3) applies to routing too.

(Checkers: the orchestrator's routing step for rules 1–3;
SynthesizerAgent for rule 2, refusing any synthesis whose verification
level sits below the highest risk recorded in a block; the run summary
records the abort under `fast_path_abort` for later measurement.)

## Escalation rules

1. The Intent Engine (orchestrator) assigns the initial risk score.
2. Any agent may escalate risk upward at any time via
   `status: escalated` in its Response Block.
   (Checker: orchestrator — an escalated task is re-issued at the
   higher level; ignoring an escalation is a protocol violation.)
3. Risk is **never silently downgraded**.
   (Checker: SynthesizerAgent refuses to synthesize a run whose final
   verification level is below the highest risk recorded in any block.)
