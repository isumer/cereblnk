# Cereblnk Platform Catalog

> Status: Frozen v1.0 (catalog scope) / Living (item details)
> This document synthesizes the full capability scope of Cereblnk:
> every workflow, agent, domain skill, hook, and utility the platform
> will ship across Phases 1–4.
>
> Scope benchmark: full software lifecycle coverage — ideation through
> post-deploy monitoring and retrospectives — at parity with or exceeding
> the most comprehensive reference toolkits (~40 capabilities), while
> remaining architecturally Cereblnk: workflow-first, agent-backed,
> evidence-driven, verified before delivery.
>
> Depends on: 00–05 core documents, 07_BUILD_INSTRUCTIONS.md.
> Naming is 100% original per 01 §7. Reference projects contributed
> ideas only — zero names, commands, structures, or prompt text.

---

## 1. Synthesis Decisions

Three inputs were synthesized. What was kept and what was corrected:

| Input | Kept | Corrected |
|---|---|---|
| Verb-per-command tree (plan/implement/review/security/...) | The lifecycle coverage list — every verb becomes a **workflow** | Commands are not specialists. Specialists are agents; commands are workflow entry points. `plugin.yaml`, `prompts/` → replaced with the verified plugin format |
| A broad lifecycle toolkit | Full-lifecycle coverage: ideation → plan gates → build → verify → ship → deploy → watch → learn. Safety guardrails via hooks. Session memory. Readiness dashboards | Single-context "cognitive modes" → true subagents with context isolation (Law 4). Personality-driven prompts → Cognitive Contract + ACP. Real-browser tooling → F-class, deferred (Reality Map) |
| Cereblnk core docs | Everything. The runtime, ACP, Context OS, and gates are non-negotiable | Catalog breadth expanded far beyond the original Phase 1 sketch — via Phases 2–4, not by inflating Phase 1 |

**The structural rule that resolves all three inputs:**
Every capability = one thin **command** (entry point) → one **workflow**
(topology + gates) → several **agents** (expertise) → optional **domain
skills** (how to think in a stack). Nothing is a bare prompt.

---

## 2. Repository Layout (final, supersedes 07 §2.1 tree)

```
cereblnk/                                    # repo root = marketplace
├── .claude-plugin/marketplace.json
├── plugins/cereblnk/
│   ├── .claude-plugin/plugin.json
│   ├── commands/                            # thin workflow entry points (§3)
│   ├── agents/
│   │   ├── core/                            # runtime agents (§4.1)
│   │   ├── engineering/                     # specialist agents (§4.2)
│   │   ├── lifecycle/                       # product/release agents (§4.3)
│   │   └── context/                         # Context OS micro-agents (§4.4)
│   ├── skills/
│   │   ├── languages/                       # §5.1
│   │   ├── frameworks/                      # §5.2
│   │   ├── data/                            # §5.3
│   │   ├── infrastructure/                  # §5.4
│   │   ├── delivery/                        # §5.5
│   │   └── practices/                       # §5.6
│   ├── hooks/                               # hard enforcement only (§6)
│   ├── protocols/                           # ACP templates + schemas
│   ├── policies/                            # risk, budget, gates
│   └── README.md
├── docs/                                    # core documents 00–08
├── tests/
└── README.md
```

---

## 3. Workflow Catalog (22 workflows)

Every workflow: fixed output ordering (Decision → Evidence → Reasoning →
Risk → Confidence), risk-scaled gates, per-stage budgets.

### 3.1 Conception & Planning

| Command | Workflow | Purpose | Phase |
|---|---|---|---|
| `/cb-frame` | IntentFramingWorkflow | Before any code: three-level intent reading at product scale. Challenges the literal request, extracts falsifiable premises the user confirms/rejects, proposes 2–3 sized implementation paths, writes a design brief to `.claude/cereblnk/memory/briefs/` that downstream workflows consume | 2 |
| `/cb-design` | FeatureDesignWorkflow | Turns a brief into an executable spec: architecture, data flow, state transitions, failure modes, trust boundaries, diagrams (mandatory — diagrams force hidden assumptions into the open), test matrix | 2 |
| `/cb-product-gate` | ProductGateWorkflow | ProductStrategyAgent pass over a plan: scope modes (expand / hold / reduce), 10x-version search, premise validation. Advisory gate | 3 |
| `/cb-ux-gate` | ExperienceGateWorkflow | UXAgent pass over a plan: state coverage (empty/loading/error/mobile), information hierarchy, generic-AI-look risk, scored 0–10 per dimension with fixes | 3 |
| `/cb-plan-pipeline` | PlanPipelineWorkflow | Runs Product → UX → Engineering gates sequentially with encoded auto-resolution principles; only taste decisions surface to the user. Readiness dashboard at the end | 3 |

