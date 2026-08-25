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

## Open — the outside test journal, second pass

An external operator drove the plugin through a build-shaped run in a
scratch repository and kept a measurement journal: 29 findings, each
with the command that produced it, and a 30th that appeared while the
first batch was being fixed. Thirteen closed under CB-134 and nine more
under CB-135..CB-140 and CB-143, CB-145, CB-146. These are what is left:
one waiting on a live check, two waiting on a decision this release
should not fake.

Every one was reproduced against this branch before being written here.
A finding that stopped reproducing is recorded in CB-140 with the reason
rather than silently dropped.

The journal's own severity scale is preserved in the finding ids so a
reader can trace a task back to the measurement that found it.

### CB-141 — The domain-skill layer is inert (F-09) — FIX COMMITTED, LIVE CHECK PENDING

**Status.** `plugin.json` now declares the six group directories as
scan roots, so the files do not move; `check-agent-skills` A-8 keeps the
manifest and the tree in step, verified against a constructed failure.
The deterministic layer confirms the manifest and the tree agree. It
does not confirm the host loads them — that needs one command in a live
session: update the plugin, `/reload-plugins`, then `Skill(spring-boot)`.
Until that returns a skill body instead of `Unknown skill`, this stays
open. The fallback if it fails is unchanged: a flat tree, 77 files moved.



Seventy-seven of the ninety-four shipped `SKILL.md` files cannot be
loaded. `skills/<group>/<skill>/SKILL.md` sits two directories deep and
the host walks only the first level, so the six category trees —
`practices/`, `frameworks/`, `languages/`, `data/`, `delivery/`,
`infrastructure/` — are unreachable. Only the seventeen workflow entry
points are invocable.

Measured three times independently: `Skill(spring-boot)`,
`Skill(api-design)` and `Skill(cereblnk:owasp-threat-modeling)` each
return `Unknown skill`, while the files exist on disk. Two specialists
worked around it by reading `SKILL.md` with `cat`.

First sized as a release that moves every skill file. That turned out
to be the wrong shape: the published plugin reference documents a
`skills` field in `plugin.json` that declares additional scan roots, so
the six group directories become discoverable where they are. The
migration was avoided by reading the reference instead of inferring the
contract from the failure.

**Urgency changed after CB-134.** While the floors were identity-blind
they never asked for these skills. CB-134 fixed identity matching, so a
Task Block naming a domain skill now produces a floor demand that
cannot be satisfied. The nudge cap bounds it, so it is friction rather
than deadlock — but it is friction this release introduced.

**Acceptance.**
1. `Skill(spring-boot)` returns the skill body, not `Unknown skill`.
2. Every file matching `skills/**/SKILL.md` is invocable by its
   directory name; a checker enumerates the tree and asserts it.
3. `scripts/check-agent-skills` still passes: no dangling reference, no
   unreachable skill, preload within budget.

### CB-142 — The cascade has a parser and no executor (F-08)

`policies/skill-selection.yaml` declares `discovery` triggers on most
rules (`@Entity -> hibernate-jpa`, `spring-boot-starter -> spring-boot`).
`scripts/lib/cbmap.py` defines `discovery_pairs` to read them. Nothing
in the tree calls it — grep across 1.3.5 and 1.4.0 returns zero callers.

The cascade is therefore instruction-driven: it happens when a
specialist reads the map and decides to follow a trigger, and not
otherwise. `agent-selection-policy.md` §4c presents it as a step that
occurs.

**The open question is who runs it**, and that is a design decision
rather than a missing line: the conductor cannot see inside the
specialist's window, and the specialist does not re-read the map after
its evidence changes. Route through `/cb-think` or `/cb-frame` before
implementing.

**Acceptance.**
1. Either a mechanism resolves declared triggers and records the
   resolution, or `discovery` is documented as advisory and
   `agent-selection-policy.md` §4c stops asserting it happens.
2. Whichever is chosen, a checker fails when the tree and the claim
   disagree.

### CB-144 — A conductor counted idle while its specialists run (F-14)

RunGuard fired a continue-nudge on a turn that ended with two subagents
still working: *"execute the NEXT unconfirmed task"*. There was no
ledger to reconcile — the run had written no `plan.md` — and the
conductor was not idle, it was waiting, which is the normal state of a
multi-agent run.

The remedy the nudge offers is worse than the nudge: removing
`flags/run-active` while specialists are running disarms the floors
that are supposed to judge them.

**Acceptance.**
1. A turn that ends with live background subagents produces no
   continue-nudge, or produces one whose text distinguishes waiting
   from stalling.
2. The nudge never recommends an action that disarms enforcement while
   enforcement is still needed.

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
- [x] **CB-121** — Rewrite: the old behaviour is ruled, not transcribed
- [x] **CB-122** — The guard held the door it was guarding
- [x] **CB-123** — Delegation boundary reaches the shell
- [x] **CB-124** — A refusal that repeats the step just taken
- [x] **CB-125** — A verdict from a specialist that was never shipped
- [x] **CB-126** — Project-local skills: dropped, the host already binds them
- [x] **CB-127** — The role vocabulary is closed (ACP A3)
- [x] **CB-128** — A gate that had never once applied
- [x] **CB-129** — Backlog ids stop shipping in copied templates
- [x] **CB-130** — Rule globs narrowed to their own trigger tables
- [x] **CB-131** — The arm that failed, and the boundary that went with it
- [x] **CB-132** — A name nothing could spawn, and a refusal with no way out
- [x] **CB-133** — Unresolved infers a specialist, and says so
- [x] **CB-134** — Thirteen findings from an outside test journal
- [x] **CB-135** — The destructive hook read its own documentation as a threat
- [x] **CB-136** — No role is denied the tool its own workflow requires
- [x] **CB-137** — The domain floor beats the level the block was assigned
- [x] **CB-138** — The Boot skill answers the Boot question it was silent on
- [x] **CB-139** — The `bin/` on PATH is a decision, and the tree records it
- [x] **CB-140** — Five findings closed without a change, and why
- [x] **CB-143** — The floor routed the contract and forgot the implementer
- [x] **CB-145** — The checkpoint is this project's threshold, not the host's
- [x] **CB-146** — A suite that reads its own shell is not a suite
