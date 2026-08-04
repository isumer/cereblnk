# Cereblnk Runtime Specification

> Status: Frozen v1.0
> This document defines HOW Cereblnk executes work.
> Depends on: 00_MANIFESTO.md
> Consumed by: all agents, skills, and workflows.

---

## 1. Runtime Overview

The Cereblnk Runtime is the stable core of the platform. It is the only
layer that never changes shape as the system grows.

Responsibilities:

1. Detect intent (three-level reading).
2. Build an execution plan and Task Graph.
3. Allocate context budget per task.
4. Spawn ephemeral specialist agents.
5. Merge evidence into the Evidence Graph.
6. Run quality gates (Verifier, Challenger, Consistency).
7. Compose the final decision-oriented response.

---

## 2. Execution Pipeline

Every non-trivial request flows through this pipeline:

```
User Request
    │
    ▼
[1] Intent Engine ──── literal / operational / constraint reading
    │
    ▼
[2] Planner ────────── decompose into independently verifiable tasks
    │
    ▼
[3] Task Graph ─────── DAG of tasks with dependencies + risk scores
    │
    ▼
[4] Budget Manager ─── assign context budget per task (see 03_CONTEXT_OS.md)
    │
    ▼
[5] Agent Scheduler ── spawn specialist agents (parallel where possible)
    │
    ▼
[6] Specialist Agent Mesh
    │   Architecture · Backend · Security · QA · Performance · Docs · ...
    │   (agents communicate ONLY via ACP — see 02_ACP.md)
    │
    ▼
[7] Evidence Graph ─── merged, labeled, source-linked facts
    │
    ▼
[8] Quality Gates ──── Verifier → Challenger → Consistency (risk-scaled)
    │
    ▼
[9] Response Composer ─ Decision → Evidence → Reasoning → Risk → Confidence
    │
    ▼
User
```

### Fast Path

Trivial, low-risk requests (single fact, small localized edit) may skip
steps 3–6 and use a single agent with a lightweight verification pass.
The Intent Engine decides this using the Risk Model (Section 6).
This implements Manifesto Principle 3: spend intelligence where
uncertainty lives.

---

## 3. Runtime Modules

| Module | Responsibility | Stability |
|---|---|---|
| Intent Engine | Three-level intent reading, risk pre-scoring | Core |
| Planner | Task decomposition into verifiable units | Core |
| Task Graph | DAG of tasks, dependencies, risk, budget | Core |
| Budget Manager | Token budget allocation and enforcement | Core |
| Agent Scheduler | Spawning, sequencing, parallelization | Core |
| Context OS | Retrieval, chunking, compression, evidence preservation | Core |
| Evidence Store | Append-only store of labeled facts with sources | Core |
| Verifier | Independent technical re-derivation | Core |
| Challenger | Contrarian refutation attempts | Core |
| Consensus Engine | Cross-agent contradiction detection & resolution | Core |
| Response Composer | Decision-first output assembly | Core |

Future modules (do not design against these yet):
Repository Mapper, Semantic Index, Dependency Analyzer, Risk Estimator,
Cost Optimizer, Memory Manager, Adaptive Compression, Autonomous Planning.

---

## 4. Agent Model

Agents are **ephemeral**. They have no persistent identity between tasks.

Lifecycle:

```
Spawn → Receive objective (ACP task block)
      → Request minimum context (via Context OS, never raw repo access)
      → Execute within budget
      → Self-verify against own quality gates
      → Publish evidence + conclusion (ACP response block)
      → Terminate
```

Agent invariants:

- An agent never owns global state.
- An agent never reads the full conversation history.
- An agent never reads the full repository.
- An agent never exceeds its assigned token budget.
- An agent never outputs free-form text to another agent — ACP only.
- An agent never decides outside its expertise (Law 1).

### Standing Agent Roles (Phase 1 core set)

| Role | Decides on | May only advise on |
|---|---|---|
| PlannerAgent | task decomposition, ordering | everything else |
| ArchitectAgent | structure, boundaries, patterns | implementation detail |
| BackendAgent | implementation correctness | architecture, security |
| SecurityAgent | vulnerabilities, authz/authn, secrets | performance |
| QAAgent | test coverage, test correctness | design |
| PerformanceAgent | complexity, hotspots, resource use | security |
| DocsAgent | documentation accuracy & completeness | code decisions |
| VerifierAgent | technical validity of any claim | — |
| ChallengerAgent | refutation, counter-arguments | — |
| SynthesizerAgent | final composition | domain conclusions |

The role list grows over time; the invariants never change.

---

## 5. Task Graph

Each node in the Task Graph carries:

```yaml
task_id: string            # unique within the run
objective: string          # one sentence, verifiable
depends_on: [task_id]
assigned_role: string      # e.g. SecurityAgent
risk: low | medium | high  # from Risk Model
budget_tokens: integer     # from Budget Manager
verification_level: 1 | 2 | 3   # from Quality Gates policy
acceptance: string         # what "done and correct" means, testable
```

Rules:

- A task with an untestable acceptance criterion is rejected by the Planner.
- Tasks are sized so a single agent can complete them within 5–10K input tokens.
- Independent tasks run in parallel by default.

---

## 6. Risk Model

Risk drives everything: verification depth, agent count, budget.

