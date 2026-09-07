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

## Autonomous run — 2026-08-31 onward

User is on vacation and authorized initiative: work the eval-fix backlog to
completion without waiting for prompts, Codex CLI as the implementation worker,
Claude as conductor owning quality/correctness (may also use Codex for review).
All work collects on branch `cb/1.6.0`. No PR — local-path install, branch is
the test loop. Safety-net cron fires twice an hour to resume if the pipeline
stalls (session-only, 7-day expiry).

Rules the conductor is holding to:
- Every task: Codex implements -> Claude reviews (git diff + ./scripts/verify,
  a second Codex pass where correctness is non-obvious) -> commit only if clean.
- Design-gated epics (C0 mandated-specialist policy, H0 loop-layer ownership):
  prepare analysis, do NOT decide — leave for the user.
- Task fails twice or review finds a defect Codex can't fix: stop it, note here,
  move on.
- Keep this log current so the return is legible.

### Progress log
- 2026-08-31 — branch `cb/1.6.0` cut, CB-165..168 documented, verify baseline
  green. CB-165 dispatched to Codex.
- 2026-08-31 — CB-165 DONE (d130f9c). Channels `deferred` status. +2 fixtures, +2 tests.
- 2026-08-31 — CB-166 DONE (becb83e). contract-floor baseline at run arm; only
  newly-introduced findings block, pre-existing ones are a note. +10 tests (26 total).
- 2026-08-31 — CB-167 DONE (3c3c449). ground-check wired as SubagentStop floor
  (ground-floor.sh). B0 confirmed it was un-wired. +test-ground-floor (8 cases).
  README "what blocks a finish" table corrected to real hook order. Review caught
  one miss: new files unstaged so check-exec-bit failed; staged + re-verified green.
