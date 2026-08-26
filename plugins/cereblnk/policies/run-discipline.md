# Run Discipline Policy

Binding on EVERY workflow run — dispatch-routed or slash-invoked,
whichever command is the entry point. These rules previously lived
only in `/cb-orchestrate`; dispatch routes directly to specific
workflows, so runs entered through them executed without the rules
that exist to keep runs alive. This policy is the authoritative
extraction; on any wording divergence, this file wins.

## 1. File-mediated ACP (context ledger)
Every subagent writes its full Response Block to
`$CB_DIR/context/<run_id>/<task_id>.yaml` and returns ONLY a digest of
at most ten lines (task_id, role, status, one-sentence decision, fact
counts per label, unknown/risk counts, confidence, block path). Gate
agents receive block file PATHS and read them in their own context.
The conducting conversation never re-quotes a full block.
**Checker:** DigestCapHook (SubagentStop) measures the return against
the computed `digest_lines_max` and blocks an oversized one on exit 2;
run summary `ledger_blocks_written` vs task count; SynthesizerAgent
refuses inline full blocks when a ledger exists.

## 1b. Revising a block: append, never rewrite

A Response Block is written once. When a gate finds a contradiction and
the owning role is re-issued, it APPENDS a `revisions:` entry and leaves
the text above untouched. The base block is its own history.

Rewriting was the default because it was the only thing anyone had
named, and it cost three things. Twelve roles deny the Edit tool — they
decide and record, they never modify existing source — and Edit is
denied per role, not per path, so changing two fields in a block meant
re-emitting the whole file with Write. Measured: a qa-agent spent 3900
tokens against a 2500 budget to change two fields in a 230-line block,
and a verifier pass ran ~9800 against 3500. In both cases the reasoning
was cheap and the re-emission was the entire overrun.

The tokens were the least of it. A role that is structurally over budget
declares `over_budget: true` on every revision, so the flag stops
carrying information. It prices self-correction above being wrong, which
inverts the incentive the gates exist to create. And re-emission
REPLACED the block, so each rewrite destroyed the previous
`budget_report` — a run summary could only report each block's last
pass, meaning the cost of revising was erased by revising.

Appending needs no new permission. ToolFloorHook blocks in-place
rewrites (`sed -i`, `patch`, `ed`) and deliberately does not block
redirection, so `cat >> <block>.yaml <<'EOF'` was available the whole
time. What was missing was anything telling an agent to use it.

Each appended revision carries `revision:`, `reason:`, its own
`budget_report:`, and the `supersedes:` entries naming what it replaces.
`scripts/acp-lint` T-4 refuses one that is unattributable or unpriced.

**Reader rule.** Current state is the base block with each revision's
`supersedes` applied in order, newest last. A reader that takes the base
alone is reading the first draft; a reader that takes only the last
revision is reading a patch without its subject. Gate agents read both.

## 1c. The skill floor has one copy

`scripts/select-agents --emit-floor` writes
`$CB_DIR/context/<run_id>/skills-required.yaml`. That file is the only
place the floor exists. A Task Block names the file and the role key; it
never restates the list.

The list used to be hand-copied to two places — the file the
SubagentStop floor reads, and the Task Block text the subagent reads.
Two copies of one truth, written by the same conductor at different
moments, and nothing kept them in sync. Both failure modes were
measured: a run where the file was never written left the floor silently
inert for four consecutive runs, and a run where the two disagreed
blocked a specialist for not loading a skill its own Task Block never
named.

`--emit-floor` writes only to a run pinned by id. Without one it says so
and writes nothing: `cb_run_dir` falls back to a newest-directory guess,
and a guessed destination for the judge's own input is how a ledger
splits.

## 2. The conducting conversation is a budget
It holds: intent, plan, digests, verdicts, synthesis — nothing else.
Raw file contents belong in subagent contexts. Any slice/task that
must read even one repository file runs in a spawned agent, including
on the fast path; implementation work (edits, builds, test shells)
runs inside the building specialist's subagent, never in the
conductor. A context-length failure mid-run is a violation of this
rule, not bad luck.

## 3. Synchronous execution
Never background a gate-bearing stage: a backgrounded agent's
completion does not wake the conversation; its result waits for the
user's next message and the run stalls. Foreground, always.

## 3b. What "independent" means in a wave

A wave runs independent tasks in parallel up to `wave_size`. Two tasks
are independent when neither reads a file the other writes — and that is
wider than the plan graph's `depends_on`, because the plan graph is
written before the run and the collisions that matter appear during it.

The case that has bitten: a gate task and an edit to that gate's target
are NOT independent. Measured — a verifier re-issued to correct one
claim, and the owner of the block it gates re-issued to fix another,
were dispatched in the same wave. The target's new revision landed 112
seconds before the gate's final write, so the gate read one text and
reported on another, and stated in good faith that it had read the
current one. Its currency claim was false, and nothing in the block
could show that: a version pin proves which text was read, never that
the text held still between the read and the write.

