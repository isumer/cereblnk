# Run Archival Policy

Class: D — the terminal lifecycle for Cereblnk run context. This policy
extends `run-discipline.md` §5; that section remains authoritative for
arming, pausing, and the `run-completed` handoff.

## 1. Synthesis is not the end of a run

A workflow that reaches synthesis asks the operator: **Anything to
improve or fix?** It does not call `scripts/run-flag complete` before the
answer.

- **No:** complete the run. Completion performs its handoff and telemetry
  append, then archives the run context.
- **Yes:** keep `$CB_DIR/context/<run_id>/` live and enter an improvement
  loop. The existing plan, Response Blocks, digests, and other evidence
  remain the run ledger. After the requested improvements are verified and
  synthesized, ask again. Archive only when the operator is satisfied.

The question is a deliberate user wait, so the ordinary §5
disarm-before-asking rule applies. Resume re-arms the same run id. A run is
therefore synthesized but still live until the operator accepts it; only
acceptance crosses the archival boundary.

## 2. Live and archived layout

`$CB_DIR/context/` contains live runs. A retired run moves, as one directory,
to:

```
$CB_DIR/archive/<run_id>/
```

The run id remains the stable key. The archived directory retains the same
run-owned structure it had under `context/<run_id>/`: `plan.md`, spec
sections, inbox, Response Blocks, digests, logs, edit and execution ledgers,
and any other durable run evidence. Retirement does not reconstruct or copy
that evidence.

Each retired directory also contains `archive-pointer.txt`, with these
single-line fields:

```
run_id: <run_id>
session_id: <session id, or ->
spec: <spec name/path, or none|->
archived_at: <UTC ISO-8601 timestamp>
```

The session id and spec are best-effort metadata. Missing metadata never
prevents retirement; `-` records that it was unavailable. The pointer is
written into the live directory before the move so an archived directory is
never published without it.

Archival is atomic-ish and fail-closed: create `archive/`, refuse to replace
an existing `archive/<run_id>/`, write the pointer, move the directory with
`mv`, then verify that the archived directory exists and the live directory
does not. A failed move must not be reported as an archived run.

## 3. Normal completion

`scripts/run-flag complete [cb_dir] [run_id]` resolves the run id using the
explicit argument, then the validated CB-147 pin, then the historical newest
live-context fallback. It performs the terminal operations in this order:

1. Hand off `run-active` to `run-completed` and clear transient flag state.
2. Read the still-live run context and append completion telemetry to
   `telemetry/runs.log`; for a shipping run, append its operator-review record
   to `telemetry/review-ledger.log`.
3. Add the archive pointer and move `context/<run_id>/` to
   `archive/<run_id>/`.

Telemetry is deliberately computed before the move, so the CB-169 cost and
task rollup and the CB-172 touched-file review record keep their existing
inputs. Neither log stores a `context/<run_id>/` path today. If a future
record stores a run-directory path, it must write `archive/<run_id>/` or use
a resolver that checks the live path first and the archived path second.

`/cb-catchup` is unaffected: it lists `telemetry/review-ledger.log`, offers
`git log` or `git show` only on request, and never reads a run context
directory. Marking a review changes only the append-only cross-run ledger.

Completion without a resolvable live context retains its existing degraded
handoff and partial-telemetry behavior; there is simply no directory to
archive. Completion must report that no context was archived rather than
inventing a run id or moving a guessed non-run path.

## 4. Abandoning a crashed or stale run

`scripts/run-flag abandon [cb_dir] [run_id]` retires a run that cannot be
completed honestly. It uses the same explicit-id, validated-pin, then
newest-live-context resolution as completion.

Before moving the directory it clears run-owned transient state:

- `contract-baseline.txt`
- run-floor and nudge `*.state` markers
- `run-guard.last-progress`
- the global `flags/run-active.state`, `run-active.nudged`, and
  `run-active.witness` markers

It removes `run-active` and verifies removal. It does **not** write or retain
`run-completed`: abandonment is retirement without the successful-run
handoff. It then writes the archive pointer and moves the live directory by
the same collision-refusing, verified archival operation as completion.

Before retirement, the command derives touched paths from the run's
`edited-files.log`, falling back to Response Block `artifacts` or
`files_touched` fields for older runs. It prints a sorted, deduplicated list
limited to these durable memory classes for operator review:

- `memory/contracts/`
- `memory/briefs/`
- `memory/requirements/`

An empty result is stated explicitly. The list is evidence, not an undo
plan: `abandon` never edits, moves, or reverts anything in `memory/`.

## 5. Project state that is never archived or reverted

These directories stay in place across both completion and abandonment:

- `memory/` — contracts, briefs, requirements, and other durable knowledge
- `telemetry/` — `runs.log`, `review-ledger.log`, and other append-only,
  cross-run observations
- `config/` — project-level runtime configuration

Only the selected per-run directory moves. Archival never reverts repository
source or project memory.

## OPEN QUESTION — stronger abandonment with memory snapshots

**Do not implement this in CB-178. Route it through `/cb-design`.**

A stronger abandon mode could snapshot each `memory/` file immediately
before a run changes it, generalizing the CB-166 contract baseline, and then
offer to restore those snapshots when the run is abandoned.

The hazard is cross-run causality: a later run may already have built on the
dead run's memory edit. Restoring the older snapshot would silently invalidate
the later run's assumptions and could erase legitimate knowledge. Any design
needs dependency tracking, conflict detection, and an operator-visible
decision rather than an automatic rollback. Until that design exists,
abandonment lists memory touches and never reverts them.
