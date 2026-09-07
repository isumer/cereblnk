# Cereblnk Hooks — Hard Enforcement Layer

Hooks are the scarce real-enforcement resource (the execution-mechanism map consequence
#3): spent only on irreversible-damage prevention, never on style.

| Hook | Event | Enforces | Activation |
|---|---|---|---|
| DelegationGuardHook | PreToolUse:Bash\|Write\|Edit\|MultiEdit\|NotebookEdit | blocks conductor repository-source writes while `ARMED`, and routes source follow-ups while `COMPLETED`; subagent and conductor-owned control writes pass | run state is presence-only |
| ToolFloorHook | PreToolUse:Bash | blocks an in-place shell edit when the running agent's own `disallowedTools` forbids edit tools | **always on** (subagents only) |
| DestructiveCommandHook | PreToolUse:Bash | blocks recursive delete, force-push, hard reset, SQL DROP/TRUNCATE, disk writes; matches the command, never text that merely mentions one (heredoc bodies and quoted spans are inert unless a shell, interpreter or DB client re-runs them); build-artifact cleanups and a lone delete of the `careful` flag itself allowlisted | opt-in: `/cb-careful` |
| EditBoundaryHook | PreToolUse:Write\|Edit | blocks writes outside a declared directory | opt-in: `/cb-boundary <path>`; auto-engaged by /cb-bug fix stage |
| SecretGuardHook | PreToolUse:Write\|Edit | blocks writes containing likely credentials (fail-closed on detection) | **always on** |
| ScratchGuardHook | PreToolUse:Write | blocks a new untracked file at the repository root during a run and names the run's scratch directory; releases after two nudges | **always on** (inside an active run only) |
| DocFloorHook | PreToolUse:Read | blocks an unbounded read of an indexed document and returns its section outline; fail-open and nudge-capped | **always on** |
| SkillLedgerHook | PreToolUse:Skill | records each specialist skill load in the pinned run ledger | **always on**, never blocks |
| PostEditTestHook | PostToolUse:Write\|Edit | runs the configured test subset after edits during gate-level-3 work | policy: `.claude/cereblnk/flags/gate3` + `.claude/cereblnk/config/test-command` |
| ExecLedgerHook | PostToolUse:Write\|Edit\|MultiEdit\|NotebookEdit\|Bash | records edited and executed surfaces for the pinned run | **always on**, never blocks |
| HistoryArchiveHook | PreCompact | copies the session transcript into project runtime history before compaction discards detail | **always on**, never blocks |
| RunGuardHook | Stop | reports ledger progress and missing mandated responders; only stagnant Stops consume its bounded nudge budget | **always on** while `ARMED` |
| StaleRunHook | SessionStart | reports an old pinned run whose plan has no closed task, naming resume/abandon recovery; never changes the flag | **always on**, never blocks; default 12h, override with `CB_STALE_RUN_HOURS` |
| EnvTeardownHook | SessionEnd | takes down only an environment this project recorded as starting | **always on**, never blocks |
| SkillFloorHook | SubagentStop | refuses a specialist missing the skill floor written for its role | **always on** (inside a run ledger only) |
| ExecFloorHook | SubagentStop | refuses a specialist that edited a configured surface without executing its check | **always on** (inside a run ledger only) |
| ReachFloorHook | SubagentStop | refuses a specialist that introduced a near-certain unreferenced symbol | **always on** (inside a run ledger only) |
| ContractFloorHook | SubagentStop | refuses only contract findings introduced after the run-arm baseline; pre-existing findings are notes and deferred Channels rows are skipped | **always on** (inside a run ledger only) |
| DigestCapHook | SubagentStop | retains final assistant text, persists an isolatable ACP block without clobbering an agent-authored file, and blocks a return exceeding the computed `digest_lines_max` | **always on** (inside a run ledger only) |
| GroundFloorHook | SubagentStop | runs `ground-check` on the stopping specialist's response-like blocks and refuses dangling file, document-line, or quote references; fail-open and nudge-capped | **always on** (inside a run ledger only) |
| ContextMonitorHook | UserPromptSubmit | measures real window occupancy from the session transcript; samples every turn to telemetry, injects a short warning past the checkpoint | **always on**, never blocks |
| RouteHintHook | UserPromptSubmit | runs `select-agents --text` on the prompt and injects one line naming the resolved specialists and gate | **always on**, never blocks; silent on explicit `/cb-`, armed, unresolved, or opted-out prompts |

Opt-in state lives in flag files under `.claude/cereblnk/flags/` in the user's
project, created/removed by the `/cb-careful` and `/cb-boundary`
commands — hooks read them at execution time.

**Honest note:** edit-boundary hooks block *tools*, not shell
side-effects — this is accident prevention, not a sandbox.

## Interpreter failure semantics

Hooks source `scripts/lib/cbenv.sh`. If no usable Python 3 is
found (Windows Store alias stubs are skipped, never executed),
hooks **fail open**: exit 0 with a stderr warning, so a missing
interpreter cannot block every Write/Edit. This is a documented
deviation from SecretGuard's fail-closed ideal — the redaction
check announces on stderr when it is being skipped. Install
Python 3 to re-arm all hooks.

## StaleRunHook (SessionStart)

Presence-only run state has no silent timeout. At session start, a
`flags/run-active` pin older than 12 hours is reported only when its
`plan.md` has no checked task (or no plan exists). The notice reads the
pin directly, never substitutes another run, never touches the flag, and
always exits 0. Set `CB_STALE_RUN_HOURS` to a non-negative whole number
to change the threshold. Its recovery routes are `/cb-resume` for the
same live plan and `run-flag abandon` for archival without completion.

## HistoryArchiveHook (PreCompact)

Before every compaction — manual `/compact` or automatic — the session
transcript is copied to `<project>/.claude/cereblnk/history/` as
`<utc>-<trigger>-<session>.jsonl`. Always on, always fails open: an
archiving problem never blocks compaction. Works without Python (sed
fallback). Retention keeps the newest 20 archives; override with a
number in `.claude/cereblnk/config/history-keep`. Upstream caveat: on
some setups the harness sends an empty `transcript_path`
(claude-code#13668); the hook logs that nothing was archivable and
lets compaction proceed.

## RunGuardHook (Stop)

A workflow's subagent result can land between turns; the session then
sits idle until the user types. While a run is `ARMED`, the guard shows
Response Block progress against plan checkboxes and names any mandated
agent without a Response Block. Ledger growth does not spend its nudge
budget; each stagnant Stop advances the counter, and after three
stagnant nudges the next Stop releases the run by renaming the flag to
`.nudged`. `stop_hook_active: true` always passes. Fail-open on every
error path. Note:
`~/.claude/projects/` transcripts are Claude Code's
own storage, not plugin output — HistoryArchiveHook copies from there
into the project; the originals staying put is expected.

## DelegationGuardHook (PreToolUse: Edit/Write)

The mechanical form of "the conductor never implements" uses the shared
`cb_run_state`: `run-active` is `ARMED`, only `run-completed` is
`COMPLETED`, and neither is `IDLE`, with no TTL. In `ARMED`, conductor
source writes are blocked; in `COMPLETED`, repository-source follow-ups
re-enter routing. Subagent edits, `.claude/` control notes, run-context
notes and outside-repository scratch pass. The Bash and edit branches
use the same state resolver and verdicts.

## SubagentStop order

The six finish checks run in the registered `hooks.json` order:
SkillFloor, ExecFloor, ReachFloor, ContractFloor, DigestCap,
GroundFloor. DigestCap precedes GroundFloor so a response-like block
recovered from the final assistant text is grounded on that same stop.
`run-flag arm` writes the contract baseline; ContractFloor therefore
blocks only findings introduced by the run, while `contract-check`
treats a Channels row marked `deferred` as explicit, non-blocking future
work.
