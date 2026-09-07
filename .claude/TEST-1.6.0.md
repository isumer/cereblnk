# cereblnk 1.6.0 — test status & reload checklist

Branch `cb/1.6.0`. 25 commits over the base. `./scripts/verify` green
(42 suites; the lone red is `test-env-lifecycle`, which needs an AF_INET
socket the CI sandbox denies — it passes on this machine).

## What is already verified (scripted / deterministic layer)

`./scripts/verify` covers all of it. Plus a direct end-to-end walk of the
run lifecycle (conductor ran it against real files, not the plugin):

| Mechanism | Check | Result |
|---|---|---|
| CB-171 arm conflict | `run-flag arm R-2` over a pinned `R-1` refuses; same-id re-arm is idempotent | PASS |
| CB-176 roster emit | `select-agents --emit-floor` writes BOTH `skills-required.yaml` and `agents-required.yaml` (with domains) | PASS |
| CB-177 plan-lint R8 | a plan missing a mandated specialist fails, names it "unassigned and unwaived"; a `merged:` header waiver clears it | PASS |
| CB-165 deferred Channels | `test-contract-check` (26 checks) — deferred row not enforced, active unbacked row flagged | PASS (suite) |
| CB-167 ground-floor | a Response Block citing `src/nonexistent.txt#L5-L9` → SubagentStop blocked (exit 2) | PASS |
| CB-169/172/178 complete | `run-flag complete` writes `runs.log` (`tokens_total=`), a `review-ledger.log` line, and moves `context/<id>/` → `archive/<id>/` with `archive-pointer.txt` | PASS |
| CB-173 review-ledger | `review-ledger list --unreviewed` / `mark <id>` — filters, one-line flip, idempotent | PASS |
| CB-178 abandon | `run-flag abandon` lists the run's `memory/` touches, archives the context dir, writes NO `run-completed` | PASS |

## Interactive test — RUN 2026-09-01 (plugin reloaded, 1.6.0 live)

A real `/cb-do` in cb-testbed: "add GET /api/users/count". Run
R-2026-09-01-001, 2 tasks + an apidesign review. cb-testbed restored to
its pre-test state afterward; the run's archive + telemetry remain as
evidence.

| # | Mechanism | Result |
|---|---|---|
| CB-174 | `/cb-do` Step 2 is "Arm the run flag", before select-surface | ✅ live |
| CB-176 | `select-agents --emit-floor` prints `emit_agents:` and writes `agents-required.yaml` (2 specialists + domains) | ✅ |
| CB-166 | `contract-baseline.txt` written into the run dir at arm | ✅ |
| CB-177 plan-lint | `plan-lint` passed with both agents assigned (apidesign as reviewer); a stripped copy failed naming the unassigned agent | ✅ |
| CB-177 backstop | the Stop nudge named `mandated agents with no response block: apidesign-agent` until its block appeared — S5 gap now surfaced loudly | ✅ |
| CB-170 | nudge reads `1/0 plan tasks have a response block`, real-artifact language, not "N/0 task blocks" | ✅ |
| D1 path | conductor spawned apidesign-agent to actually review; it returned a full ACP block, sound-with-recommendations | ✅ |
| CB-178 archive | `run-flag complete` → `archived (.../archive/R-2026-09-01-001)`; `context/<id>/` gone, archive dir holds plan+blocks+digests + `archive-pointer.txt` | ✅ |
| CB-169 | `runs.log` line: `… · /cb-do · … · tokens_total=12600 · tasks_shipped=2` | ✅ |
| CB-172 | `review-ledger.log` line: date · run_id · reviewed=no · files=… · goal summary | ✅ |
| CB-173 | `review-ledger list --unreviewed` showed it; `mark` flipped it to `reviewed=yes` | ✅ |
| CB-171 / catchup / resume (no state) | `/cb-catchup` on empty ledger and `/cb-resume` with no pin both stop correctly | ✅ |

### Findings from the interactive run (new, low severity)

- **F-A — response-block persistence is inconsistent between agent types.**
  `backend-agent` wrote `T-001.yaml` / `T-002.yaml` into `context/<id>/`;
  `apidesign-agent` returned its ACP block in the message but wrote no
  `T-003.yaml`. CB-177's backstop then kept flagging apidesign as missing
  even though the review happened. Pre-existing, but 1.6.0 made it visible.
