# Decisions for the user — cereblnk 1.6.0 wave

Written by the autonomous run (Claude conductor). Three questions I will not
decide alone. Each has a recommendation, the tradeoff, and what the choice
unblocks. Answer inline or in a reply; I'll route the follow-up work.

Context: these come out of the 2026-08-31 `/cb-dispatch` eval (findings S1–S9)
and a structural gap analysis of the run lifecycle. Wave 1 (CB-165–168)
shipped the design-free fixes; these three are gated on your call.

---

## D1 — mandated-specialist enforcement (blocks epic C)

**The situation.** `select-agents` emitted `apidesign-agent` + `backend-agent`
for the eval task. The conductor spawned only `backend-agent` and folded
`api-design` in as a skill. Every upstream check passed — `skill-floor` verifies
skills *loaded*, not agents *spawned*. Only the after-the-fact verifier
(`V-GATE-V`) caught it, and downgraded the run to "weakened". `HANDOFF.md §2`
already flagged this as an open question.

**The question.** When a run finishes without spawning a specialist that
`select-agents` mandated, is that:
- **(a) a defect** — a new floor should refuse the conductor's final synthesis
  until every mandated specialist has a block on disk (nudge-capped, overridable
  with a recorded reason); or
- **(b) in-bounds judgment** — the conductor legitimately merges specialists for
  small tasks, and the verifier catching it after the fact is the right place.

**Recommendation: (a), but soft.** A `Stop`-time reconciliation in `run-guard`
(not a hard new hook): list mandated specialists with no response block, and
either refuse once with a nudge, or require a one-line `merged: <agent> into
<agent> because <reason>` in the plan. Rationale: the eval showed the verifier
*can* catch it, but only at gate level 2+; a level-1 run has no verifier, so the
omission ships silently. Soft enforcement closes that without removing the
conductor's judgment.

**If (a):** epic C = CB-17x (extend `run-guard` specialist reconciliation) +
`select-agents --emit-floor` also writes `agents-required.yaml`.
**If (b):** epic C is closed as "working as intended"; document the conductor's
merge latitude in `agent-selection-policy.md` so it's a stated allowance.

### DECIDED 2026-09-01 — (a), enforce at START not at synthesis.

The user's refinement (correct): rejecting at synthesis is late and lossy — the
missing specialist can only review finished code, and it costs a full round trip.
Enforce early instead:
- `select-agents --emit-floor` also emits `agents-required.yaml` (the roster).
- `plan-lint` (runs before Task 1) refuses a plan unless every mandated
  specialist appears as a lead or reviewer on some task, OR the plan carries an
  explicit `merged: <agent> into <agent> because <reason>` waiver line. The
  waiver keeps the conductor's judgment for genuinely trivial merges (no
  wasteful 3-agent spawns for a one-line change) — it just has to be recorded,
  never silent.
- `run-guard` Stop reconciliation stays, as the BACKSTOP only: the plan-less
  `/cb-do` single-task path, and the case where plan-lint was bypassed.

Epic C ≈ 2 small tasks: `select-agents --roster`/`agents-required.yaml` output,
and the `plan-lint` rule + `merged:` waiver grammar.

---

## D2 — the loop layer (blocks epic H, the eval's biggest structural gap)

**The situation.** Measured against a generic autonomous-run model — trigger,
work, gate, state, stop — cereblnk is a strong **harness** (isolated Work + mechanical
Gate) with **no loop**: no non-human trigger, no schedule, no compounding
cross-run state, no enforced budget stop. Every run is synchronous, one session,
human-in-the-loop at every wait point.

**The question.** Does cereblnk:
- **(a) own the loop layer** — add a scheduled/proactive entry point, a
  `STATE.md`/`VISION.md` standing-state pair, cross-run carry-over, and an
  enforced per-run + daily token ceiling that halts; or
- **(b) stay the harness** — document the integration seam with Claude Code's
  native `/schedule` + `/goal` + worktrees, add only the enforced **budget
  ceiling** (which is in-scope regardless and is a real current gap), and leave
  scheduling/persistence to the platform.

**Recommendation: (b) plus the budget ceiling.** cereblnk's value is verification
discipline *within* a run; owning a scheduler duplicates platform capability that
will age with it (same reason the plugin ships no model names). The budget
ceiling (per-run + daily token cap that actually stops the run) is the one piece
of the "stop" primitive that belongs in cereblnk no matter what — the eval run
burned ~430K subagent tokens for ~8 lines with nothing measuring or capping it.

**If (a):** epic H is large — a design brief via `/cb-frame` first.
**If (b):** epic H shrinks to one task (the budget ceiling) + a
`docs/LOOP-INTEGRATION.md` showing the `/schedule` + cereblnk pattern.

### DECIDED 2026-09-01 — NEITHER. Epic H closed for now, subordinate to D4.

The user: do not implement the loop layer at all right now — any loop-layer
machinery (scheduler, cross-run state, even a `/schedule` integration doc)
couples cereblnk tighter to the Claude Code host, which conflicts with D4's goal
of running cereblnk with local LLMs outside Claude. The budget-ceiling question
folds into D4: token counts come from the host, so a run-halting budget cap can
only be designed once D4's direction is set. Revisit epic H after D4.

