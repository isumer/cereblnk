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

## 4. Path anchoring
Every `.claude/cereblnk/...` write resolves against the PROJECT ROOT —
never `$HOME` as a project, never a mid-run `cd` location, never temp
(context-policy R-5 for artifacts; cbenv resolution for shell).
Resolve the root once at run start; subagents inherit the absolute
path in their Task Blocks.

## 5. Run flag lifecycle (RunGuardHook, DelegationGuardHook)
Arm `$CB_DIR/flags/run-active` at execution start; remove it before
ANY turn that ends awaiting the user, and at final synthesis. While
armed, a premature stop gets exactly one continue-nudge.

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
