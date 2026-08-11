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

## Open — 1.4.0: the host boundary

**Release branch.** This release lands on `feature/1.4.0`. Tasks are
implemented on `cb/CB-XXX-slug` branches cut from and merged into
`feature/1.4.0`; the release branch merges to `main` once, with a single
version bump. This deviates from the per-task-to-`main` workflow above
and applies to this release only.

**What 1.4.0 claims.** The platform gains a host boundary. The only
bound host is still Claude Code. Bindings for adjacent hosts are out of
scope: they depend on CB-122 output that does not exist yet, and a task
may not depend on an F-class mechanism.

**Mandatory order.** CB-127 → CB-128 → CB-124. Freezing the current
binding is what makes "nothing changed" provable; doing it after the
refactor proves nothing. CB-122, CB-123, CB-126 and CB-129 are
independent and may run in parallel.

### CB-122 — Host capability is measured by running it, not read off a page

Secondary sources disagree with each other and with themselves across
months: one adjacent host was reported to have no blocking hooks in one
quarter and a full pre-tool veto in the next. Nothing downstream may
rest on that.

- **Deliverable.** `scripts/host-probe`, plus one
  `context/host-profile.<host>.yaml` per probed host.
- **Acceptance.** For each probed host the profile records, from an
  actual run: the events that fired, the field names present on the
  event payload, at least one case where a refusal actually stopped the
  action, and at least one case establishing whether an erroring hook
  fails open or closed. A field asserted without a run is recorded as
  absent, not assumed.
- **Depends on.** Nothing.

### CB-123 — A script path named inside a prompt is never checked to exist

`scripts/` is referenced 60 times inside skill and agent files and 6
times in README and docs. `ground-check` validates evidence citations
(`path#Lm-n`), not these. A stale path here fails silently at runtime:
an agent is told to run something that is not there.

- **Deliverable.** `scripts/check-script-paths`, wired into
  `scripts/verify`.
- **Acceptance.** Every script path named in `skills/`, `agents/`,
  `rules/`, `README.md` and `docs/` resolves to a file that exists.
  Mutation: break one path, the checker goes red.
- **Depends on.** Nothing.

### CB-128 — The refusal is decided in eighteen places and expressed in one

Every blocking hook ends the same way: message to stderr, `exit 2`.
That pairing is Claude Code's refusal form, and it is currently spelled
out inside each script. Any second host would require either a second
copy of all eighteen or a translation layer. It gets the translation
layer.

- **Deliverable.** `hooks/lib/hostio.sh`, providing `cb_event_read`
  (normalises the event payload into host-neutral variables) and
  `cb_block` (emits the host's refusal form). The 18 scripts change at
  their exit sites only.
- **Acceptance.** `test-hook-contract` from CB-127 passes unchanged. No
  hook script contains a literal `exit 2` outside `hostio.sh`. Hook
  logic, conditions and message text are untouched — the diff is
  confined to exit sites and one added source line.
- **Depends on.** CB-127.

### CB-125 — The support matrix is checked against the probe, not written by hand

A hand-maintained capability table drifts from the tree, and a silent
drop from M to D is the failure this project exists to refuse. A host
that cannot block must say so, not quietly stop blocking.

- **Deliverable.** `scripts/check-host-matrix`, wired into
  `scripts/verify`, plus the matrix section in `README.md`.
- **Acceptance.** Every cell in the published matrix is derived from a
  `context/host-profile.<host>.yaml` field. Mutation: change one cell by
  hand, the checker goes red. A capability absent on a host is printed
  as absent, never omitted.
- **Depends on.** CB-122.

### CB-126 — Manifests for adjacent hosts, without moving a file

Adjacent hosts read repo-local plugin registries, and the layout they
expect is a per-plugin manifest under `plugins/<name>/` — which is the
layout this repo already has. Moving assets to the root would move away
from it, and would collide: the root already holds a `scripts/`
directory distinct from the plugin's.

- **Deliverable.** `.agents/plugins/marketplace.json`,
  `plugins/cereblnk/.codex-plugin/plugin.json`, and `AGENTS.md` at the
  repository root.
- **Acceptance.** Each manifest passes its host's validator. The Claude
  manifests and `marketplace.json` are unchanged, verified by diff. This
  task adds packaging only and claims no capability; nothing in the
  matrix changes because of it.
- **Depends on.** Nothing. (Matrix entries for these hosts wait on
  CB-122.)

### CB-130 — A release branch reaches main empty

"1.4.0 does not merge to main until the backlog is done" is a rule, and a
rule without a checker is a wish. Someone merges on a Friday, two items
are still open, and nothing objects.

- **Deliverable.** `scripts/check-release-ready`, and a CI job that runs
  it on pull requests whose base is `main`.
- **Acceptance.** With any task heading under `## Open`, the checker
  exits non-zero and names every open item. With the section empty, it
  exits 0. It does not run on merges into the release branch, where open
  items are the normal state — so it stays out of `scripts/verify`.
- **Depends on.** Nothing.

### CB-129 — One skill exceeds the smallest host's ceiling

An adjacent host caps a skill file at 8 KB. Measured across the tree:
1 of 94 `SKILL.md` files is over (`skills/orchestrate/SKILL.md`, 9983 B);
0 of 29 agent files are.

- **Deliverable.** `skills/orchestrate/SKILL.md` brought under the cap,
  and a size assertion in the verify suite.
- **Acceptance.** Every `SKILL.md` is under 8192 bytes. The checker
  names the ceiling and its source. `authoring-lint judgment` still
  passes on the reduced file — shrinking it must not turn judgment
  language into a recipe.
- **Depends on.** Nothing.

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
- [x] **CB-112** — Document index: reach the right page without reading the book
- [x] **CB-113** — Execution floor: a surface cannot close unverified
- [x] **CB-114** — Reachability: new code that nothing calls is not done
- [x] **CB-115** — Runtime stage: environment lifecycle and health-gated attribution
- [x] **CB-116** — Cross-surface contract as a referenceable artifact
- [x] **CB-117** — The front page says what this is before how to install it
- [x] **CB-118** — Every README claim re-derived from the tree; five were wrong
- [x] **CB-119** — Architecture assets generated from the tree, not drawn then checked
- [x] **CB-120** — Correct and unread: the generated panels reverted for a systems note
- [x] **CB-127** — The Claude binding is frozen before anything moves
- [x] **CB-121** — Rewrite: the old behaviour is ruled, not transcribed
