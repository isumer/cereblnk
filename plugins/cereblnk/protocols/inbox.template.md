# Inbox — <run_id>

written_by: conductor
run_id: <run_id>
date: <YYYY-MM-DD>
acp_version: "1.0"

Every user message arriving during a run lands here at the next task
boundary, with its class (input-policy §3). Unchecked `- [ ]` means
unresolved; `correction` and `invalidation` hold the loop,
`clarification` never does. `scripts/run-status` counts both.

Format — one entry, one checkbox, disposition on the second line:

- [ ] 2026-07-25T14:02 · class: correction · "store drafts as JSONB, not a shadow table"
      → routed: database-agent · disposition: pending
- [x] 2026-07-25T14:10 · class: clarification · "why is slice 3 first?"
      → answered inline · disposition: closed, no artifact change
- [x] 2026-07-25T15:30 · class: invalidation · "drafts must survive hard delete"
      → routed: architect-agent · disposition: REWORK Task 2, plan v3

Rules:
- Class is assigned at intake, never retroactively softened to unblock
  the loop — downgrading a `correction` to `clarification` to keep
  moving is the violation this file makes visible.
- A closed entry states what changed (artifact + version) or states
  explicitly that nothing changed.
- Entries are never deleted; the file is run-scoped and dies with the
  run's context directory.
