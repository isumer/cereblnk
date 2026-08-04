# Context Operating System (Context OS)

> Status: Frozen v1.0
> This document defines how Cereblnk manages context.
> Depends on: 00_MANIFESTO.md (Law 4, Law 5), 01_RUNTIME_SPECIFICATION.md
> This is the module where Cereblnk's main innovation lives.

---

## 1. Core Rule

> **Context is not shared. Knowledge is shared.** (Law 4)

No agent ever reads:
- the full repository,
- the full conversation history,
- another agent's raw context.

Every agent receives only compressed, evidence-preserving knowledge bundles
(`CTX-*` references) sized to its objective.

---

## 2. Budget Policy

**Global target:** total operational context stays below **50% of the
available model context window** at all times. The remaining half is
reserve: verification headroom, escalation, and safety margin.

The budget is managed dynamically by the Budget Manager — never hardcoded.

### Reference allocation (example for a 128K window → 64K operational)

```
Available operational budget          64K
├── Planner                            4K
├── Specialist agents (parallel)      ~6–8K each
│     Architect                        8K
│     Security                         6K
│     QA                               6K
│     Backend                          8K
├── Evidence Merge                     4K
├── Verifier                           4K
├── Challenger                         4K
├── Synthesis                          6K
└── Reserve                        remainder
```

Rules:
- Each agent knows its budget (ACP `budget_tokens`) and reports usage
  (ACP `budget_report`).
- Exceeding budget without declaring `blocked` is a protocol violation.
- The Budget Manager may reallocate reserve to escalated high-risk tasks.
- Individual agent working sets target **5–10K tokens** regardless of
  repository size.

---

## 3. Tree of Context

Conventional agent chains pass context linearly (A → B → C), so context
grows monotonically. Cereblnk uses a tree instead:

```
                Root Context (intent + constraints only)
                        │
        ┌───────────────┼───────────────┐
        │               │               │
     Task 1          Task 2          Task 3
   (own 5–10K)     (own 5–10K)     (own 5–10K)
        │               │               │
     Summary         Summary         Summary
        └───────────────┼───────────────┘
                        │
                  Evidence Merge
                        │
                    Verifier
                        │
                 Merged Summary
                        │
                     Final
```

Properties:
- Sibling tasks never see each other's raw context.
- Only evidence-preserving summaries travel upward.
- Depth is bounded; width scales with repository size.
- A million-line repository is analyzable because no single node ever
  needs more than its local working set.

---

## 4. Context Pipeline

```
Repository
    │
    ▼
Dependency Graph ──── what depends on what (imports, calls, configs)
    │
    ▼
Semantic Graph ────── what is about what (domain concepts ↔ files)
    │
    ▼
Chunk Builder ─────── objective-driven slices, 5–10K each
    │
    ▼
Parallel Agents ───── each consumes only its chunks
    │
    ▼
Evidence Merge ────── labeled facts merged into Evidence Graph
    │
    ▼
Evidence-Preserving Compression (see Section 5)
    │
    ▼
Consistency Check ─── contradictions between summaries detected
    │
    ▼
Final Context ─────── what synthesis actually sees
```

---

## 5. Evidence-Preserving Compression

A summary is **not** a paraphrase. It is a compressed structure that keeps:

1. **Every epistemic label** (known/derived/estimated/assumed/speculative).
2. **Every evidence reference** (`CTX-114#L42-58` survives compression).
3. **Every unknown and risk** (these are never compressed away).
4. **The fact IDs** (so cross-references remain resolvable).

What compression is allowed to drop:
- Reasoning prose (re-derivable from facts).
- Redundant restatements.
- Context that produced no facts.

**Ordering rule:** compression happens only **after** evidence extraction,
never before. Compressing raw context first destroys evidence.

---

## 6. Role-Scoped Retrieval

Different agents receive different slices of the same repository.
Example — a Spring Boot project:

| Agent | Receives |
|---|---|
| SecurityAgent | SecurityConfig, JWT/OAuth code, controllers, filters |
| BackendAgent | services, domain model, business logic |
| DatabaseAgent | repositories, Liquibase/migrations, SQL |
| QAAgent | test sources, JUnit/Playwright configs, coverage reports |
| PerformanceAgent | hot paths flagged by dependency graph, pool configs |
| DocsAgent | READMEs, ADRs, API specs |

The Chunk Builder computes these slices from the Dependency Graph and
Semantic Graph, filtered by the agent's role and task objective.

---

## 7. Context Support Agents

Context management is itself agentic. Dedicated micro-agents:

| Agent | Job |
|---|---|
| ContextPlannerAgent | decides what knowledge each task needs |
| ChunkBuilderAgent | cuts objective-driven slices |
| CompressionAgent | evidence-preserving compression |
| EvidenceCollectorAgent | extracts labeled facts from chunks |
| MergeAgent | merges facts into the Evidence Graph |
| ConsistencyAgent | detects contradictions across summaries |
| ContextArchivistAgent | stores reusable bundles under `.claude/cereblnk/memory/` |
| MemoryBuilderAgent | promotes stable knowledge into persistent memory |

These agents follow ACP like every other agent.

---

## 8. Principles Summary

1. Never load unnecessary files.
2. Prefer semantic retrieval over path-based loading.
3. Compress only after evidence extraction.
4. Preserve references through every transformation.
5. Merge incrementally, verify at every merge.
6. Total operational budget < 50% of model context, always.

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
