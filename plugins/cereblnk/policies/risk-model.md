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

## Precedence: the domain floor beats the assigned level

The list above is a FLOOR, and a floor is not advice. When a Task
Block's `verification_level` or `risk` sits below the floor its domain
carries, **the floor wins** — both fields, both directions.

This had never been written down. A Task Block arrived carrying
`verification_level: 1` and `risk: low` for a security task, while
`security-agent.md` and `skills/security-audit/SKILL.md` both said
"always verification level 3 — no exceptions, no fast path" and cited
this file. Two rules, no stated order. The agent ran at level 3, which
is correct, and it got there by judgment: nothing it could point at
said which of the two it was obeying, and the next agent could as
easily have obeyed the block.

| Who | Reads this rule as |
|---|---|
| Dispatcher / orchestrator | A block assigned to a domain with a floor is ISSUED at the floor. Writing a lower level is not a downgrade decision the dispatcher is entitled to make — it is a malformed block. |
| Specialist | Run at the floor, whatever the block says. Do not ask, do not negotiate, and do not silently comply with the lower number. Record the correction: `status: escalated`, naming `level-3-surface`, so the run's own ledger shows the block was wrong rather than showing an agent that ignored its instructions. |

The floor is never satisfied by a smaller scope, a read-only task, a
one-line diff, or a Task Block that says `risk: low`. Those are the
conditions under which the escalation rules below would have caught a
downgrade in flight; this rule catches the downgrade that was written
into the assignment before anything ran.

**Checker:** `scripts/acp-lint` T-2 refuses a Task Block whose role
carries an unconditional floor and whose `verification_level` is below
it — at the assignment, which is where the wrong number is written
first (the CB-127 lesson, applied to levels instead of roles).

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
