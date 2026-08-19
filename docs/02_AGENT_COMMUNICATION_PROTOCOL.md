# Agent Communication Protocol (ACP)

> Status: Frozen v1.2 (Amendments A1, A3 applied — see Appendix)
> This document defines the ONLY format in which agents exchange information.
> Depends on: 00_MANIFESTO.md, 01_RUNTIME_SPECIFICATION.md
> No agent output in free-form text is ever accepted by another agent.

---

## 1. Why ACP Exists

Synthesis across many agents is only possible if every agent speaks the
same structured language. ACP guarantees:

- **Mergeability** — the Consensus Engine can compare outputs mechanically.
- **Evidence traceability** — every claim links to its source (Law 2).
- **Epistemic integrity** — labels survive summarization (Principle 5).
- **Budget accounting** — every block reports its context consumption.

---

## 2. Task Block (Runtime → Agent)

Every agent receives exactly one Task Block. Nothing else.

```yaml
acp_version: "1.0"
kind: task
task_id: T-014
run_id: R-2026-07-16-001
role: SecurityAgent
objective: >
  Determine whether the JWT validation change in AuthFilter introduces
  an authentication bypass.
constraints:
  - Do not evaluate performance implications (out of expertise → Law 1)
  - Production system, zero-downtime requirement
risk: high
budget_tokens: 8000
verification_level: 3
context_refs:               # provided by Context OS, never raw files
  - ref: CTX-114            # compressed evidence bundle: AuthFilter diff
  - ref: CTX-115            # compressed evidence bundle: SecurityConfig
documents:                  # indexed sources; sections, never whole files
  - doc_id: 1113d150a553    # scripts/docindex; outline.json holds the map
    sections: [s004, s005]  # the agent opens these line ranges, nothing more
acceptance: >
  A pass/fail conclusion on auth bypass with every supporting claim
  labeled Known or Derived and linked to evidence.
```

---

## 3. Response Block (Agent → Runtime)

Every agent returns exactly one Response Block.

```yaml
acp_version: "1.0"
kind: response
task_id: T-014
role: SecurityAgent
status: completed          # completed | blocked | escalated

decision: >                # one sentence, the answer to the objective
  The change introduces a token-expiry bypass when clock skew exceeds 30s.

facts:
  known:                   # directly observed in evidence
    - id: F-1
      claim: "AuthFilter no longer calls validateExpiry() on refresh path"
      evidence: [CTX-114#L42-58]
  derived:                 # logically follows from known facts
    - id: F-2
      claim: "Expired tokens on the refresh path are accepted"
      from: [F-1]
  estimated:               # quantified with uncertainty
    - id: F-3
      claim: "Exploit window is roughly the configured skew tolerance (~30s)"
      basis: "config value in CTX-115#L12"
  assumed:                 # taken without evidence — must be listed
    - id: F-4
      claim: "No upstream gateway re-validates expiry"
  speculative: []          # hypotheses; never drive decisions alone

unknowns:
  - "Whether the API gateway performs its own JWT validation"

risks:
  - severity: high
    description: "Authentication bypass on refresh endpoint"
    falsified_by: "Evidence that gateway validates expiry (resolves F-4)"

confidence: 0.78           # 0.00–1.00, calibrated, justified by fact mix
confidence_basis: >
  High on F-1/F-2 (direct evidence). Discounted for assumption F-4.

next_action: >
  Verify gateway JWT config before finalizing severity.

artifacts: []              # produced files/patches, by reference

budget_report:
  tokens_received: 8000
  tokens_used: 6200
```

---

## 4. Field Rules

### 4.1 Epistemic labels (mandatory, Principle 5)

| Label | Definition | May drive a decision? |
|---|---|---|
| known | Directly observed in referenced evidence | Yes |
| derived | Logical consequence of known facts, chain stated | Yes |
| estimated | Quantified with stated basis and uncertainty | Yes, with caveat |
| assumed | Believed without evidence, explicitly listed | Only if flagged in decision |
| speculative | Hypothesis | Never alone |

Rules:
- Every fact has an `id` so other agents can reference it (`from: [F-1]`).
- A `derived` fact must name the `known` facts it follows from.
- If a decision depends on any `assumed` fact, the decision text must say so.
- Labels are preserved verbatim through compression and synthesis.

### 4.2 The role vocabulary is closed

`role:` names an agent that exists. The legal values are exactly the
agent files the platform ships — `agents/**/<name>-agent.md` — matched
without regard to case or separators, so `SecurityAgent` and
`security-agent` are the same role.

A role is not a description of the expertise wanted. It is the address
of something that can be spawned. A block naming a role with no agent
file addresses nothing: the Task Block assigns work that cannot be
picked up, and the Response Block reports a verdict nobody reached.

The distinction this closes is skill against agent. A skill is a
capability an agent loads; an agent is what runs. When a request needs
expertise the roster does not name, the answer is the surface
specialist that owns the files, carrying whatever skills apply — never
a new role invented at the point of use.

### 4.3 Evidence references