| Risk | Signals | Consequence |
|---|---|---|
| Low | read-only questions, isolated edits, no prod impact | Fast path, verification level 1 |
| Medium | multi-file changes, API changes, data model touches | Full pipeline, verification level 2 |
| High | security surface, migrations, auth, money, deletion, prod config | Full pipeline, verification level 3, Challenger mandatory |

The Intent Engine assigns an initial risk score; any agent may escalate
risk upward at any time. Risk is never silently downgraded.

---

## 7. Naming Conventions

- Runtime modules are nouns: `IntentEngine`, `BudgetManager`.
- Agents end with `Agent`: `SecurityAgent`.
- Workflows end with `Workflow`: `PRReviewWorkflow`.
- Protocols end with `Protocol`: `AgentCommunicationProtocol`.
- SDK components end with `SDK`.
- All names are original. No names borrowed from reference projects.

---

## 8. Repository Layout

```
.claude/cereblnk/
    runtime/        # runtime module specs & configs
    agents/         # agent definitions (one file per agent)
    skills/         # domain skills (see Skill Model)
    workflows/      # multi-agent workflow definitions
    protocols/      # ACP and other protocols
    templates/      # ACP block templates, output templates
    schemas/        # machine-readable schemas (YAML/JSON)
    policies/       # quality gates, risk model, budget policy
    memory/         # persisted knowledge artifacts (never raw context)
    context/        # context OS configuration
    telemetry/      # run metadata for later analysis
docs/
tests/
scripts/
```

---

## 9. Skill Model

A skill is **executable knowledge** — it defines how to think in a domain,
not just what to do. Every skill file contains, in order:

1. **Identity** — name, domain, version.
2. **Mission** — one sentence.
3. **Philosophy** — how an expert in this domain thinks: the thinking-style
   layer — epistemology, priorities, instincts.
4. **Decision Strategy** — how tradeoffs are resolved in this domain.
5. **Inputs** — what evidence the skill needs.
6. **Outputs** — ACP-formatted, always.
7. **Quality Gates** — domain-specific correctness checks.
8. **Failure Modes** — the known ways this domain goes wrong.
9. **Examples** — at least one worked example.

Skills never communicate directly with users. Skills are invoked by agents.

---

## 10. Workflow Model

```
Workflow = Planning + Agent Orchestration + Verification + Delivery
```

A workflow definition specifies:

- Trigger (what user intent activates it).
- Agent sequence / mesh topology (including allowed feedback loops,
  e.g. Architect → Security → Architect).
- Per-stage budgets.
- Quality gate policy for the workflow's typical risk level.
- Output template.

Phase 1 workflows: `PRReviewWorkflow`, `BugInvestigationWorkflow`.
Later: FeatureDesign, IncidentResponse, Refactoring, Release, ADR,
PerformanceAudit.

---

## 11. Scale Targets (Directional, Not Commitments)

Long-term direction: tens of agents, 100+ skills, dozens of workflows.

**Binding Phase 1 target instead:**

- 10 core agents (Section 4 table)
- 2 workflows, end-to-end functional
- ACP fully implemented and enforced
- Context OS with budget enforcement
- Quality gates at all three levels

Nothing else ships until Phase 1 works end to end.

---

## 12. Roadmap

| Phase | Name | Contents |
|---|---|---|
| 1 | Foundation | Runtime core, ACP, Context OS, 10 agents, 2 workflows |
| 2 | Engineering Agents | Domain skills (Java, Spring, K8s, React, SQL, DevSecOps...) |
| 3 | Enterprise Workflows | Incident, Release, ADR, Performance Audit |
| 4 | Adaptive Intelligence | Memory, adaptive compression, autonomous planning |

---

## Appendix — Amendment Log

**A2 (v1.0 → v1.1).**
- Runtime state path: every `.cereblnk/<subdir>` reference becomes
  `.claude/cereblnk/<subdir>`, resolved from `CLAUDE_PROJECT_DIR`
  (falling back to `$PWD`), never from `$HOME` and never from a
  hook's incidental working directory.
- Reason: hooks and scripts used bare relative paths, so runtime state
  (flags, config, memory, plans, telemetry) landed wherever the process
  happened to start — in practice under the user's home Claude
  directory rather than the project. Anchoring makes per-project state
  actually per-project, and consolidates it beside `.claude/BACKLOG.md`.
- Impact: mechanical path update across agents, policies, commands,
  skills, tests, and examples; `scripts/lib/cbenv.sh` exports `CB_DIR`
  as the single source of the location. No semantics changed — what is
  written, by whom, and under which rules is untouched.

**A3.**
- Section: §8 Repository Layout. `examples/` removed from the repository layout.
- Old text: the layout listed `examples/` between `docs/` and `tests/`.
- New text: the entry is gone; `docs/`, `tests/` and `scripts/` follow
  each other directly.
- Reason: the directory held a Phase-2 placeholder announcing that
  worked examples would arrive later, plus two standards samples. The
  placeholder had outlived its usefulness and the samples duplicated
  what `.claude/cereblnk/memory/repository/standards/` documents in
  place. It was deleted; the layout described a directory the
  repository no longer has.
- Impact: description only. No agent, skill, workflow, policy or gate
  reads `examples/`; reproducible fixtures live under `tests/` and are
  unaffected.
