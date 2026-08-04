# Cereblnk Documentation Index

The one-page entry point. Documents 00 + 09 together are the
constitution — a separate constitution document was deliberately
rejected: a third normative source invites drift.

## Reading order

**First pass (why and how to think):**

| Doc | Role in one sentence |
|---|---|
| `00_MANIFESTO.md` | Why Cereblnk exists: the Cognitive Contract (10 principles) and the Five Laws every agent obeys. |
| `09_COGNITIVE_OPERATIONS_MANUAL.md` | How to execute the contract: eight procedures, the false-competence catalog, the per-skill philosophy standard, the five-question self-test. |

**Second pass (the machine):**

| Doc | Role in one sentence |
|---|---|
| `01_RUNTIME_SPECIFICATION.md` | The execution pipeline, agent model, task graph, risk model, and naming rules. |
| `02_AGENT_COMMUNICATION_PROTOCOL.md` | The only format agents may use to exchange information (task/response/verification/synthesis blocks). |
| `03_CONTEXT_OS.md` | How context is budgeted, sliced (Tree of Context), and compressed without destroying evidence. |
| `04_QUALITY_GATES.md` | What must be true before any answer reaches the user: Verifier, Challenger, Consistency, risk-scaled. |

**Third pass (reality and delivery):**

| Doc | Role in one sentence |
|---|---|
| `05_EXECUTION_REALITY_MAP.md` | Living map from every concept to its real Claude Code mechanism (M), discipline (D), or future (F) class. |
| `06_PROJECT_INSTRUCTIONS.md` | Original collaboration ground rules (superseded by 07, kept for history). |
| `07_BUILD_INSTRUCTIONS.md` | How the plugin is built and delivered: backlog protocol, artifact standards, amendment protocol. |
| `08_PLATFORM_CATALOG.md` | The full capability scope: 22 workflows, 28 agents, 40+ skills, 4 hooks, phased. |

**Working documents:** `COVERAGE.md` (capability map),
`.claude/BACKLOG.md` (live task source of truth).

## Precedence on conflict

00 governs everything; 09 operationalizes 00; 01–04 must stay
consistent with both; 05 constrains all designs to reality; 07/08
govern delivery and scope. Frozen documents change only by recorded
amendment (07 §8).
