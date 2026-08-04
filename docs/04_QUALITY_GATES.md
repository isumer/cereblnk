# Quality Gates Policy

> Status: Frozen v1.0
> This document defines what must be true before any answer reaches the user.
> Depends on: 00_MANIFESTO.md (Law 3, Principle 3), 01_RUNTIME_SPECIFICATION.md,
> 02_AGENT_COMMUNICATION_PROTOCOL.md

---

## 1. The Three Gates

Every synthesis passes through up to three independent gates:

| Gate | Question | Method |
|---|---|---|
| **Verifier** | Is the result technically correct? | Independent re-derivation from evidence, without reading the original reasoning first |
| **Challenger** | Can I argue the opposite? | Constructs counter-scenarios, edge cases, failure modes — never repeats original reasoning |
| **Consistency** | Do agents contradict each other? | Mechanical comparison of ACP fact sets across all Response Blocks |

An answer that fails a required gate does not reach the user.
It returns to the Planner for re-work with the gate's findings attached.

---

## 2. Risk-Scaled Verification (Principle 3)

Running all three gates on every trivial question would make the system
unusably slow and expensive. Gates scale with risk:

| Verification Level | Risk | Required Gates |
|---|---|---|
| **Level 1** | Low | Self-verification by the executing agent only |
| **Level 2** | Medium | Verifier + Consistency |
| **Level 3** | High | Verifier + Challenger + Consistency (all mandatory) |

Escalation rules:
- Any agent may escalate risk upward at any time (ACP `status: escalated`).
- Risk is never silently downgraded.
- Security-surface, auth, data-deletion, migration, money, and prod-config
  tasks are always Level 3, regardless of apparent simplicity.

---

## 3. Gate Definitions

### 3.1 Verifier

- Receives: the task's evidence bundle + the decision (NOT the reasoning).
- Re-derives the conclusion independently from evidence.
- Verdicts: `confirmed | refuted | weakened | inconclusive`.
- `weakened` → confidence is reduced and the weakness appears in RISK.
- `refuted` → task returns to Planner.
- `inconclusive` → more evidence is requested; never silently passes.

### 3.2 Challenger

- Receives: the decision and its fact set.
- Obligation: produce at least one concrete counter-scenario, or explicitly
  state that none could be constructed and why.
- Prohibited: restating or paraphrasing the original reasoning.
- A surviving counter-scenario becomes a mandatory RISK entry in the
  user-facing synthesis.

### 3.3 Consistency

- Mechanical, not interpretive: compares fact IDs, claims, and labels
  across all Response Blocks in the run.
- Contradiction types:
  - **Direct** — F-3 (SecurityAgent) contradicts F-7 (BackendAgent).
  - **Epistemic** — same claim labeled `known` by one agent, `speculative`
    by another.
  - **Silent** — one agent's `assumed` fact is another agent's disproven claim.
- Any contradiction blocks synthesis until the Consensus Engine resolves it
  (by evidence, never by majority vote).

---

## 4. Workflow-Level Validation

Beyond the three gates, every completed workflow must pass:

1. **Technical validation** — code compiles / logic holds / claims re-derivable.
2. **Architectural validation** — respects declared structure and boundaries.
3. **Security validation** — no new attack surface without explicit sign-off.
4. **Performance validation** — no unbounded complexity introduced silently.
5. **Consistency validation** — output does not contradict prior decisions
   recorded in `.claude/cereblnk/memory/`.

---

## 5. Correction-First Outputs (Principle 8)

Every user-facing synthesis must contain, in its RISK section:

- **Falsifiers** — what evidence would prove this answer wrong.
- **Watch items** — what to check first if reality disagrees.
- **Assumption ledger** — every `assumed` fact the decision rests on.

An answer that cannot state its own falsifiers is not done.

---

## 6. Confidence Discipline

- Confidence is a single calibrated number (0.00–1.00) with a stated basis.
- \>0.90 requires: zero assumed facts in the decision chain AND a
  `confirmed` Verifier verdict.
- 0.60–0.90: normal operating range; unknowns listed.
- <0.60: the synthesis must lead with uncertainty, and the DECISION section
  must present it as a provisional recommendation, not a conclusion.
