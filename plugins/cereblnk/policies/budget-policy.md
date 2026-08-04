# Context Budget Policy

Governs context budgeting, under the context-isolation rule (context is not shared) and
the cost hierarchy (cost hierarchy).
Class: Discipline — budgets are declared in Task Blocks and self-reported
in Response Blocks; the platform does not enforce them. Every rule names
its checker.

## Global target

Total operational context stays below **50% of the available model
context window**. The remainder is reserve: verification headroom,
escalation, safety margin.

## Default per-role budgets (as fractions of the computed capacity)

| Role | Default budget |
|---|---|
| PlannerAgent | 4K |
| ArchitectAgent | 8K |
| BackendAgent | 8K |
| SecurityAgent | 6K |
| QAAgent | 6K |
| PerformanceAgent | 6K |
| DocsAgent | 4K |
| VerifierAgent | 4K |
| ChallengerAgent | 4K |
| SynthesizerAgent | 6K |

Individual agent working sets target **5–10K tokens** regardless of
repository size. The orchestrator may reallocate reserve to escalated
high-risk tasks.

## Rules and checkers

1. Every Task Block declares `budget_tokens`; every Response Block
   returns a `budget_report`.
   (Checker: orchestrator rejects blocks missing either field.)
2. Exceeding budget without declaring `status: blocked` is a protocol
   violation.
   (Checker: orchestrator compares `tokens_used` to `tokens_received`
   on every block; violating blocks are discarded and re-issued.)
3. No agent reads the full repository or the full conversation.
   Agents receive only the `context_refs` listed in their Task Block.
   (Checker: ConsistencyAgent flags Response Blocks citing evidence
   outside the task's declared `context_refs`.)

## Rule 4 — the orchestrator's own context is a budget too

Per-agent budgets are pointless if the orchestrating conversation
itself overflows. The failure mode is mechanical: each returned
Response Block, tool result, and re-quoted file accumulates in the
main context until input + reserved output exceeds the model window
and the run dies mid-flight. Observed twice, at two different window
sizes — which is the point: the window is not a constant, so no
number here may be one. Run
`${CLAUDE_PLUGIN_ROOT}/scripts/context-budget` at run start and state
what it returns.

- Subagents return **digests** (≤10 lines); full Response Blocks are
  written to `$CB_DIR/context/<run_id>/` (file-mediated ACP — the
  Tree of Context, 03 §3, applied to the orchestrator itself: only
  summaries travel upward).
- Gate agents receive block file PATHS, never inline block bodies.
- The orchestrator never re-quotes a full block or raw file content
  into its own conversation.
- **Checker:** DigestCapHook (SubagentStop) reads the subagent's own
  transcript, counts the lines of the message it returned, and blocks
  the stop when the count exceeds `digest_lines_max` — the cap is a
  mechanism, not a request. The run summary
  (run-summary.template.yaml) records `ledger_blocks_written` vs tasks
  executed; a run whose task count exceeds its ledger count violated
  this rule. SynthesizerAgent refuses a synthesis Task Block that
  inlines full Response Blocks when a ledger directory exists.


## The budget is computed, never assumed

The model window changes. A figure written here while it was one size
is wrong the day it becomes another, and the failure surfaces as a
context-length error partway through a run rather than as a bad
number in a document.

At run start the orchestrator runs:

```
${CLAUDE_PLUGIN_ROOT}/scripts/context-budget --agents <planned>
```

and states the result in the run ledger. The script derives every figure from variables Claude Code already
defines, in its own precedence order — command line, then the
settings-file `env` block, then the shell:

| Variable | Carries |
|---|---|
| `CLAUDE_CODE_AUTO_COMPACT_WINDOW` | the context capacity in tokens |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | the output reservation |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | the compaction trigger percent |

An unset window or reservation is reported as `assumed`, naming the
variable to set, so a default is never mistaken for a measurement.
Set them once in the project's `.claude/settings.json` and every run
computes from a fact rather than a guess.

What it returns and what each figure binds:

| Figure | Binds |
|---|---|
| `input_capacity` | window minus the output reservation |
| `checkpoint_at` | compact here and resume from the ledger, before the ceiling |
| `wave_size` | agents that may run in one wave at this capacity |
| `digest_lines_max` | the per-return cap of §1 |

**Checker:** VerifierAgent rejects a run whose ledger states no
computed budget, and any policy or command that states an absolute
token figure as the capacity rather than deriving it.
