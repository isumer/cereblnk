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
| Entry points: skill form over `commands/` | **M** | VERIFIED 2026-07-25 against platform docs: `commands/` is now marked legacy ("use skills/ instead"); plugin skills are invocable as slash commands and namespaced `plugin-name:skill-name`. Cereblnk entry points therefore ship as skills carrying the `cb-` name prefix (`cb-dispatch`, `cb-think`); the layering rule of 08 §1 (entry → workflow → agents) is unchanged — only the file form is. Migration of the 13 existing `commands/*.md`: CB-090 |
| Skill/command naming classes | **M** | `check-skill-frontmatter` (CB-088) enforces: bare name = domain skill (name must equal its directory), `cb-` prefix = entry point. A SKILL.md without frontmatter does not load at all — this was true of 54 skills before the checker existed |
| Agent skill preload (`skills:` frontmatter) | **M** | VERIFIED 2026-07-31 against platform docs: the field preloads FULL skill content into the subagent at startup, and a listed skill that is missing or disabled is skipped with only a debug-log warning — a silent failure. Cost is charged on every spawn, so CB-097 restricts preload to invariant craft (cap enforced by `check-agent-skills`) and resolves stack-shaped skills per task |
| Task-scoped skill loading | **M**/D | Subagents may invoke unlisted skills through the Skill tool (M). WHICH skills a task needs is computed by `scripts/select-agents` from `policies/skill-selection.yaml` (M, deterministic); the agent actually loading them is instruction-driven (D) — enforced below |
| Skill floor enforcement | **M** | `SkillLedgerHook` (PreToolUse: Skill) records every load into the run ledger; `SkillFloorHook` (SubagentStop) exits 2 when a specialist finishes with an unmet floor, which blocks the stop and returns the agent to work. Nudge-capped and fail-open, in `run-guard.sh`'s shape. VerifierAgent compares `skills_loaded` at gate review |
| Surface execution floor | **M** | `ExecLedgerHook` (PostToolUse) records which surfaces a specialist edited, resolved through `policies/surface-map.yaml`, and which surface check commands it ran; `ExecFloorHook` (SubagentStop) exits 2 when an edited surface was never executed. Nudge-capped and fail-open, in `skill-floor.sh`'s shape. A surface with no configured `config/check-command.<surface>` is recorded as skipped and allowed through — the gap stays visible in the ledger instead of turning a project red for a command it was never given. Running a program is the one check no static gate performs (CB-113) |
| Reachability floor | **M** | `ExecLedgerHook` records edited paths to `edited-files.log`; `scripts/reachability` reports a symbol declared there whose identifier appears nowhere in the project outside its own declaration line, exempting decorated and annotated declarations where a framework may be the caller; `ReachFloorHook` (SubagentStop) exits 2 on a report. Precision over recall by design — a report is near-certain, a clean result is weak evidence, and transitive orphans are out of reach. Escape hatch: `config/reachability-ignore`. Unwired code fails by silence, so execution does not catch it (CB-114) |
| Environment lifecycle | **M** | `plugins/cereblnk/scripts/env` reads `config/runtime.md` and runs the project's own up/down commands; Cereblnk never writes a compose file. Preflight refuses to start when something already answers the health URL, and teardown runs the command recorded in `flags/env-active` rather than whatever config currently says — an environment this project did not start is never touched (CB-115) |
| Health-gated attribution | **M** | Exit 4 from `scripts/env` is an ENVIRONMENT verdict and /cb-qa stops the stage there. A check run against a stack that never became healthy is evidence of nothing; reporting it as an application failure is the error the exit code exists to prevent (CB-115) |
| Environment teardown | **M** | `EnvTeardownHook` (SessionEnd) reclaims a leaked environment. The stage takes its own environment down and does not lean on the hook; the hook covers the session that died (CB-115) |
| Browser/live-device execution | F | Still absent. /cb-qa may write a browser test and name its run command; a passes claim requires real CI output. The runtime stage above brings a system up and polls health — that is a different mechanism and the two are no longer stated as one |
| Cross-surface contract | **M**/D | The contract is an artifact under `memory/contracts/` written by APIDesignAgent (D); `scripts/contract-check` reconciles it against each surface's own files and `ContractFloorHook` (SubagentStop) exits 2 on a mismatch (M). Both directions are checked: the new channel present AND the replaced path gone. Presence without absence is a half-done migration that reads as finished (CB-116) |
| Cross-surface parallelism | **M** | Each party is judged only on its own files, so the UI is asked whether the UI carries every channel, never whether the backend is done. A closing gate, not a starting gate: the failure was never that a leg started early, it was that a leg finished unmatched (CB-116) |
| Stack detection | **M** | `scripts/detect-stack` reads manifest files and their dependency text, caches `context/stack-profile.yaml` by size+mtime signature. Git-based and file-based only; no index, no embeddings — the semantic graph stays F-class |
| Intent Engine | D | Instruction block in the top-level orchestrator: three-level reading before any planning |
| Planner / Task Graph | D | PlannerAgent subagent producing ACP task blocks as structured text |
| Budget Manager | D | Budget figures written into each task block; agents self-report; orchestrator checks reports. NOT platform-enforced — treat overruns as protocol violations |
| Context OS chunking | **M**/D | Subagents' native isolated contexts (M) + instructions on what to read (D); file-scoped reading via explicit path lists |
| Dependency / Semantic Graph | **F** | Requires indexing scripts (Phase 2+); Phase 1 approximates with targeted file reads guided by the orchestrator |
| Evidence Store / Evidence Graph | D | ACP fact blocks accumulated in orchestrator context; persisted to `.claude/cereblnk/memory/` as files when promoted |
| Evidence-preserving compression | D | `agents/context/compression-agent.md` (conservation gates: labels, refs, unknowns/risks counted before and after); format rules in 03_CONTEXT_OS.md §5. **Checker:** ConsistencyAgent on conservation mismatch |
| ACP enforcement | D | Templates in `.claude/cereblnk/templates/` + orchestrator rejecting malformed blocks |
| Verifier / Challenger | **M**/D | Dedicated subagents (M for isolation) running under gate instructions (D) |
| Consistency gate | D | ConsistencyAgent comparing fact sets; mechanical rules in 04_QUALITY_GATES.md §3.3 |
| Quality gate blocking | D | Orchestrator instruction: no user-facing synthesis without required gate verdicts |
| Fast path | D | Orchestrator instruction keyed to Risk Model |
| Hooks (lint, test, guard) | **M** | Claude Code hooks — can genuinely block actions; use them for the few things that must be hard-enforced (e.g., "never write outside repo", "run tests after edit") |
| Durable plan (file+lint+status) | **M** | `.claude/cereblnk/memory/plans/*.md` as execution state; `plugins/cereblnk/scripts/plan-lint` refuses malformed plans, `plan-status` recovers state after a dead session. Enables fresh-executor-per-task and weak-model resume — the advisory-loop core, ACP-reconciled |
| Security-finding enforcer (script) | **M** | `plugins/cereblnk/scripts/security-findings-lint`: validates the security-findings artifact against the finding contract; exit 1 blocks synthesis. Real hard-enforcement at the audit boundary |
| Repository map (script-based) | **M** | `plugins/cereblnk/scripts/repo-map`: git-history hotspots, per-path ownership, static import listing → single YAML attached as a CTX bundle (context-policy.md). The git-buildable subset of the F-class Dependency Graph; semantic indexing remains F |
| Delegation enforcement | **M** | PreToolUse `delegation-guard.sh`: mid-run conductor Edit/Write blocked (exit 2), subagent edits pass via `agent_id`/`agent_type` hook-input fields; correct under both current (fields populated) and legacy (subagent calls bypass hooks) platform behavior |
| Stalled-run continuation | **M** | Stop hook (`run-guard.sh`): while `flags/run-active` is armed, the first stop is blocked with a continue-reason listing ledger progress, then the guard disarms (rename to `.nudged`) — one nudge, never a loop; `stop_hook_active` always bypasses. Root resolution via cbenv: CLAUDE_PROJECT_DIR → walk-up to nearest `.git`/`.claude` (never selecting $HOME) → create `.claude/` at $PWD for brand-new projects — under temp locations the absolute last resort is `$HOME/.claude/` (function over data loss; projects always win when present) |
| Session history preservation | **M** | PreCompact hook (fires on manual `/compact` and auto-compact; stdin carries `transcript_path`/`trigger`) → `hooks/scripts/history-archive.sh` copies the transcript to `<project>/.claude/history/`. Known upstream caveat: `transcript_path` may arrive empty (claude-code#13668) — hook fails open and says so |
| Persistent memory | **M**/D | Files under `.claude/cereblnk/memory/` (M: real files) + MemoryBuilderAgent promotion rules (D) |
| XML/XSD tooling (parse, validate, generate) | **M** | `plugins/cereblnk/scripts/xmltools/` — original stdlib-only parser core, fail-closed subset XSD validator, Estimated-labeled schema generator; consumed via `skills/practices/xml-processing` |
| Telemetry | D/F | Run summaries appended to `.claude/cereblnk/telemetry/` as files; analysis tooling is Future |

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
