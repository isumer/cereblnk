# Input Policy

Binding on EVERY workflow, at EVERY stage. User input is not a
conversational aside to be answered by whoever is holding the
conversation — it is the highest-authority input the system receives,
and it gets the same structural treatment as any other input:
classified, labeled, routed, recorded.

The failure this policy exists to prevent: a request enters, the
conducting conversation answers it fluently, and it reaches no
specialist and no artifact. It feels absorbed and is gone.

## 1. Two hats (I-1)

The same person speaks in two registers, and the register decides the
epistemic treatment. Getting this wrong causes two opposite failures.

| Hat | Example | Treatment | If mistreated |
|---|---|---|---|
| **Customer** — intent, constraint, priority | "this must ship Friday", "auditors need every draft" | Authoritative. Becomes a premise; requirements-agent makes it testable. Not debated, not verified. | Treated as a claim → the system argues with the user about what they want |
| **Engineer** — mechanism, design, technique | "use JSONB, not an audit table" | A technical claim like any other: labeled, routed to the domain owner, challengeable on evidence | Treated as intent → enters the artifact as `known` without a specialist reading the code (Part II #9, confidence laundering) |

When the register is ambiguous, ask — one question, before routing.
Guessing the hat is guessing the epistemic label.

**Checker:** ConsistencyAgent rejects any artifact fact whose only
provenance is "the user said so" while labeled `known` — user-origin
mechanism claims carry their routing verdict or stay `assumed`.

## 2. Routing (I-2)

Engineer-hat input routes through `select-agents` to the owner of the
affected artifact section, in that owner's own window. The architect
integrates the verdicts and adjudicates structure — it never answers
in place of the domain owner (a single reviewer for everything is
Manifesto §2's monolithic-reasoning failure). The conductor relays;
it does not evaluate.

**Checker:** VerifierAgent confirms at gate time that every revised
section carries a fresh specialist block from that section's owner.

## 3. Mid-run intake (I-3)

Input arriving during a run is queued to the next task boundary —
never applied mid-task, which would break the one-commit-per-task
atomicity. At the boundary it is classified:

| Class | Meaning | Loop behavior |
|---|---|---|
| `clarification` | asks about work, changes nothing | answered, closed, loop continues |
| `correction` | changes unstarted work | plan reconstruction (memory-policy R-3), loop holds until folded |
| `invalidation` | contradicts completed work | surfaces as REWORK, never silent, loop holds |

Entries live in `$CB_DIR/context/<run_id>/inbox.md`
(`protocols/inbox.template.md`). `scripts/run-status` reports
`inbox: N unresolved (M blocking)`; the loop does not advance past
a nonzero blocking count.

**Checker:** run-status blocking count at every task boundary; a
`completed` run with blocking inbox entries is a protocol violation.

## 4. Post-run follow-ups (I-4)

A completed run hands `flags/run-active` off to
`flags/run-completed`, which keeps DelegationGuard armed through the
follow-up window (TTL-bounded, default 8h, `CB_COMPLETED_TTL_HOURS`).
A follow-up re-enters routing at dispatch step 1 — it is not handled
freehand because the last workflow finished.

**Checker:** DelegationGuardHook (mechanism) for edits;
`test-hooks` covers armed, subagent-allowed, and stale-flag paths.

## 5. Honest limit (I-5)

The guard sees `Edit|Write|MultiEdit|NotebookEdit` and nothing else.
A conductor that *evaluates* a follow-up freehand — opinions, design
verdicts, technical judgments with no file touched — crosses no tool
boundary and cannot be mechanically caught. That path is D-class: the
dispatch skill's re-entry rule and the closing line of every
synthesis are its only enforcement.

This is recorded, not solved. A future mechanism would need a
conversation-level hook that does not exist today; claiming this seam
is closed would itself be the fluency trap this system was built
against.
