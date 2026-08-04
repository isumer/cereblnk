---
name: cb-docs
description: Diff-driven documentation sync — finds every doc statement the diff made stale; safe updates applied, risky rewrites surfaced as questions
argument-hint: [branch or diff range; defaults to current branch vs main]
---

# DocumentationWorkflow (/cb-docs)

**Trigger intent:** bring the docs in line with this change.

## Agent topology

```
Orchestrator → docs-agent (leads: drift detection, diff-scoped)
            → technicalwriter-agent (only when a drifted section needs
              restructuring beyond line fixes)
            → verifier-agent (level 2: spot re-derivation that flagged
              drifts are real and applied fixes match the code)
            → synthesizer-agent
```

Budgets: Docs 4K · TechnicalWriter 5K (when engaged) · Verifier 4K ·
Synthesis 6K. Risk: low by default; docs describing security or
migration behavior escalate to the underlying topic's level.

## Method

1. **Diff first.** Extract what changed: paths, names, structures,
   counts, behaviors, examples.
2. **Cross-reference every doc file** against those changes. README,
docs/, inline doc comments in changed modules, and CONTRIBUTING where
process changed. Each hit = fact pair (doc line ↔ code line).
3. **Classify per hit.**
- **Mechanical drift.** A renamed path, a changed count, a moved
  file, a dead link. The fix is applied directly, one entry per fix in the
     evidence list.
   - **Risky rewrite.** Behavioral descriptions, semantics, and examples
  that encode intent. Surfaced as a question with the proposed text.
  Never silently applied (traps: the caveat you rewrite
     away is the one that mattered).
4. Doc statements about UNCHANGED behavior are out of scope — mention, don't touch.

## Output

DECISION states sync status, fixes applied, and questions pending.
EVIDENCE carries the doc-to-code pairs. Then REASONING, then RISK,
which covers pending questions and undocumented new behavior) → CONFIDENCE.