- **F-B — the conductor cannot reconcile a missing block.** The nudge's
  "NEITHER" case says "reconcile the run ledger", but `cbowner.sh`
  (post-CB-168) makes `context/<id>/*.yaml` specialist-owned, so
  DelegationGuard blocks the conductor from writing the missing block.
  Only path is re-spawning an agent to write it.
- **F-C — `review-ledger` files list mixes source with bookkeeping.** It
  listed `context/<id>/T-001.yaml` and `plan.md` alongside the real
  source files. Should list only source paths (from `edited-files.log`).
- **F-D — `archive-pointer.txt` `session_id: -`.** `CLAUDE_SESSION_ID`
  not set and the `state.md` lookup missed; minor, findability only.

None block. F-A/F-B are the meatiest — worth a wave-4 task (make every
cereblnk agent persist its block, or let the conductor reconcile one).

---

## Full checklist reference (pre-reload plan — mostly covered by RUN above)

1. **Routing still works** — `/cb-dispatch` on a plain request routes; `/cb-do`
   on a stated change runs.
2. **Step order (CB-174)** — in a real `/cb-do` run, arming the flag is the
   numbered step before `select-agents --emit-floor`; no backtrack.
3. **plan-lint R8 in a live run (CB-177)** — start a `/cb-implement` or `/cb-do`
   that select-agents scopes to 2+ specialists; give it a plan that only
   assigns one; confirm plan-lint refuses before Task 1 with the missing name,
   and that adding a `merged:` line or the second specialist clears it.
3b. **run-guard backstop** — a plan-less `/cb-do` single-task run where a
   mandated agent gets no response block: the Stop nudge names it.
4. **ground-floor in a live run (CB-167)** — hard to force deliberately;
   watch that specialist Response Blocks with real `file:line` evidence still
   close cleanly (no false blocks).
5. **Archival on complete (CB-178)** — finish a real run; confirm the
   post-synthesis "anything to improve or fix?" question appears; on "no",
   `context/<id>/` ends up under `archive/<id>/`, `runs.log` +
   `review-ledger.log` each get their line.
6. **`/cb-catchup`** — after a shipping run, run it: it should list the
   unreviewed run, show it once, and mark it reviewed only on explicit ack.
7. **`/cb-resume`** — arm a run, half-finish a plan, kill it; new session,
   `/cb-resume` should re-arm the same id and continue from the first
   unchecked task.
8. **`run-flag abandon`** — a stale/crashed run; `stale-run.sh` at SessionStart
   should now point at `/cb-resume` and `run-flag abandon`.
9. **`contract-floor` baseline (CB-166)** — a run touching a contract party
   that ALREADY has a stale finding: the specialist can still stop (the
   pre-existing finding is a note, not a block); a finding introduced during
   the run still blocks.

## Known / carried

- Commit `7493558` (`fix(shellwrite)…`) is the base of the branch, inherited
  from `cb/guard-parse-message` — decide whether it belongs in the 1.6.0 tag.
- `docs/assets/cereblnk-systems-note.png` needs a redraw for the new counts
  (noted in CHANGELOG); the alt text and prose are corrected.
- `DECISIONS-1.6.0.md` D4 (codex-backed executor) and the epic-F open question
  (per-run memory snapshots) are unresolved by design — your call.

### Wave 4 — findings F-A..F-D fixed (2026-09-01)

- CB-181 (f80b7ed) — F-A/F-B: `digest-cap` persists any agent's ACP block to
  `context/<id>/<task_id>.yaml` (no-clobber); hooks.json runs DigestCap before
  GroundFloor. Block persistence is a mechanism now.
- CB-182 (e6436bf) — F-C: `review-ledger` files list filtered to source only
  (drops `.claude/**`, context paths, bookkeeping basenames).
- CB-183 (<commit>) — F-D: `archive-pointer` session_id also resolves from the
  run's `history/*.jsonl` filename and a context-dir grep.

All committed on cb/1.6.0, `./scripts/verify` green. Safety-net cron stopped.