### 3.2 Build & Verify

| Command | Workflow | Purpose | Phase |
|---|---|---|---|
| `/cb-do` | DirectExecutionWorkflow | Direct execution from a request: no spec, no design phase, no plan to approve. Reads the request three ways, selects specialists with `select-agents --text`, writes an internal task list only when the work exceeds one task, then runs the standard execution loop. Stops for confirmation only where the work is irreversible | 2 |
| `/cb-implement` | ImplementationWorkflow | Executes an approved spec task-by-task: Planner slices, specialists build, Verifier checks each slice before the next starts | 2 |
| `/cb-pr-review` | PRReviewWorkflow | The flagship. Production-incident hunting: N+1, races, trust boundaries, stale reads, missing enum handlers, retry logic, tests that pass while missing the failure mode. Mechanical fixes auto-applied with per-fix commits; judgment calls surfaced | **1** |
| `/cb-bug` | BugInvestigationWorkflow | Iron rule: no fix without root cause. Hypothesis-driven tracing, one hypothesis at a time; after 3 failed fixes, stops and questions the architecture instead of thrashing | **1** |
| `/cb-qa` | QAWorkflow | Diff-aware test pass: reads the branch diff, identifies affected surfaces, executes the test plan produced by FeatureDesignWorkflow, generates a regression test for every confirmed fix | 2 |
| `/cb-refactor` | RefactoringWorkflow | Behavior-preserving restructuring with invariant checklist before/after; edit-boundary hook auto-engaged | 2 |
| `/cb-security-audit` | SecurityAuditWorkflow | OWASP Top 10 + threat-model sweep; findings with severity, evidence reference, and fix. Always gate level 3 | 2 |
| `/cb-perf-audit` | PerformanceAuditWorkflow | Complexity hotspots, query plans, resource baselines; before/after comparison mode for PRs | 3 |
| `/cb-health` | CodeHealthWorkflow | Wraps type checker, linter, tests, dead-code detection into a weighted 0–10 score; trend tracked in `.claude/cereblnk/telemetry/` | 3 |

### 3.3 Ship & Operate

| Command | Workflow | Purpose | Phase |
|---|---|---|---|
| `/cb-release` | ReleaseWorkflow | Final mile: sync main, run tests, coverage audit of the diff (gaps get tests generated), changelog/version updates, push, PR creation. Checks gate readiness before creating the PR | 3 |
| `/cb-deploy` | DeployWorkflow | Merge → CI wait → deploy wait → production health verification. First run on a project is a dry-run walkthrough | 3 |
| `/cb-watch` | ProductionWatchWorkflow | Post-deploy monitoring loop: errors, regressions, page failures vs pre-deploy baseline | 3/4* |
| `/cb-incident` | IncidentResponseWorkflow | Live-issue triage: impact scoping, mitigation-first ordering, root cause deferred to BugInvestigation, postmortem artifact | 3 |

### 3.4 Knowledge & Team

| Command | Workflow | Purpose | Phase |
|---|---|---|---|
| `/cb-docs` | DocumentationWorkflow | Cross-references every doc file against the diff; updates drifted paths, structures, counts; risky rewrites surfaced as questions | 2 |
| `/cb-changelog` | ChangelogWorkflow | Conventional-commit-driven changelog and version bump proposal | 3 |
| `/cb-adr` | ADRWorkflow | Architecture Decision Records: context, options, decision, consequences — with Challenger pass on the chosen option | 3 |
| `/cb-retro` | RetrospectiveWorkflow | Data-driven retro from git history: velocity, test-ratio trends, hotspot files, per-contributor breakdowns, growth items. Snapshot persisted for trend comparison | 3 |
| `/cb-memory` | MemoryWorkflow | Review / search / prune / export what Cereblnk learned about this project (`.claude/cereblnk/memory/`). Stale entries (referencing deleted files) flagged for pruning | 4 |

Session continuity (save/restore working state across sessions) ships as
two utility commands `/cb-save` and `/cb-resume` backed by
ContextArchivistAgent — Phase 4.

*ProductionWatch depends on log/browse tooling availability → F-class
until the Reality Map confirms a mechanism; ships degraded (log-file and
health-endpoint based) in Phase 3.

---

## 4. Agent Roster (28 agents)

### 4.1 Core runtime agents (Phase 1)

PlannerAgent · VerifierAgent · ChallengerAgent · ConsistencyAgent ·
SynthesizerAgent