Two rules follow, and they are the conductor's to apply — no hook can
see a collision that lives in two subagents at once:

- **Never wave a gate with an edit to its target.** Sequence them: the
  edit lands, then the gate reads. A gate re-issued to correct itself is
  still a gate.
- **§3 re-verification rounds are outside the plan graph.** They are
  created after planning, so they carry no `depends_on` and inherit
  none. Their dependencies have to be read off the targets named in
  their Task Blocks, every time.

A gate may also protect itself: re-check the target revisions
immediately before its final write, and say so if they moved.

## 4. Path anchoring
Every `.claude/cereblnk/...` write resolves against the PROJECT ROOT —
never `$HOME` as a project, never a mid-run `cd` location, never temp
(context-policy R-5 for artifacts; cbenv resolution for shell).
Resolve the root once at run start; subagents inherit the absolute
path in their Task Blocks.

## 5. Run flag lifecycle (RunGuardHook, DelegationGuardHook)
Arm with `scripts/run-flag arm "" <run_id>` at execution start; disarm
with `scripts/run-flag disarm` before ANY turn that ends awaiting the
user; and at final synthesis use `scripts/run-flag complete`, which
performs the handoff described below. The two verbs are not synonyms —
`disarm` is a pause the run may return from, `complete` ends it. While armed, a premature stop gets exactly
one continue-nudge.

The flag also carries the run's identity, and that is not bookkeeping.
Eight hooks — the four floors, both ledgers, DigestCap and RunGuard —
need to know which run directory to read or write. They used to infer
it: newest directory under `context/` by mtime, recomputed on every
invocation. An agent that edits source and only afterwards writes its
Response Block creates a newer directory than the one holding its own
edit records, so the floor read an empty directory and let an unrun
change through (F-31). Writers and readers guessed separately, so the
whole record layer could split. `cb_run_dir()` in `lib/cbenv.sh` is now
the single resolver: it reads this flag, rejects anything that is not a
bare run id, requires the directory to still exist, and falls back to
the old scan otherwise. Arming without an id leaves every hook guessing.

The flag is `$CB_DIR/flags/run-active`; the script exists because
writing it by hand went wrong in a way nothing could see. A raw
`mkdir`/`touch` pair carries no environment, so an unresolved `$CB_DIR`
aimed at `/flags` and failed on permissions. DelegationGuard and
RunGuard read this file and treat its absence as "no run", so the arm
failing did not weaken the boundary — it removed it, and the session
went on to run a full workflow inline with no Task Blocks on disk.
`run-flag` resolves `$CB_DIR` through cbenv and stats the file
afterwards: a non-zero exit means the run is NOT guarded. A run that
cannot arm does not proceed as though it did.

At final synthesis the flag is not merely removed — it is HANDED OFF:
write `$CB_DIR/flags/run-completed`, which keeps DelegationGuard armed
through the follow-up window (input-policy §4). The window is
TTL-bounded (default 8h, `CB_COMPLETED_TTL_HOURS`) so a forgotten flag
degrades to fail-open rather than blocking a project indefinitely.
A new run arming `run-active` supersedes it.

## 6. Context-error recovery
On a context-length error: no blind retry. `/compact`, then resume
from the run ledger (`plan.md` + completed blocks), re-issuing only
tasks without a confirmed verdict.

## 7. Tool-output gate (CB-085)
Build, test, and any long-talking shell runs through
`scripts/run-quiet <task_id> <command…>`. Full output lands in
`$CB_DIR/context/<run_id>/logs/`; the agent's window receives only the
bounded digest. Needing more than the digest means grep the log —
never cat it, never re-run the command unwrapped. An inline tool dump
in any agent window is the same violation class as reading an
undeclared file.
**Checker:** VerifierAgent rejects a Response Block whose evidence
quotes raw tool output beyond digest size instead of citing a log
path; staged review STAGE 1 does the same for executor transcripts.

## 8. Declared-files boundary (CB-085)
An executor's context is its Task Block plus its declared files —
nothing else. Needing an undeclared file is not a license to read it:
return `blocked` naming the file; the planner amends the plan. This
turns silent context growth into a visible plan defect.
**Checker:** VerifierAgent compares the files cited in a block's
evidence refs and artifacts against the Task Block's declaration; an
undeclared read in a `completed` block is a protocol violation
(discard + re-issue, per ACP §7).

## 9. In-attempt tool ceiling (CB-085)
The stop-rule bounds attempts; this bounds the loop inside one. An
executor spends at most 15 tool calls per attempt. Reaching the
ceiling returns `blocked` with the count and the last digest — never
a 16th call, never a silent overrun. The digest's header makes the
count cheap to keep.
**Checker:** each executor digest line carries `calls=N`; a
`completed` block reporting more than 15 is treated as a budget
overrun without `blocked` status (ACP §7 hard failure #5) — discarded
and re-issued.
