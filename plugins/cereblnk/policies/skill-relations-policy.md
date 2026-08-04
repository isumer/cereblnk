# Skill Relations Policy

Class: D — declarative metadata in skill Identity sections, consumed by
the orchestrator/PlannerAgent through `agent-selection-policy.md` §4.
**Checker: ConsistencyAgent** — validates that every referenced skill
exists, that the `requires` graph is acyclic, and that no relations
line smuggles a static confidence claim (see §4). A dangling reference
or a `requires` cycle is a structural contradiction that blocks the
run's synthesis until repaired.

## 1. The three fields

Each domain skill may carry, directly under its Identity `name:` line:

```
requires: <skill> · <skill>
complements: <skill> · <skill>
escalate_to: <target> (<when>) · <target> (<when>)
```

| Field | Meaning | Consumption rule |
|---|---|---|
| `requires` | Hard prerequisites — this skill's reasoning is unreliable without them | When this skill is loaded for an agent, its `requires` closure is loaded with it, within the agent's budget (see §3) |
| `complements` | Optional companions that improve quality when the task touches their surface | Loaded only if the task signal also matches them AND budget remains |
| `escalate_to` | The out-of-scope boundary: which skill (or agent) takes over, and when | Informational for the executing agent; a hit on the stated condition is grounds for ACP `status: escalated` or an explicit unknown, never a silent guess |

Empty fields are omitted, not written as empty lists. Entry-point
skills (dispatch) carry no relations — they route, they are not domain
knowledge.

## 2. What this is and is not

- Relations are **load-together and hand-over metadata**, nothing more.
- `escalate_to` is the skill-level mirror of Law 1: it names where this
  skill's competence ends. It does not transfer decision authority —
  agents decide, skills inform, exactly as before.
- Relations are **not** invocation conditions. Which skills a task
  needs is decided by `agent-selection-policy.md` §1 signals and agent
  frontmatter; relations only expand or bound that set.

## 3. Budget interaction

The `requires` closure counts against the agent's `budget_tokens`.
Resolution order when the closure does not fit:

1. The skill itself and its direct `requires` — never dropped.
2. Transitive `requires` — dropped farthest-first, each drop recorded
   as an `assumed` fact ("reasoned without <skill>") in the Response
   Block.
3. `complements` — first to drop, silently (they are optional by
   definition).

An agent that drops a direct `requires` instead reports `blocked` —
reasoning without a hard prerequisite is the exact failure mode this
policy exists to prevent.

## 4. No static confidence — by design

Relations metadata deliberately contains **no** per-skill confidence
rating. Confidence in Cereblnk is a calibrated property of a specific
decision in a specific run (ACP `confidence` + `confidence_basis`),
never a static attribute of a knowledge file. A skill declaring itself
"high confidence" would transfer no information and would invite
exactly the uniform, uncalibrated certainty the false-competence
catalog warns against. ConsistencyAgent treats any confidence-like
token in a relations line as a violation of this policy.

## 5. Falsifier

This policy earns its place if agents loading a skill's `requires`
closure produce measurably fewer `assumed` facts referencing missing
prerequisite knowledge, and if escalation conditions fire where guesses
previously shipped. If relations metadata is observed to be loaded but
never consulted across runs, the policy has failed and should be
removed rather than maintained as decoration.