### 4.2 Engineering specialists

| Agent | Decision domain | Phase |
|---|---|---|
| ArchitectAgent | structure, boundaries, patterns | 1 |
| BackendAgent | server-side implementation correctness | 1 |
| FrontendAgent | UI implementation, state management, rendering | 2 |
| SecurityAgent | vulnerabilities, authn/authz, secrets, trust boundaries | 1 |
| QAAgent | test coverage, test correctness, regression design | 1 |
| PerformanceAgent | complexity, hotspots, resource use | 1 |
| DatabaseAgent | schema, migrations, query correctness | 2 |
| APIDesignAgent | contract design, versioning, compatibility | 2 |
| RefactoringAgent | behavior-preserving transformations | 2 |
| DebuggerAgent | root-cause investigation methodology | 2 |
| InfraAgent | containers, orchestration, IaC correctness | 2 |
| SREAgent | reliability, observability, incident mitigation | 3 |

### 4.3 Lifecycle specialists

| Agent | Decision domain | Phase |
|---|---|---|
| ProductStrategyAgent | scope, premises, product framing | 3 |
| UXAgent | interaction states, hierarchy, experience quality | 3 |
| ReleaseAgent | branch hygiene, versioning, PR mechanics | 3 |
| DeployAgent | deploy pipeline execution and verification | 3 |
| TechnicalWriterAgent | documentation accuracy and completeness | 2 |
| ComplianceAgent | licenses, data handling, policy conformance | 4 |
| RetroAnalystAgent | delivery metrics, trends, team patterns | 3 |

### 4.4 Context OS micro-agents (per 03 §7)

ContextPlannerAgent · ChunkBuilderAgent · CompressionAgent ·
EvidenceCollectorAgent · MergeAgent · ContextArchivistAgent ·
MemoryBuilderAgent — Phases 1–4 as needed (Merge + EvidenceCollector
in Phase 1).

Count: 5 core + 12 engineering + 7 lifecycle + 7 context ≈ **28+ agents**,
each with Law 1 boundaries, budgets, and ACP compliance per 07 §4.1.

---

## 5. Domain Skill Catalog (40+ skills)

Every skill follows the 9-section structure (01 §9); **Philosophy** —
how an expert thinks in this domain — is the load-bearing section.
All Phase 2+ unless noted. Directory = `skills/<group>/<name>/SKILL.md`.