- Evidence is referenced, never inlined in bulk: `CTX-114#L42-58`.
- A claim without an evidence reference cannot be labeled `known`.
- The Consensus Engine rejects any Response Block containing an unlabeled claim.
- An indexed document is cited by `doc:<doc_id>#L<start>-<end>` — the
  lines actually read, never the section id. A section id under a
  `derived` or `assumed` segmentation names a boundary the document did
  not declare, so citing one would attach a claim to a guess.
- A doc-cited fact may carry `quote:` with a span copied from those
  lines. When present it is checked against the source, which turns the
  reference from a pointer into evidence. `scripts/ground-check`
  resolves both forms and fails on a dangling one.

### 4.4 Confidence

- Single calibrated number plus a one-line basis.
- Confidence above 0.9 requires zero `assumed` facts in the decision chain.
- Confidence is about the decision, not about individual facts.

### 4.5 Status semantics

| Status | Meaning | Runtime action |
|---|---|---|
| completed | Objective met within budget | Merge into Evidence Graph |
| blocked | Cannot proceed; missing evidence or budget | Planner re-plans |
| escalated | Risk higher than assigned | Risk upgraded, task re-issued |

---

## 5. Verification Blocks

The Verifier and Challenger use the same Response Block schema with
one additional field:

```yaml
kind: verification          # or: challenge
target_task: T-014
verdict: confirmed          # confirmed | refuted | weakened | inconclusive
verdict_detail: >
  F-1 re-derived independently from CTX-114. F-4 remains the weak point.
```

Rules:
- The Verifier re-derives claims from evidence; it never re-reads the
  original agent's reasoning first (independence requirement).
- The Challenger must produce at least one concrete counter-scenario
  or explicitly state that none could be constructed.

---

## 6. Synthesis Block (Runtime → User)

The only block a user ever sees. Fixed ordering (Principle 7):

```
1. DECISION      — one paragraph, the answer
2. EVIDENCE      — the known/derived facts that matter, with references
3. REASONING     — how evidence leads to the decision
4. RISK          — what could be wrong, what would falsify this
5. CONFIDENCE    — number + basis + open unknowns
```

Assumed and speculative content appears in RISK, never silently in DECISION.

---

## 7. Protocol Violations

The following are hard failures. The Runtime discards the block and
re-issues the task:

1. Free-form output between agents.
2. Unlabeled claims.
3. `known` claim without evidence reference.
4. Decision resting on `speculative` facts.
5. Budget overrun without a `blocked` status.
6. Conclusion accepted from another agent without its evidence attached (Law 2).

---

## Appendix — Amendment Log

**A3 (v1.1 → v1.2).**
- §4 Field Rules: adds §4.2, closing the `role:` vocabulary to the
  agent files the platform ships; former §4.2 becomes §4.3.
- Old text: none. `role:` appeared only in the §2 and §3 examples, both
  spelling it `SecurityAgent`. No rule anywhere said which values were
  legal.
- New text: §4.2 as written above.
- Reason: the silence was load-bearing. A run whose selector returned
  UNRESOLVED chose a specialist by hand and wrote `role: domain-expert`
  in a Task Block — a name it took from the project's own skills
  directory, where it is a skill and not an agent. The Task returned
  "Done" with zero tool uses and no Response Block, the run read that
  silent no-op as a finished task, re-ran the work on a general-purpose
  agent and wrote the block itself. A fabricated specialist's verdict
  reached the gate. Nothing had asked whether the specialist existed,
  because nothing had ever said it must.
- Impact: `tests/fixtures/acp/good-task-block.yaml` asserted
  `role: LegalReviewAgent`, a name with no agent file, and was the only
  evidence anyone had ever considered the question — it is now
  `RequirementsAgent`, and the objective is unchanged. `acp-lint`
  checks the roster on every block kind rather than responses only, so
  the check reaches the Task Block, which is where an invented role is
  written first. Blocks naming real agents are unaffected.

**A1 (v1.0 → v1.1).**
- §2 Task Block: adds the optional `documents:` field — a list of
  `doc_id` plus the `sections` the agent is expected to open.
- §4.2 Evidence references: adds the `doc:<doc_id>#L<start>-<end>`
  citation form and the optional `quote:` companion field.
- Reason: a long document could reach an agent only as a path, and a
  path is an instruction to read all of it. Law 4 says knowledge is
  shared, not context; handing over a whole contract shares context.
  Naming sections in the Task Block, and lines in the citation, makes
  the unit of exchange a slice. The line-not-section rule in the
  citation form exists because `scripts/docindex` labels its
  segmentation `known`, `derived` or `assumed`, and only the first is
  a boundary the source itself declared.
- Impact: `documents:` is optional, so every existing block stays
  valid. `plugins/cereblnk/scripts/acp-lint` validates the new field
  and accepts `doc:` where it previously required `CTX-`;
  `scripts/ground-check` resolves `doc:` references against the index
  and verifies any `quote:` against the cited lines. No agent file
  changes shape.