- 2026-08-31 — CB-168 core done (Codex, uncommitted). `cb_run_state` (cbenv.sh)
  = ARMED/COMPLETED/IDLE, both delegation-guard branches use it, run-completed no
  longer reads as active, COMPLETED routing narrowed to repo source via
  cb_is_repo_source. .claude/** + context notes + out-of-repo scratch now writable
  post-run. test-hooks 148 checks, verify green here.
  REVIEW FINDING: Codex also removed the CB-099 staleness fail-open (aged run-active
  flag over a cold ledger used to be treated as absent). Now presence-only — a
  forgotten run-active flag stays ARMED until `run-flag disarm`/`complete` or the
  conductor-override hatch. This is a DESIGN CHANGE -> added to the decision doc
  for the user; epic F2 (SessionStart stale-flag detection) is now load-bearing,
  not nice-to-have. Doc-reconciliation follow-up dispatched to Codex.

  Note: env-lifecycle fails in Codex's sandbox (no AF_INET socket) — verified green here each time.
  Codex tasks run detached; cron :17/:47 drives the poll/review/commit/dispatch cycle.
- 2026-08-31 — CB-168 committed (d8589ea) + doc-reconciliation (input-policy,
  run-discipline, CHANGELOG state the presence-only model). Decision doc
  .claude/DECISIONS-1.6.0.md written (D1/D2/D3). Wave 2 planned CB-169..174.
- 2026-08-31 — Cleared a stale `run-completed` flag in this repo (from an Aug 27
  run) — post-CB-168 it put delegation-guard in COMPLETED mode and route-blocked
  conductor verification commands. This is exactly D3 / epic F2's territory.
- 2026-08-31 — CB-169 DONE (4793567). run-flag complete --decision/--gate appends
  one runs.log line + tokens_total (budget_report rollup) + tasks_shipped.
- 2026-08-31 — CB-170 DONE (f048c5c). run-guard: real "3/5 plan tasks have a
  response block" count; ledger growth no longer burns the nudge budget (only
  stagnant Stops advance the cap). test-hooks 154.
- 2026-08-31 — CB-171 DONE (ae7f64a). run-flag arm refuses a different pinned
  run; stale-run.sh SessionStart hook warns on a cold forgotten flag. 163/52.
- 2026-08-31 — CB-172 DONE (f3fb320). review-ledger.log — one line per shipping
  run, reviewed=no. Also removed the CB-169 append-failure wart. run-flag now
  ~350 lines of telemetry awk in _completion_* helpers (contained; extract-later
  noted, not blocking).
- 2026-08-31 — CB-173 DONE (4023aab). Added /cb-catchup + the
  review-ledger list/mark helper. Utility skill, no routing, one-line flip on
  explicit ack only.
- 2026-08-31 — CB-174 DONE (36fdb10). Entry-point skills arm the run before
  selecting the surface, so the skill floor has a pinned destination.
- 2026-09-01 — CB-175 DONE (8d793e4). Cut release 1.6.0.

### WAVE COMPLETE — 2026-09-01

10 eval-fix tasks (CB-165..174) + release, on branch `cb/1.6.0`.
20 commits total; `./scripts/verify` green throughout.

- Wave 1 (A/B/D epics): CB-165 contract deferred · CB-166 contract-floor
  baseline · CB-167 ground-floor hook · CB-168 delegation-guard one-state.
- Wave 2 (E/F/G/J epics): CB-169 telemetry line · CB-170 run-guard count+nudge
  · CB-171 run lifecycle guards · CB-172 review-ledger · CB-173 /cb-catchup ·
  CB-174 skill step order.
- 1.6.0: plugin.json bumped, CHANGELOG rolled up.

**Carried in from the base branch**: commit 7493558 (`fix(shellwrite)…`) came
from `cb/guard-parse-message` which this branch was cut from — it is the first
of the 20 commits. Decide whether it belongs in the 1.6.0 tag or should be
separated.

**Still waiting on the user** (do NOT decide): D1 (specialist enforcement,
blocks epic C), D2 (loop layer, blocks epic H), D3 (stale-flag model — CB-171
mitigates either way), D4 (codex-backed executor idea). All in
`.claude/DECISIONS-1.6.0.md`.

**Deferred**: J3 (cb-testbed target/ gitignore — friction with cb-testbed's own
run-completed flag).

### WAVE 3 COMPLETE — 2026-09-01 (superseded the "ends here" line above)

D1/D2/D3 decided (DECISIONS-1.6.0.md); D4 kept separate. Then, autonomously:
- CB-176 (b97868d) select-agents emits agents-required.yaml + domains.
- CB-177 (c379926) plan-lint R8: mandated specialists assigned or `merged:`
  waiver; run-guard names unfulfilled agents at Stop.
- CB-178 (5517759) run archival lifecycle: policies/run-archival.md,
  archive/<id>/, `run-flag abandon`, complete archives, /cb-resume (19th
  entry point), post-synthesis improve/fix gate in 10 workflows.
- CB-179 (f50335c) 1.6.0 documentation sweep — 17 files, zero stale counts.
- CB-180 (216bd50) run-flag 952 -> 466 lines; helpers to lib/run-lifecycle.sh,
  behaviour-preserving, every test count identical.

`./scripts/verify` green throughout. Scripted E2E of the lifecycle passed.
Test status + the reload-and-interactive checklist: `.claude/TEST-1.6.0.md`.

**Open, not scheduled**: D4 (codex-backed executor); epic-F per-run
memory-snapshot question (in run-archival.md); the systems-note image redraw;
whether `7493558` belongs in the 1.6.0 tag.

Safety-net cron stopped.

---

## Open — wave 1 (from the 2026-08-31 dispatch eval, worker: Codex CLI)

Origin: a live `/cb-dispatch` -> `/cb-do` eval run (R-2026-08-31-001, cb-testbed)
plus a structural gap analysis of the run lifecycle. Findings S1–S9 in
the session transcript; the fix themes are epics A–J there. This wave is the
three highest-value, design-decision-free items. Conductor: Claude. Worker:
Codex CLI (separate provider, off the Claude token meter for the iteration).

Workflow deviation for this wave: branch `cb/CB-XXX-slug`, Codex implements,
`./scripts/verify` green, checkbox ticked on the branch. **No PR** — the plugin
is installed from this local path, so a branch + reload is the test loop.

- [x] **CB-165** — contract-check: a `## Channels` row may be `deferred` (epic A1)
      `scripts/contract-check` skips `## Migration` rows whose status is
      `deferred` but has no deferred concept for `## Channels` rows, so the only
      way past the gate for an unimplementable channel is to hide it from the
      checker (this is what R-2026-08-31-001 T-001 was forced to do — false
      green, ruled unsound by apidesign-agent T-003).
      Acceptance: a `## Channels` row carrying a `deferred` status → `contract-check
      <root> <party>` exits 0; a non-deferred unbacked Channels row still exits 1;
      `./scripts/verify` green; a `test-hooks`/`contract-check` fixture covers both.

- [x] **CB-166** — contract-floor: pre-existing-failure baseline (epic A2)
      `exec-floor` got an honest escape for out-of-scope pre-existing failures
      (its own closed task); `contract-floor` did not — so any task touching a
      contract party inherits every prior run's contract debt and must fix it to
      stop. At run arm, snapshot `contract-check` per party to
      `context/<run_id>/contract-baseline.txt`. `contract-floor` blocks only on
      failures ABSENT from the baseline; a pre-existing failure surfaces as a
      digest risk line, not a stop-block.
      Acceptance: a contract already failing before the run does not block a
      specialist stop that did not touch that contract; a contract break
      introduced DURING the run still blocks; baseline file is written at arm and
      cleaned at complete; `./scripts/verify` green.

- [x] **CB-167** — ground-check wired as a SubagentStop floor (epic B0→B1)
      `scripts/ground-check` already resolves `path#Lx-Ly` / `doc:id#Lx` refs and
      checks `quote:` presence (grounding-policy G-2/G-3), but nothing in the Stop
      path runs it — the checker exists un-wired. B0: confirm current invocation
      points (grep). B1: if absent from SubagentStop, add a fail-open,
      nudge-capped hook that runs `ground-check` on each response block written to
      `context/<run_id>/` and refuses the subagent stop on a dangling reference.
      Acceptance: a response block citing a nonexistent file:line or an
      unresolvable ref → SubagentStop refused (bounded nudges); a block with only
      resolvable refs passes; hook fails open if `ground-check` cannot run;
      `./scripts/verify` green + a `test-hooks` scenario.

- [x] **CB-168** — delegation-guard: one run-state reader for both branches (epic D1, finding S9)
      After `run-flag complete`, three readers disagree: `run-flag status` says
      "not armed", delegation-guard's Write branch says "last run completed —
      route it", its Bash branch says "a run is active". All three block the
      conductor from writing. Extract a single run-state resolver (reuse
      `run-flag status` semantics) into `hooks/scripts/lib/`; both branches call
      it; the `run-completed` sentinel must never read as active; the post-run
      "follow-ups re-enter routing" rule applies to source-tree paths, not to
      every write.
      Acceptance: after `run-flag complete`, a conductor Write and a conductor
      Bash write get the SAME verdict, matching `run-flag status`; a write to a
      non-source path (scratchpad, `context/<run_id>/`) is allowed post-run;
      `./scripts/verify` green.

## Open — wave 2 (mechanical, no design gate — autonomous run continues)

- [x] **CB-169** — run-flag complete writes the run's telemetry line (epic E1+E2)
      `runs.log` gets no entry when a run ends; `run-flag complete` doesn't append
      and no skill reliably does. Make `run-flag complete` take `--decision` and
      `--gate` and append one `runs.log` line itself, plus a token/tasks rollup:
      sum `budget_report` tokens across `context/<run_id>/*.yaml`, count response
      blocks, write `tokens_total=` and `tasks_shipped=`. Acceptance: a completed
      run leaves exactly one dated `runs.log` line with decision, gate, token
      total and task count; missing budget fields degrade to a partial line, not
      a crash; ./scripts/verify green + a test.

- [x] **CB-170** — run-guard: honest count + nudge counter resets on progress (epic E3+E4, S6)
      The Stop nudge reports "N/0 task blocks on disk" (confusing — the conductor
      writes no task-block file) and the 3-nudge cap counts conductor turns, not
      stalls, so a healthy multi-agent run burns all three just by waiting.
      Fix: count response blocks vs plan.md checkboxes in the message; reset (or
      don't increment) the nudge counter when `context/<run_id>/` gained a
      `*.yaml` since the last Stop. Acceptance: a run that adds a block between
      two Stops does not advance the nudge count; the message names real
      artifacts; ./scripts/verify green + a test.

- [x] **CB-171** — run-active lifecycle guard (epic F1+F2 — load-bearing after CB-168)
      CB-168 removed the TTL fail-open, so a forgotten `run-active` now blocks the
      conductor until explicit cleanup. Add: (a) `run-flag arm` refuses (or loudly
      warns) if a *different* run is already armed; (b) a SessionStart hook that,
      when `run-active` points at a `context/<id>/` older than N hours with an
      all-unchecked plan, prints a one-line "stale run flag from <date> —
      `run-flag disarm` or `complete`". Acceptance: arming over an existing
      different armed run is caught; a stale flag is surfaced at session start;
      neither blocks a legitimate resumed run; ./scripts/verify green + a test.

- [x] **CB-172** — comprehension ledger (epic G1) — depends on CB-169
      Extend the `runs.log` line (or a sibling `review-ledger.log`): each shipping
      run appends files-touched, the one-sentence domain summary from synthesis,
      and `reviewed_by_human: no`. One line per run, never loaded into a working
      context. Acceptance: a shipping run appends one review-ledger line with the
      three fields; a non-shipping run (think/review) does not; ./scripts/verify
      green + a test.

- [x] **CB-173** — `/cb-catchup` skill (epic G2) — depends on CB-172
      A pull-not-push skill: read the review ledger, group unreviewed shipping
      runs, present them one at a time (summary + `git show` on request), mark
      `reviewed_by_human: yes` on acknowledgement. No diffs loaded unless asked.
      Acceptance: skill lists only `reviewed_by_human: no` runs, marks them
      reviewed on confirm, and the count is visible; manual scenario in tests/;
      ./scripts/verify green (skill authoring + check-skill-frontmatter/relations).

- [x] **CB-174** — SKILL.md step order: arm the flag before selecting the surface (S1, epic J1)
      `/cb-do` Step 2 says run `select-agents --emit-floor`, which refuses until
      the run flag is armed — but "arm the flag" is an unnumbered section far
      below. Reorder so arming is the numbered step before surface selection, in
      `/cb-do` and any sibling skill sharing the pattern (`/cb-implement`,
      `/cb-orchestrate`, `/cb-rewrite`). Acceptance: each skill's numbered steps
      run top-to-bottom without a backtrack; no behaviour change; ./scripts/verify
      green (authoring-lint).

- [x] **CB-175** — cut release 1.6.0: bump the plugin manifest, roll the
      Unreleased changelog into `[1.6.0]`, and run the release verification.

### Direct (Claude, not Codex — outside the plugin repo)
- [x] J2 — cb-testbed stale run: already clean. R-2026-08-27-006 has no `run-active`
      flag (disarmed early in this session); the newer `run-completed` marker is
      from the eval run R-2026-08-31-001. Nothing to complete — the Aug 27 run was
      abandoned mid-way (6 edits, no response blocks) and "completing" it would be
      dishonest. Left as-is.
- [~] J3 — cb-testbed `target/` gitignore: DEFERRED. cb-testbed's own
      `run-completed` flag (from the eval run) puts CB-168's delegation-guard in
      COMPLETED mode and route-blocks the `.gitignore` write. Same friction as D3.
      Low value (testbed hygiene), not worth clearing another flag mid-wave.
      Do after the wave, or when the D3 model is settled.

---

## Open — wave 3 (decided 2026-09-01, not yet started)

### Epic C — enforce mandated specialists at plan-lint (D1 decided: option a, at START)
- [x] **CB-176** — `select-agents` emits the agent roster to disk
      Add `agents-required.yaml` alongside `skills-required.yaml` from
      `--emit-floor` (and expose it on `--roster`). One entry per mandated
      specialist with its decision domain. Acceptance: emit-floor writes both
      files; `--roster` prints the spawnable names; ./scripts/verify green + test.
- [x] **CB-177** — `plan-lint` requires every mandated specialist, or a recorded waiver
      `plan-lint` (runs before Task 1) refuses a plan unless every agent in
      `agents-required.yaml` appears as a lead or reviewer on some task, OR the
      plan carries `merged: <agent> into <agent> because <reason>`. `run-guard`
      Stop reconciliation stays as the BACKSTOP for the plan-less `/cb-do` path.
      Acceptance: a plan missing a mandated specialist and no waiver → plan-lint
      fails with the missing names; a `merged:` line satisfies it; the `/cb-do`
      single-task path is covered by run-guard; ./scripts/verify green + tests.

### Epic F — interrupted-run recovery + archival (D3 expansion — NEEDS /cb-design FIRST)
- [x] **CB-178** — the run archival lifecycle (spec, then build)
      Post-synthesis "anything to improve/fix?" gate; `.claude/cereblnk/archive/
      <run_id>/` mirroring `context/<run_id>/`; `/cb-abandon` (or `run-flag
      abandon`) moving a dead run to archive + clearing transient state;
      `/cb-resume` re-arming the same id; `memory/` edits surfaced not reverted
      on abandon. Codex drafts the spec first (context/<id>/archive-lifecycle.md);
      the one open question — optional per-run memory snapshots, with the
      "a later run built on it" hazard — is flagged for the user, not decided;
      then implement the parts that don't depend on that question.

### Epic — 1.6.0 documentation sync
- [x] **CB-179** — update every reference doc for the 1.6.0 surface
      README.md, plugins/cereblnk/README.md, plugins/cereblnk/hooks/README.md,
      docs/TOPOLOGY.md, docs/05_EXECUTION_REALITY_MAP.md, and any doc 00–09 that
      names hook counts / floor lists / entry points / the run flag model.
      1.6.0 changed: +2 hooks (ground-floor, stale-run → 22 total), the finish
      floors are now six, +2 entry points (/cb-catchup, /cb-resume → 19), run-state is
      presence-only (ARMED/COMPLETED/IDLE), run-flag complete writes telemetry,
      review-ledger.log + /cb-catchup exist, contract-floor has a baseline,
      Channels rows can be deferred. `check-readme` enforces the counts; make
      every prose statement match the tree. ./scripts/verify green.

- [x] **CB-180** — extract run-flag's lifecycle helpers to a library
      `run-flag` is now 952 lines — CB-166 (contract baseline), CB-169/172
      (telemetry rollup), CB-178 (archival) all piled awk/parsing into a
      lifecycle-critical script that arms the delegation boundary. Move the
      `_completion_*`, `_archive_*`, `_memory_touch_list`, `_clear_run_transients`
      helpers into `plugins/cereblnk/scripts/lib/run-lifecycle.sh` (or a small
      `scripts/run-telemetry` + `scripts/run-archive` pair), sourced by run-flag.
      Behavior-preserving — the existing tests must pass unchanged, plus a note
      that the arm/disarm/abandon/complete verbs are byte-identical in behaviour.
      Acceptance: run-flag back under ~400 lines; ./scripts/verify green with the
      SAME test count; no CHANGELOG behaviour entry (pure refactor, a Changed
      "internal" note at most).

### Open — wave 4 (from the 2026-09-01 interactive test, `.claude/TEST-1.6.0.md`)

- [x] **CB-181** — response-block persistence is a mechanism, not per-agent diligence (F-A + F-B)
      In the live run `backend-agent` wrote `context/<id>/T-001.yaml` / `T-002.yaml`;
      `apidesign-agent` returned its full ACP block in the message and wrote no
      `T-003.yaml`. CB-177's backstop then kept flagging apidesign as missing, and
      the conductor could not reconcile it (`cbowner.sh` post-CB-168 makes
      `context/<id>/*.yaml` specialist-owned so DelegationGuard blocks the write).
      `digest-cap.sh` (SubagentStop) already writes `digest.<agent>.<ts>.txt` for
      EVERY subagent. Fix: when that digest text is a parseable ACP block
      (`kind: response|verification|challenge` + a `task_id:`), digest-cap also
      writes `context/<id>/<task_id>.yaml` — so persistence covers every agent.
      run-guard's backstop and ground-floor read those. Acceptance: an agent that
      returns a block but writes no yaml still gets a `<task_id>.yaml` on disk
      via the hook; run-guard stops flagging it; a non-block digest writes no
      yaml; ./scripts/verify green + tests.

- [x] **CB-182** — review-ledger files list is source only (F-C)
      `_completion_review_file_list` in `lib/run-lifecycle.sh` listed
      `context/<id>/T-001.yaml` and `plan.md` alongside real source. Filter out
      `.claude/**`, `context/**`, and the run's own bookkeeping — the list should
      be the source paths a reviewer would `git show`. Acceptance: the
      review-ledger line for a run names only source files; a run that only
      touched `.claude/` files lists `-`; test.

- [x] **CB-183** — archive-pointer session_id resolution (F-D)
      `archive-pointer.txt` wrote `session_id: -`. Try harder:
      `$CLAUDE_SESSION_ID`, then `state.md`, then the run's `history/*.jsonl`
      filename (encodes the session). Acceptance: when any source has it, the
      pointer carries a real session id; still `-` only when none do; test.

Epic H (loop layer): CLOSED for now — see DECISIONS D2. Revisit after D4.

### Autonomous continuation — 2026-09-01
User: do it all except D4, autonomously via Codex (this workflow shipped a lot
without hitting limits). Order: CB-176, CB-177, CB-178 (spec then partial build),
CB-179. Leak check done — CHANGELOG/commits/source clean; 3 planning-doc phrases
genericized. Safety-net cron re-armed.

---

## Design decisions for the user (do NOT decide autonomously)

Full analysis in `.claude/DECISIONS-1.6.0.md`.

- **D1** — DECIDED 2026-09-01: enforce at plan-lint, not synthesis (epic C above).
- **D2** — DECIDED 2026-09-01: no loop layer, epic H closed pending D4.
- **D3** — DECIDED 2026-09-01: (a) presence-only + the epic-F recovery spec above.
- **D4** — codex-backed executor / host portability: kept separate, its own
  design conversation when the user is ready (data from this wave recorded in
  DECISIONS-1.6.0.md).

Superseded framing (kept for history):
- **D1 (was epic C0)** — mandated-specialist enforcement: is "specialist saw the
  discovery trigger but never loaded the skill / was never spawned" a defect the
  gate should block, or in-bounds judgment? Blocks epic C.
- **D2 (was epic H0)** — the loop layer: does cereblnk own trigger/schedule/
  compounding-state/budget-stop, or integrate Claude Code `/schedule`+`/goal`+
  worktrees and stay the harness? Blocks epic H (and the eval's biggest gap).
- **D3 (new, from CB-168)** — stale `run-active` flag: CB-168 made it presence-only
  (forgotten flag stays ARMED until explicit cleanup). Keep that, or restore a
  staleness fail-open (and make `run-flag status` staleness-aware too)? CB-171
  mitigates either way but the model choice is yours.

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
- [x] **CB-141** — The seventy-seven skills the host could not see
- [x] **CB-142** — The cascade is advisory, and the policy now says so
- [x] **CB-143** — The floor routed the contract and forgot the implementer
- [x] **CB-144** — A conductor counted idle while its specialists run
- [x] **CB-145** — The checkpoint is this project's threshold, not the host's
- [x] **CB-146** — A suite that reads its own shell is not a suite
- [x] **CB-147** — Run-reading hooks guessed which run they were in
- [x] **CB-148** — The routing map's `roles:` field could not route
- [x] **CB-149** — Automatic routing was a description, not a mechanism
- [x] **CB-150** — The monitor was worst exactly after a compaction
- [x] **CB-151** — A finished run had no way to say so
- [x] **CB-152** — The skill floor judged the run, not the pass
- [x] **CB-153** — A gate verdict could not be checked for staleness
- [x] **CB-154** — Revising a block cost more than being wrong
- [x] **CB-155** — The intake surface had a reader and no writer
- [x] **CB-156** — A wave could pair a gate with an edit to its target
- [x] **CB-157** — Three checkers that misread their own inputs
- [x] **CB-158** — Comments that told the changelog's story
- [x] **CB-159** — The staleness gate was an instruction the linter never read
- [x] **CB-160** — The skill floor was hand-copied to two places
- [x] **CB-161** — The exec floor promised what it could not check
- [x] **CB-162** — A contract could not name the path clients actually call
- [x] **CB-163** — Reachability covered Java types and no Java methods
- [x] **CB-164** — The manifest stopped declaring its own entry points

### CB-184 — redesign the 1.6.0 systems note (fresh session, not autonomous)
GPT-5's HTML/SVG attempt (committed ae72d38, reverted 79ac0c6) was content-
accurate but colours + sizing + density did not match the original hand-made
sheet. Do this in a fresh session with the `artifact-diagramming` skill loaded:
match the original's dense one-sheet aesthetic (monospace labels, tight panels,
the red refused-stop arrow), the 1.6.0 content from `.claude/SYSTEMS-NOTE-SPEC.md`
(delivered to the user as a file), export to PNG, replace docs/assets/
cereblnk-systems-note.png, drop the "predates 1.6.0" note in README + CHANGELOG.
Old PNG + note are back in place until then — not blocking.

  ATTEMPT 1 (2026-09-02, reverted ed3382c→fdea88c): GPT-5 v3 HTML matched
  the original's palette/format/no-version, content 1.6.0-correct, but SVG
  <text> has no wrapping — labels overflow their panels in a real browser
  (looked fine only in GPT's own render). Draft kept at scratchpad
  systems-note-v3-draft.html. Next attempt: give the drafter a hard rule —
  every <text> must fit its <rect> (measure, or use <foreignObject> with
  wrapping divs, or tspan-wrap by hand), render-test in an actual browser
  before delivering. artifact-diagramming skill, fresh session.
