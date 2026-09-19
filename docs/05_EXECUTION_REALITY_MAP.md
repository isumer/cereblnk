# Execution Reality Map

> Status: Living Document v1.0
> This document maps every Cereblnk concept to the concrete Claude Code
> mechanism that implements it. It exists to prevent the architecture from
> floating above reality.
>
> **Rule:** If a concept has no row in this table, it cannot be referenced
> by any agent, skill, or workflow document until it gets one.
>
> Note: verify current Claude Code capabilities against official docs
> before implementation — plugin mechanisms evolve.

---

## 1. The Honest Distinction

Cereblnk concepts fall into three implementation classes:

| Class | Meaning |
|---|---|
| **M — Mechanism** | Backed by a real Claude Code feature (subagents, skills, hooks, commands, settings). Enforced by the platform. |
| **D — Discipline** | Implemented as prompt/protocol convention. Enforced by instruction quality and gate agents, not by the platform. |
| **F — Future** | Requires tooling that does not exist yet (scripts, external index, CI). Must not be assumed by Phase 1 designs. |

Being honest about D vs M is what keeps this project credible.
A "Budget Manager" that is actually a paragraph of instructions must be
designed as a paragraph of instructions — and made as enforceable as
a paragraph can be.

---

## 2. Concept → Mechanism Map