**5.1 languages/** — java · kotlin · typescript · javascript · python ·
go · sql · shell

**5.2 frameworks/** — spring-boot · spring-security · hibernate-jpa ·
react · angular · nextjs · nodejs · junit-testing · playwright-testing

**5.3 data/** — postgresql · oracle · redis · elasticsearch ·
liquibase-migrations · query-optimization · data-modeling

**5.4 infrastructure/** — docker · kubernetes · helm · terraform ·
nginx · linux-ops · cloud-architecture · observability

**5.5 delivery/** — jenkins-pipelines · github-actions · bitbucket-pipelines ·
git-strategy · release-engineering · artifact-management

**5.6 practices/** — devsecops · owasp-threat-modeling · api-design ·
event-driven-architecture · microservices · performance-engineering ·
accessibility · technical-writing · code-review-craft · legacy-modernization

The user's stack (Java, Spring, Angular, React, SQL, Kubernetes, Docker,
Jenkins, Bitbucket, GitHub, Terraform) is fully covered and prioritized
first within Phase 2.

---

## 6. Hooks — Hard Enforcement Layer (Phase 1–2)

Hooks are the scarce real-enforcement resource (Reality Map #3).
Cereblnk ships exactly seven (Amendments A1–A3):

| Hook | Enforces | Command |
|---|---|---|
| DestructiveCommandHook | warns before irreversible shell ops (recursive delete, force-push, hard reset, table drops); routine build-artifact cleanups allowlisted | `/cb-careful` |
| EditBoundaryHook | blocks Edit/Write outside a declared directory during focused work; auto-engaged by RefactoringWorkflow and BugInvestigationWorkflow | `/cb-boundary <path>` |
| PostEditTestHook | runs the affected test subset after edits in gate-level-3 work | policy-driven |
| SecretGuardHook | fail-closed redaction check before any artifact leaves the run | always on |
| DelegationGuardHook | while a run is armed, blocks Edit/Write from the conducting conversation (no `agent_id` in hook input) — file edits belong to surface specialist subagents; subagent edits pass | always on during runs, flag-released |
| RunGuardHook | blocks the FIRST stop while `$CB_DIR/flags/run-active` is armed (one continue-nudge for runs whose subagent results land between turns), then disarms itself | always on, self-disarming |
| HistoryArchiveHook | archives the session transcript to `<project>/.claude/history/` before compaction (manual and auto) discards detail | always on |

Honest note: edit-boundary hooks block tools, not shell side-effects —
accident prevention, not a sandbox. Documented as such.

---

## 7. Where Cereblnk Deliberately Differs

These are commitments, not omissions:

1. **No persona prompts.** Reference toolkits encode "modes" as
   personality text in one shared context. Cereblnk encodes expertise as
   subagents with isolated context, ACP outputs, and Law 1 boundaries —
   verification is structural, not stylistic.
2. **No unverified output.** Every workflow ends at risk-scaled gates.
   Reference toolkits treat review as one command among many; Cereblnk
   treats it as a property of every command.
3. **Cross-agent contradiction detection** (ConsistencyAgent) has no
   reference equivalent — it exists because we run many agents.
4. **Real-browser tooling is F-class.** Binary daemons and headed
   browsers are out of scope until the Reality Map confirms a shippable
   mechanism inside plugin constraints. QAWorkflow ships evidence-based
   (tests + diff analysis) first. This is stated, not hidden.
5. **Epistemic labels survive to the user.** No reference toolkit
   distinguishes Known from Assumed in its final output. Cereblnk always does.

---

## 8. Phase Mapping (updates 07 §3.2 — CB-001..012 unchanged)

| Phase | Ships | Catalog items |
|---|---|---|
| 1 — Foundation | runtime, ACP, gates, 10 core agents, 2 workflows, 4 hooks | CB-001..012 |
| 2 — Engineering | 8 workflows (§3.2 + frame/design/docs), 8 agents, ~25 priority-stack skills | CB-013..040 |
| 3 — Lifecycle | 10 workflows (§3.1 gates + §3.3 + retro/adr/changelog), 7 agents, remaining skills | CB-041..070 |
| 4 — Adaptive | memory workflows, session continuity, compliance, telemetry trends, adaptive compression | CB-071+ |

Backlog IDs beyond CB-012 are allocated when their phase opens —
BACKLOG.md remains the single live source.

---

## Appendix — Amendment Log

**A1 (v1.0 → v1.1).**
- §6: hook count four → five; added HistoryArchiveHook (PreCompact).
- Reason: compaction is irreversible information loss, squarely inside
  the hook budget's mandate (Reality Map consequence #3:
  irreversible-damage prevention). User-requested after field use.
- Impact: hooks.json gains a PreCompact entry; hook fails open always
  (an archive failure never blocks compaction); retention default 20,
  configurable via `.claude/cereblnk/config/history-keep`.

**A2 (v1.1 → v1.2).**
- §6: hook count five → six; added RunGuardHook (Stop event).
- Reason: a backgrounded/between-turns subagent completion does not
  wake the conversation — runs stalled until the user typed. One
  loop-proof nudge (stop_hook_active respected; flag renamed after
  the single block) resumes them.
- Impact: hooks.json gains a Stop entry; orchestrator manages the
  run-active flag lifecycle (armed at execution start, removed before
  any user question and at synthesis).

**A3 (v1.2 → v1.3).**
- §6: hook count six → seven; added DelegationGuardHook (PreToolUse:
  Edit|Write|MultiEdit|NotebookEdit, first in the edit chain).
- Reason: three PRs of instructions could not stop the conductor from
  implementing; the platform now distinguishes subagent tool calls
  (`agent_id`/`agent_type` in hook input, per current docs), making
  delegation mechanically enforceable — the Reality Map's own
  standard: promote D to M when a mechanism appears. Safe under the
  older platform behavior too (subagent calls bypassing hooks pass
  implicitly).
- Impact: conductor edits mid-run exit 2 with a spawn-the-specialist
  reason; escape hatch = removing `flags/run-active`.

**A4 (v1.3 → v1.4).**
- §3.2 gains DirectExecutionWorkflow (`/cb-do`, CB-101).
- Reason: the catalog offered no path from a stated request to running
  code. `/cb-frame → /cb-design → /cb-implement` serves work whose
  shape is unknown; a bounded, stated change paid that cost for
  nothing, and the observed result was users routing around the
  workflows entirely.
- Impact: one command, one workflow row. No agent, no gate, and no
  policy changed — `/cb-do` binds `execution-loop-policy.md` as it
  stands. Nothing was weakened: risk still raises the gate level, and
  irreversible work still stops for confirmation.

**A5 (v1.4 → v1.5).**
- Section: §2 Repository Layout. `examples/` removed from the repository layout.
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
