# Cereblnk Hooks — Hard Enforcement Layer

Hooks are the scarce real-enforcement resource (the execution-mechanism map consequence
#3): spent only on irreversible-damage prevention, never on style.
Cereblnk ships exactly four.

| Hook | Event | Enforces | Activation |
|---|---|---|---|
| DestructiveCommandHook | PreToolUse:Bash | blocks recursive delete, force-push, hard reset, SQL DROP/TRUNCATE, disk writes; build-artifact cleanups allowlisted | opt-in: `/cb-careful` |
| EditBoundaryHook | PreToolUse:Write\|Edit | blocks writes outside a declared directory | opt-in: `/cb-boundary <path>`; auto-engaged by /cb-bug fix stage |
| SecretGuardHook | PreToolUse:Write\|Edit | blocks writes containing likely credentials (fail-closed on detection) | **always on** |
| PostEditTestHook | PostToolUse:Write\|Edit | runs the configured test subset after edits during gate-level-3 work | policy: `.cereblnk/flags/gate3` + `.cereblnk/config/test-command` |
| DigestCapHook | SubagentStop | blocks a subagent whose returned message exceeds the computed `digest_lines_max`; names the fields a digest must carry | **always on** (inside a run ledger only) |
| ContextMonitorHook | UserPromptSubmit | measures real window occupancy from the session transcript; samples every turn to telemetry, injects a short warning past the checkpoint | **always on**, never blocks |
| ScratchGuardHook | PreToolUse:Write | blocks a new untracked file at the repository root during a run and names the run's scratch directory; releases after two nudges | **always on** (inside an active run only) |

Opt-in state lives in flag files under `.cereblnk/flags/` in the user's
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
sits idle until the user types. While a run is active (the
orchestrator arms `$CB_DIR/flags/run-active`), the FIRST stop is
blocked with a reason showing ledger progress (blocks/tasks); the
guard then renames the flag to `.nudged` and never fires again for
that run. `stop_hook_active: true` always passes. Fail-open on every
error path. Note: `~/.claude/projects/` transcripts are Claude Code's
own storage, not plugin output — HistoryArchiveHook copies from there
into the project; the originals staying put is expected.

## DelegationGuardHook (PreToolUse: Edit/Write)

The mechanical form of "the conductor never implements": while
`flags/run-active` is armed, an Edit/Write whose hook input carries no
`agent_id`/`agent_type` (i.e. the main conversation) is blocked with a
spawn-the-specialist reason; subagent edits pass. Acts only mid-run;
released by the same flag the workflows manage. First in the edit hook
chain, before EditBoundary and SecretGuard.