| Cereblnk Concept | Class | Claude Code Realization |
|---|---|---|
| Specialist Agents | **M** | Claude Code subagents (agent definition files); each spawned with its own context window — this natively implements ephemerality and context isolation |
| Agent expertise boundaries (Law 1) | D | Role constraints written into each agent definition + Consistency gate checks |
| Skills | **M** | Claude Code skill files (SKILL.md format) under the plugin's skills directory |
| Workflows | **M**/D | Slash commands or skill entry points that orchestrate subagent invocations; sequencing logic is instruction-driven |
| Entry points: skill form over `commands/` | **M** | VERIFIED 2026-07-25 against platform docs: `commands/` is now marked legacy ("use skills/ instead"); plugin skills are invocable as slash commands and namespaced `plugin-name:skill-name`. Cereblnk ships 19 entry-point skills carrying the `cb-` prefix, including the ledger utility `/cb-catchup` and interrupted-run recovery `/cb-resume`; `scripts/check-readme` checks the tree against the documented command set |
| Skill/command naming classes | **M** | `check-skill-frontmatter` (CB-088) enforces: bare name = domain skill (name must equal its directory), `cb-` prefix = entry point. A SKILL.md without frontmatter does not load at all — this was true of 54 skills before the checker existed |
| Agent skill preload (`skills:` frontmatter) | **M** | VERIFIED 2026-07-31 against platform docs: the field preloads FULL skill content into the subagent at startup, and a listed skill that is missing or disabled is skipped with only a debug-log warning — a silent failure. Cost is charged on every spawn, so CB-097 restricts preload to invariant craft (cap enforced by `check-agent-skills`) and resolves stack-shaped skills per task |
| Task-scoped skill loading | **M**/D | Subagents may invoke unlisted skills through the Skill tool (M). WHICH skills a task needs is computed by `scripts/select-agents` from `policies/skill-selection.yaml` (M, deterministic); the agent actually loading them is instruction-driven (D) — enforced below |
| Mandated-agent roster persistence | **M** | `plugins/cereblnk/scripts/select-agents --emit-floor` writes `agents-required.yaml` beside `skills-required.yaml` in the id-pinned run, one qualified specialist and decision domain per roster entry; the same script's `--roster` output is the source of those domains (CB-176) |
| Mandated-agent planning gate | **M** | `plugins/cereblnk/scripts/plan-lint` rule R8 refuses Task 1 when a specialist in `agents-required.yaml` is neither assigned as lead/reviewer nor covered by an exact plan-header `merged: <agent> into <agent> because <reason>` waiver. `hooks/scripts/run-guard.sh` names roster entries without Response Blocks as the plan-less `/cb-do` Stop backstop (CB-177) |
| Skill floor enforcement | **M** | `SkillLedgerHook` (PreToolUse: Skill) records every load into the run ledger; `SkillFloorHook` (SubagentStop) exits 2 when a specialist finishes with an unmet floor, which blocks the stop and returns the agent to work. Nudge-capped and fail-open, in `run-guard.sh`'s shape. VerifierAgent compares `skills_loaded` at gate review |
| Surface execution floor | **M** | `ExecLedgerHook` (PostToolUse) records which surfaces a specialist edited, resolved through `policies/surface-map.yaml`, and which surface check commands it ran; `ExecFloorHook` (SubagentStop) exits 2 when an edited surface was never executed. Nudge-capped and fail-open, in `skill-floor.sh`'s shape. A surface with no configured `config/check-command.<surface>` is recorded as skipped and allowed through — the gap stays visible in the ledger instead of turning a project red for a command it was never given. Running a program is the one check no static gate performs (CB-113) |
| Reachability floor | **M** | `ExecLedgerHook` records edited paths to `edited-files.log`; `scripts/reachability` reports a symbol declared there whose identifier appears nowhere in the project outside its own declaration line, exempting decorated and annotated declarations where a framework may be the caller; `ReachFloorHook` (SubagentStop) exits 2 on a report. Precision over recall by design — a report is near-certain, a clean result is weak evidence, and transitive orphans are out of reach. Escape hatch: `config/reachability-ignore`. Unwired code fails by silence, so execution does not catch it (CB-114) |
| Response grounding floor | **M** | `hooks/scripts/ground-floor.sh` selects the stopping specialist's response-like blocks and invokes `plugins/cereblnk/scripts/ground-check`; an unresolved file, indexed-document line or quote exits 2 at SubagentStop. The hook is fail-open, recursive-stop safe and nudge-capped (CB-167) |
| Environment lifecycle | **M** | `plugins/cereblnk/scripts/env` reads `config/runtime.md` and runs the project's own up/down commands; Cereblnk never writes a compose file. Preflight refuses to start when something already answers the health URL, and teardown runs the command recorded in `flags/env-active` rather than whatever config currently says — an environment this project did not start is never touched (CB-115) |
| Health-gated attribution | **M** | Exit 4 from `scripts/env` is an ENVIRONMENT verdict and /cb-qa stops the stage there. A check run against a stack that never became healthy is evidence of nothing; reporting it as an application failure is the error the exit code exists to prevent (CB-115) |
| Environment teardown | **M** | `EnvTeardownHook` (SessionEnd) reclaims a leaked environment. The stage takes its own environment down and does not lean on the hook; the hook covers the session that died (CB-115) |
| Browser/live-device execution | F | Still absent. /cb-qa may write a browser test and name its run command; a passes claim requires real CI output. The runtime stage above brings a system up and polls health — that is a different mechanism and the two are no longer stated as one |
| Cross-surface contract | **M**/D | The contract is an artifact under `memory/contracts/` written by APIDesignAgent (D); `plugins/cereblnk/scripts/contract-check` searches each surface's files for string occurrence: a non-deferred new channel must appear somewhere and a non-deferred replaced path must be absent (M; CB-116/165). A comment or test can satisfy presence, so the check proves the surface was not silent about the contract, not that implementations are compatible. A `## Channels` row with status `deferred` remains explicit non-current work |
| Contract new-damage baseline | **M** | `plugins/cereblnk/scripts/run-flag arm` snapshots sorted `contract-check` findings to `context/<run_id>/contract-baseline.txt`; `hooks/scripts/contract-floor.sh` blocks only current findings absent from that baseline. Pre-existing findings are risk notes, a missing baseline fails open, and lifecycle verbs clear the transient file (CB-166) |
| Cross-surface parallelism | **M** | Each party is judged only on its own files, so the UI is asked whether the UI carries every channel, never whether the backend is done. A closing gate, not a starting gate: the failure was never that a leg started early, it was that a leg finished unmatched (CB-116) |
| Stack detection | **M** | `scripts/detect-stack` reads manifest files and their dependency text, caches `context/stack-profile.yaml` by size+mtime signature. Git-based and file-based only; no index, no embeddings — the semantic graph stays F-class |
| Intent Engine | D | Instruction block in the top-level orchestrator: three-level reading before any planning |
| Planner / Task Graph | D | PlannerAgent subagent producing ACP task blocks as structured text |
| Budget Manager | D | Budget figures written into each task block; agents self-report; orchestrator checks reports. NOT platform-enforced — treat overruns as protocol violations |
| Context OS chunking | **M**/D | Subagents' native isolated contexts (M) + instructions on what to read (D); file-scoped reading via explicit path lists |
| Dependency / Semantic Graph | **F** | Requires indexing scripts (Phase 2+); Phase 1 approximates with targeted file reads guided by the orchestrator |
| Evidence Store / Evidence Graph | D | ACP fact blocks accumulated in orchestrator context; persisted to `.claude/cereblnk/memory/` as files when promoted |
| Evidence-preserving compression | D | `agents/context/compression-agent.md` (conservation gates: labels, refs, unknowns/risks counted before and after); format rules in 03_CONTEXT_OS.md §5. **Checker:** ConsistencyAgent on conservation mismatch |
| ACP enforcement | D | Templates in `plugins/cereblnk/protocols/` + orchestrator rejecting malformed blocks |
| Existing-source abstention for decision roles | D | Compression, ContextArchivist, EvidenceCollector, MemoryBuilder, Merge, Challenger, Consistency, Planner, Synthesizer, Verifier, Architect and QA deny `Edit` and `NotebookEdit` but retain `Write`, which can replace a whole file. `ToolFloorHook` blocks in-place shell edits only and leaves Write-shaped redirection available. Their instruction not to modify existing source is discipline; PlannerAgent uses `Write` to replace `plan.md` each iteration |
| Verifier / Challenger | **M**/D | Dedicated subagents (M for isolation) running under gate instructions (D) |
| Consistency gate | D | ConsistencyAgent comparing fact sets; mechanical rules in 04_QUALITY_GATES.md §3.3 |
| Quality gate blocking | D | Orchestrator instruction: no user-facing synthesis without required gate verdicts |
| Fast path | D | Orchestrator instruction keyed to Risk Model |
| Hooks (lint, test, guard) | **M** | Claude Code hooks — can genuinely block actions; use them for the few things that must be hard-enforced (e.g., "never write outside repo", "run tests after edit") |
| Durable plan (file+lint+status) | **M** | `.claude/cereblnk/context/<run_id>/plan.md` is live execution state; `plugins/cereblnk/scripts/plan-lint` refuses malformed plans and R8-unfulfilled mandated rosters, while `plan-status` recovers the first unchecked task after a dead session. Archived plans retain the same relative structure under `archive/<run_id>/` |
| Security-finding checker and invocation | **M**/D | `plugins/cereblnk/scripts/security-findings-lint` validates the security-findings artifact and returns exit 1 for named violations (M). No hook or `verify` suite invokes it automatically; the security-audit workflow requires its invocation and gate agents check that it ran (D) |
| Repository map (script-based) | **M** | `plugins/cereblnk/scripts/repo-map`: git-history hotspots, per-path ownership, static import listing → single YAML attached as a CTX bundle (context-policy.md). The git-buildable subset of the F-class Dependency Graph; semantic indexing remains F |
| Presence-only run state | **M** | `plugins/cereblnk/scripts/lib/cbenv.sh:cb_run_state` returns `ARMED` when `flags/run-active` exists, `COMPLETED` when only `flags/run-completed` exists, and `IDLE` otherwise. `hooks/scripts/delegation-guard.sh` uses that resolver for both edit and Bash paths. No TTL or ledger-mtime inference changes the answer (CB-168) |
| Delegation enforcement | **M** | PreToolUse `hooks/scripts/delegation-guard.sh`: in `ARMED`, conductor repository-source writes exit 2; in `COMPLETED`, source follow-ups re-enter dispatch. Subagent edits and conductor-owned `.claude/`, run-note and outside-repository paths pass. The Bash and edit branches share `cb_run_state` (CB-168) |
| Per-path constraint delivery | **D** | `scripts/select-rules --constraints --task "<text>" <path>` computes which constraints apply and emits them: glob, plus the stack token the owning skill declares, plus the task signal for the ten rules under `architecture/`, `governance/` and `security/` that carry no glob. Measured 11,111 -> 3,638 tokens on a real Spring controller, 65-67% across every budgeted file type, ratcheted by `check-rule-budget` and pinned by a suite that no bullet of the 1,242 in the tree is lost. Selection and delivery are mechanism; **honouring** a delivered constraint is not — 35 SKILL.md files instruct the agent to run it and nothing verifies the output was read, which is why this row is D. What IS enforced is that the instruction matches the implementation: verify fails when a skill asks for a flag select-rules does not have (CB-185) |
| Constraint floor in context | **M** | SessionStart `hooks/scripts/rule-floor.sh` injects the ten `rules/common/` files as `additionalContext`, so the technology-neutral constraints apply with the plugin installed and no command invoked. It emits the projection, not the files: 1,821 tokens against 5,307 read whole, which is what makes a per-session injection defensible. `CB_RULE_FLOOR=0` opts out. What it does NOT do is enforce them — it is a **D**-class delivery of constraints, and nothing checks that the model honoured one. It records the session it injected for, so `select-rules` stops appending common/ on top of it — without that marker the layer shipped twice and a one-file task saved 49% where the parts measured 67%. Presence, not a TTL: a marker naming another session does not match, and a floor that failed open leaves none, so the fallback is a duplicate rather than an absent constraint. Per-path rules still need `select-rules --constraints --task "<text>" <path>` (CB-185) |
| Stale-run visibility | **M** | SessionStart `hooks/scripts/stale-run.sh` reports an old valid `run-active` pin only when its plan has no checked task (or no plan exists), naming `/cb-resume` and `run-flag abandon`. It never mutates state or blocks, and `CB_STALE_RUN_HOURS` changes only the notice threshold, not run state (CB-171/178) |
| Stalled-run continuation | **M** | Stop `hooks/scripts/run-guard.sh` reports Response Block progress against plan checkboxes and unfulfilled mandated agents. Ledger growth does not consume the bounded nudge budget; stagnant Stops do, and the run is released only after the cap. `stop_hook_active` always bypasses and all error paths fail open (CB-170/177) |
| Risk-scaled gate presence at finish | **M**/D | Stop `hooks/scripts/gate-floor.sh` reads the plan's risk and blocks the conductor's stop while a required gate role has emitted no `kind: verification` block — medium needs Verifier and Consistency, high adds Challenger (04_QUALITY_GATES §2). It checks PRESENCE, never verdict value: in a real run four of six gate blocks were `refuted` and the run was right to continue, so a verdict test would strand correct work. So this proves the required gates ran, not that they passed (D). Nudge-capped like every floor and `stop_hook_active` bypasses. A plan-less run (CB-177) has no plan to carry risk, so `select-agents --emit-floor` persists its computed `gate_level` into `agents-required.yaml` and the floor reads it there; a plan's own risk wins where both exist. With neither, it fails open |
| Post-synthesis improve/fix acceptance | **D — unenforced** | Ten synthesis-ending entry skills instruct the conductor to disarm and ask “Anything to improve or fix?” before completion. No script can prove the operator was asked or answered no; `plugins/cereblnk/scripts/run-flag complete` will execute when called. The gate is therefore explicit discipline, not a mechanical floor (CB-178) |
| Run resume | **M**/D | `/cb-resume` is instruction-driven recovery (D) that validates the existing pin and plan, calls `plugins/cereblnk/scripts/plan-status`, and re-arms the same id through `plugins/cereblnk/scripts/run-flag arm` (M). It never allocates or guesses a run id (CB-178) |
| Run completion and archive | **M**/D | `plugins/cereblnk/scripts/run-flag complete` and `abandon` mechanically clear transient state, write `archive-pointer.txt`, refuse collisions, and move the selected live `context/<run_id>/` directory to `.claude/cereblnk/archive/<run_id>/`; complete retains the `run-completed` handoff, abandon removes it and never reverts memory (M). `complete` does not inspect the plan, ACP blocks or gate verdicts; calling it only after those checks is workflow discipline (D). `plugins/cereblnk/scripts/run-status` resolves archived plans and inboxes (CB-178) |
| Completion telemetry ledger | **M** | `plugins/cereblnk/scripts/run-flag complete` appends `telemetry/runs.log` with decision, gate, `tokens_total` when known, and `tasks_shipped`; missing context or budget fields degrade to a partial line rather than aborting completion (CB-169) |
| Shipping review ledger | **M**/D | For a shipping run, `plugins/cereblnk/scripts/run-flag complete` appends one `telemetry/review-ledger.log` record with `reviewed=no`, touched files and summary (M). `plugins/cereblnk/scripts/review-ledger` lists and marks exact records; `/cb-catchup` controls presentation and requires explicit acknowledgement (D; CB-172/173) |
| Session history preservation | **M** | PreCompact hook (fires on manual `/compact` and auto-compact; stdin carries `transcript_path`/`trigger`) → `hooks/scripts/history-archive.sh` copies the transcript to `<project>/.claude/cereblnk/history/`. Known upstream caveat: `transcript_path` may arrive empty (claude-code#13668) — hook fails open and says so |
| Persistent memory | **M**/D | Files under `.claude/cereblnk/memory/` (M: real files) + MemoryBuilderAgent promotion rules (D) |
| XML/XSD tooling (parse, validate, generate) | **M** | `plugins/cereblnk/scripts/xmltools/` — original stdlib-only parser core, fail-closed subset XSD validator, Estimated-labeled schema generator; consumed via `skills/practices/xml-processing` |
| Telemetry | **M**/D/F | Completion and shipping-review append paths are mechanical in `plugins/cereblnk/scripts/run-flag` (M); the richer per-run summary template remains an orchestrator write rule (D); cross-run analysis beyond `review-ledger list/mark` remains Future |

---

## 3. Design Consequences

1. **Subagent context isolation is our strongest real mechanism.**
   Law 4 (context not shared) is largely FREE on Claude Code — design
   around it aggressively.

2. **Everything Discipline-class needs a checker.**
   A rule without a checking agent is a wish. Every D-class rule in this
   map must name which gate or agent detects its violation.

3. **Hooks are the scarce hard-enforcement resource.**
   Spend them only on irreversible-damage prevention, not on style.

4. **Phase 1 must not depend on any F-class row.**
   The Dependency/Semantic Graph is the biggest temptation — resist it.
   Phase 1 retrieval = orchestrator-guided explicit file lists.

5. **This document is updated whenever Claude Code capabilities change.**
   It is the only Living Document among the frozen core five.