---

## D3 — stale `run-active` flag model (new, from CB-168)

**The situation.** Before CB-168, `delegation-guard` had a private TTL: a
`run-active` flag older than 8h over a cold context ledger was treated as absent
(fail-open) — "a forgotten flag can never brick a project" (CB-099). CB-168
unified run-state to **presence-only** (`cb_run_state` → ARMED/COMPLETED/IDLE,
matching `run-flag status`) and removed the TTL. A forgotten `run-active` now
stays ARMED — blocking the conductor from repo-source edits — until `run-flag
disarm`/`complete` or the `conductor-override` hatch.

**The question.**
- **(a) keep presence-only** (current state after CB-168) — one source of truth,
  stale flags handled by CB-171's SessionStart detector prompting explicit
  cleanup; or
- **(b) restore a staleness fail-open** — and make `run-flag status` staleness-
  aware too, so the "one answer" property holds.

**Recommendation: (a).** The TTL fail-open had its own failure mode (a real run
legitimately paused >8h silently lost its delegation boundary), and a silent
timeout is a weaker mitigation than CB-171's explicit "stale flag from <date>"
prompt at session start. Presence-only is also what makes `cb_run_state` and
`run-flag status` genuinely agree — the whole point of CB-168.

**If (a):** nothing more to do; CB-171 ships the SessionStart detector.
**If (b):** a follow-up adds a shared staleness check to both `cb_run_state` and
`run-flag status`, keyed off context-ledger mtime, with the TTL configurable.

### DECIDED 2026-09-01 — (a) presence-only, PLUS an epic-F expansion.

Core: (a). CB-168 + CB-171 already ship it; no code for D3 itself.

But the user identified a bigger gap: a stale flag is an *interrupted unit of
work*, and the system should help decide its fate, then tidy up. This becomes a
proper epic-F design (needs `/cb-design`, not a one-liner):

**Run lifecycle gains an archival stage.**
- A run is not "done" at synthesis. After synthesis, ASK the user: anything to
  improve or fix? If no → archive. If yes → the run stays live in `context/` for
  the improvement loop; archived only when the user is finally satisfied.
- New `.claude/cereblnk/archive/<run_id>/` — retired run context dirs move here,
  structure IDENTICAL to the live `context/<run_id>/` (plan.md, spec, response
  blocks, digests, history). Key stays `run_id`; the archived dir may also carry
  a `session_id` / spec pointer for findability.
- `/cb-abandon` (or `run-flag abandon`): a crashed/stale run → `archive/<run_id>/`,
  flag removed, transient state (contract-baseline, nudge markers) cleared.
- `/cb-resume`: re-arm the same run id, continue from the first unchecked task.
  No move. (`plan-status` already does most of this — needs a clean entry point.)

**Not moved / not reverted, on abandon:** `memory/` (contracts, briefs,
requirements), `telemetry/` (runs.log, review-ledger — append-only, cross-run,
readers need them whole), `config/` (project-scoped). Reason for memory
specifically: no per-run edit history (`.claude/cereblnk/` is git-ignored `*`),
contracts are cross-run by design, and a later run may have built on the dead
run's edit. So abandon SURFACES what the dead run touched in `memory/` and lets
the user decide keep/revert by hand.

**Open design question for the spec:** an optional stronger version — each run
snapshots the `memory/` files it is about to touch (like CB-166's contract
baseline) and `/cb-abandon` offers to restore them. Has the "a later run built
on it" hazard; more machinery. Decide during `/cb-design`.

---

## D4 — codex-backed executor / host portability (raised 2026-08-31)

The user's idea: cereblnk running outside local Claude Code, with model
discovery, and — when the `codex` plugin is present — dispatching implementation
tasks to Codex instead of Claude subagents.

### 2026-09-01 — kept SEPARATE from the epic-F recovery work.

D4 is a strategic direction question about the *execution substrate* (Claude
subagent vs Codex vs local LLM) and *host portability* (does cereblnk require
Claude Code). Epic F recovery/archival is host-agnostic disk-state management —
they do not need to be coupled. D4 gets its own design conversation, informed by
this 1.6.0 wave's data:

- Codex worker quality was good — 10 tasks, none failed twice, wrote its own
  tests, ran its own verify.
- Friction: Codex's sandbox mounts `.git` read-only and has no AF_INET socket →
  it cannot commit and cannot run `test-env-lifecycle` → the Claude conductor
  had to verify every result and do every commit.
- Codex detached jobs send no completion notification → polling / a cron was
  needed.
- Codex output carries NO ACP discipline (no epistemic labels, no evidence
  refs) — plain "here is what I changed" reports. The conductor re-derived the
  verification each time.

Not scheduled. Own conversation when the user is ready.

---

## Not blocked on you — proceeding autonomously

Wave 2: CB-169 (telemetry line), CB-170 (run-guard count/nudge), CB-171
(run-active lifecycle guard), CB-172 (comprehension ledger), CB-173
(`/cb-catchup`), CB-174 (SKILL.md step order), then the 1.6.0 version bump.
Progress log in `BACKLOG.md`.
