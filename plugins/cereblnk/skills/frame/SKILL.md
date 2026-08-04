---
name: cb-frame
description: Intent framing at product scale — challenges the literal request, extracts falsifiable premises, proposes sized implementation paths, and writes a design brief for /cb-design
argument-hint: <product request, however vague>
---

# IntentFramingWorkflow (/cb-frame)

**Trigger intent:** "I want to build / add / change <something>" before
any code exists. This workflow runs BEFORE planning — its output is a
confirmed brief, not tasks.

## Method (the cognitive contract at product scale)

1. **Three-level reading.** Literal request · operational objective ·
   underlying constraint (risk, deadline, irreversibility). State all
   three back to the user in two sentences each.
2. **Challenge the framing.** The literal request may not be the best
route to the operational objective. Say so now, with the concrete
alternative (09 Procedure 1, traps: literalism as obedience).
3. **Extract falsifiable premises.** List every premise the request
rests on. Users abandon at a named step. The interface can serve this within a stated budget. Write each as a
short statement the user marks **confirmed**, **rejected**, or
**unknown**. Unknown premises become explicit
   `assumed` facts in the brief — never silently absorbed.
4. **Propose two or three sized paths.** Each carries four things.
Scope in one paragraph. A rough size. What it deliberately excludes.
Its dominant risk. No path is "everything".
5. **Write the brief.** After the user picks a path and rules on
   premises, write `.claude/cereblnk/memory/briefs/<slug>-<date>.md`.

## Brief format (consumed by /cb-design)

```
# Brief: <slug>
objective:            # operational, one paragraph
constraint:           # what actually matters
chosen_path:          # the selected option, with exclusions
premises:
  confirmed: [...]
  rejected:  [...]
  assumed:   [...]    # unknowns the user accepted as assumptions
success_criteria:     # observable, falsifiable
out_of_scope:         # explicit
risk: low|medium|high # per policies/risk-model.md
```

## Rules

- Single-agent workflow (orchestrator-level reasoning; no specialist
  mesh yet — that starts at /cb-design). Gate level 1: five-question
  self-test before the brief is written.
- No implementation, architecture, or schema in the brief. Premature
  design here narrows /cb-design dishonestly.
- Output follows the fixed order. DECISION is the recommended path.
  EVIDENCE is the premise rulings. Then REASONING, then RISK, where
  assumed premises are risks by definition) → CONFIDENCE.

## Turn hand-off

This workflow has a deliberate stop: it ends its turn waiting on the
user. That wait is never silent. The reply's final line states it:
"Awaiting: confirm or reject each premise. Confirmed premises freeze into the brief. Rejected ones re-frame it."
If this workflow was started as a background task, also tell the user that its
completion will not auto-continue the conversation and any message
resumes it. The brief is written to its `.claude/cereblnk/` destination before
the turn ends. Never parked in a temp path (context-policy R-5) — so even an interrupted hand-off loses nothing.

