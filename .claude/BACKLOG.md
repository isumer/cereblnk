# Cereblnk Backlog

> Status: Living document. Location: `.claude/BACKLOG.md` — the only copy.
>
> **A one-line index of what shipped.** What each task did, and why,
> lives in `CHANGELOG.md`; the diffs live in git. Task blocks used to be
> reproduced here in full after closing, which grew the file to 74KB of
> history that nothing read.
>
> **Workflow per task**
> 1. Implemented on branch `cb/CB-XXX-slug`
> 2. Reviewed and merged into `main`, conventional commit title
> 3. Checkbox ticked with the merge
> 4. `./scripts/verify` green before any push
>
> **Rules.** A task with an untestable acceptance criterion is invalid
> (07 §3.1). No task may depend on an F-class mechanism
> (05_EXECUTION_REALITY_MAP.md). Prior art is described by class, never
> by name (00 §6, 01 §7).

---

## Closed

One line each. The full record of what shipped and why lives in
`CHANGELOG.md` from CB-013 onward, and in the commit history
throughout; the diffs live in git. Reproducing acceptance criteria and
deliverable lists here made this file 74KB of history that nothing
read.

- [x] **CB-001** — Marketplace and plugin manifests, repo scaffolding
- [x] **CB-002** — ACP templates and protocol README
- [x] **CB-003** — Risk model, budget policy, and gate policy
- [x] **CB-004** — Orchestrator entry: three-level intent reading and fast path
- [x] **CB-005** — PlannerAgent definition
- [x] **CB-006** — Verifier, Challenger, and Synthesizer gate agents
- [x] **CB-007** — Six engineering specialist agents
- [x] **CB-008** — /cb-pr-review workflow command
- [x] **CB-009** — /cb-bug workflow command
- [x] **CB-010** — Hard-enforcement hooks and opt-in commands
- [x] **CB-011** — Manual end-to-end scenarios for both Phase 1 workflows
- [x] **CB-012** — Core documents 00–09 and CONTRIBUTING.md published
- [x] **CB-013** — Phase 1 completion audit & repair
- [x] **CB-014** — Specialist agents, batch 1
- [x] **CB-015** — Specialist agents, batch 2
- [x] **CB-016** — /cb-frame (IntentFramingWorkflow)
- [x] **CB-017** — /cb-design (FeatureDesignWorkflow)
- [x] **CB-018** — /cb-implement (ImplementationWorkflow)
- [x] **CB-019** — /cb-qa (QAWorkflow)
- [x] **CB-020** — /cb-refactor (RefactoringWorkflow)
- [x] **CB-021** — /cb-security-audit (SecurityAuditWorkflow)
- [x] **CB-022** — /cb-docs (DocumentationWorkflow)
- [x] **CB-023** — skills/languages batch 1
- [x] **CB-024** — skills/languages batch 2
- [x] **CB-025** — skills/frameworks batch 1 (Spring)
- [x] **CB-026** — skills/frameworks batch 2 (UI)
- [x] **CB-027** — skills/frameworks batch 3 (testing)
- [x] **CB-028** — skills/data batch 1
- [x] **CB-029** — skills/data batch 2
- [x] **CB-030** — skills/infrastructure batch 1
- [x] **CB-031** — skills/infrastructure batch 2
- [x] **CB-032** — skills/delivery batch 1
- [x] **CB-033** — skills/delivery batch 2
- [x] **CB-034** — skills/practices batch 1
- [x] **CB-035** — skills/practices batch 2
- [x] **CB-036** — Reference coverage & originality audit
- [x] **CB-037** — Phase 2 test scenarios + docs update
- [x] **CB-038** — Working Memory hierarchy — status: done
- [x] **CB-039** — MemoryBuilderAgent + ContextArchivistAgent — status: done
- [x] **CB-040** — Evidence Index — status: done
- [x] **CB-041** — Consensus mechanics — status: done
- [x] **CB-042** — Context budget telemetry — status: done
- [x] **CB-043** — Orchestrator hardening — status: done
- [x] **CB-044** — Agent selection policy — status: done
- [x] **CB-045** — Repository map script — status: done
- [x] **CB-046** — Reader's guide + review disposition — status: done
- [x] **CB-047** — Dispatch skill (proactive workflow routing) — status: done
- [x] **CB-048** — Security-finding contract enforcer — status: done
- [x] **CB-049** — Security skill content pass — status: done
- [x] **CB-050** — RequirementsAgent + requirements-engineering skill + /cb-requirements
- [x] **CB-051** — Durable plan artifact: format, linter, status (the advisory-loop core)
- [x] **CB-052** — Durable execution loop: fresh executor, staged review, resume, stop-rule
- [x] **CB-053** — TestEngineerAgent
- [x] **CB-054** — Pyramid skills: test-strategy, unit-testing, integration-testing
- [x] **CB-055** — Automation + specialized-layer skills: bdd-gherkin, selenium-webdriver, component-testing, functional-testing
- [x] **CB-056** — Wire test skills into QAWorkflow + agent-selection-policy
- [x] **CB-057** — languages: python, go, kotlin
- [x] **CB-058** — frameworks: nodejs, nextjs
- [x] **CB-059** — data: oracle, redis, elasticsearch
- [x] **CB-060** — infrastructure: nginx, linux-ops, cloud-architecture, observability
- [x] **CB-061** — delivery: release-engineering, artifact-management
- [x] **CB-062** — practices: event-driven-architecture, microservices, performance-engineering, accessibility, technical-writing, legacy-modernization
- [x] **CB-063** — Agent frontmatter enrichment (skills / disallowedTools / model)
- [x] **CB-064** — Document extraction (docx/xlsx/pptx/pdf) — status: done
- [x] **CB-065** — OCR fallback (F-class) — status: done
- [x] **CB-066** — Skill relations metadata (requires / complements / escalate_to)
- [x] **CB-067** — XML/XSD create, parse, validate (tooling + skill)
- [x] **CB-068** — coding-standards skill + project standards bundle format
- [x] **CB-069** — DevSecOps deepening: supply chain, paved road, policy-as-code
- [x] **CB-070** — Integration hardening (reverted, then corrected)
- [x] **CB-071** — Windows Python + project-anchored runtime state
- [x] **CB-073** — Context ledger (root cause: 128K overflow, 37-minute run lost)
- [x] **CB-074** — HistoryArchiveHook (PreCompact)
- [x] **CB-075** — Run plan file
- [x] **CB-076** — Disposition record for the reverted integration work
- [x] **CB-077** — Run continuity + root-resolution hardening
- [x] **CB-078** — Implementation isolation (second 128K incident)
- [x] **CB-085** — Context gates (tool output · declared files · attempt ceiling)
- [x] **CB-086** — Artifact lifecycle (ownership · history/ · state.md · staleness gate)
- [x] **CB-087** — Input path (hat classification · inbox · guard window)
- [x] **CB-088** — Migration completion + checkers
- [x] **CB-089** — /cb-think (DeliberationWorkflow — divergent, file-backed)
- [x] **CB-090** — commands/ → skills/ entry-point migration (14 commands)
- [x] **CB-091** — Reconstruction checkers as code
- [x] **CB-092** — rules/: the constraint layer
- [x] **CB-093** — Skills for domains that have none
- [x] **CB-094** — Dynamic context budget
- [x] **CB-097** — Task-scoped skill loading
- [x] **CB-098** — Discovery cascade across the skill pool
- [x] **CB-099** — Staleness bounds on the run-active flag
- [x] **CB-100** — Rules layer: close the half-built axes
- [x] **CB-101** — /cb-do: direct execution without a spec
- [x] **CB-102** — Context monitor: the budget stops resting on a guess
- [x] **CB-103** — DelegationGuard named the wrong writer
- [x] **CB-104** — The front page stops lying about the repo
- [x] **CB-105** — History archived outside the runtime directory
- [x] **CB-106** — DelegationGuard blocked the conductor from its own plan
- [x] **CB-107** — Runtime state committed; scratch files left at the root
- [x] **CB-108** — Leakage check as a verify suite
- [x] **CB-108** — Constraint coverage, and what measuring it found
- [x] **CB-109** — Rules ignored the stack profile the project already computes
- [x] **CB-110** — Refactor scaffolding and the examples stub removed
- [x] **CB-111** — Prior art described by class, never named
