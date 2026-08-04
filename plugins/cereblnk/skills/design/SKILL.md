---
name: cb-design
description: Turns a confirmed brief into an executable spec — architecture, data flow, state transitions, failure modes, trust boundaries, diagrams, and a test matrix
argument-hint: <brief slug or path under .claude/cereblnk/memory/briefs/>
---

# FeatureDesignWorkflow (/cb-design)

**Trigger intent:** design the feature we framed. Requires a brief
from /cb-frame in `.claude/cereblnk/memory/briefs/`. If none exists, stop and route the user to /cb-frame first.
Designing from a raw request skips the premise rulings this workflow
depends on.

## Agent topology

```
Orchestrator
  → architect-agent      (structure, boundaries — leads the spec)
  → SURFACE SPECIALISTS  (mandatory per agent-selection-policy §1+§3b:
        frontend-agent for any UI surface · backend-agent for
        server-side behavior · infra-agent for deployment/runtime
        topology · performance-agent advisory when hot paths or scale
        are in the brief — each authors its surface's spec sections
        with its skill closure loaded; the architect integrates,
        never substitutes)
  → apidesign-agent      (contracts, if any interface is touched)
  → database-agent       (schema/migration sections, if data is touched)
  → security-agent       (trust boundaries + failure modes review — mandatory)
  → qa-agent             (test matrix)
  → gates per risk level → synthesizer-agent
allowed feedback loop: architect ↔ security (one round) when trust
boundaries move; architect ↔ database (one round) when the model forces
a structural change.
```

Per-stage budgets: Architect 8K · APIDesign 6K · Database 6K ·
Security 6K · QA 6K · gates per policy · Synthesis 6K.

## The spec must contain (all seven, in order)

1. **Architecture** — components, boundaries, dependency direction.
2. **Data flow** — where data enters, transforms, persists, exits.
3. **State transitions** — states, events, illegal transitions.
4. **Failure modes** — what breaks, blast radius, degradation behavior.
5. **Trust boundaries** — who is trusted with what, where validation
   lives (security-agent signs this section).
6. **Diagrams** — MANDATORY, at least one (component or sequence, in
   Mermaid or ASCII). Diagrams force hidden assumptions into the open;
   a spec whose diagram was "not needed" has hidden assumptions.
7. **Test matrix** — behavior × state rows with the concrete check per
   cell, decomposable by planner-agent into ACP acceptance criteria.

Sections are authored by their owners into
`$CB_DIR/context/<run_id>/spec-sections/<section>.md` — each in its
own window, returning only a digest. The head at
`.claude/cereblnk/memory/specs/<slug>.md` is produced by
`scripts/spec-assemble` (invoked by architect-agent) — assembly is a
script, never a window (memory-policy R-1). Every
section carries epistemic labels; premises inherited from the brief
keep their confirmed/assumed status.

## Gate policy

Risk comes from the brief. High-risk features run at level 3. The
Challenger then attacks the design: the awkward consumer, the
concurrent writer, the partial
failure). The spec's acceptance: planner-agent can slice it into tasks
whose acceptance criteria come straight from the test matrix.

## Output

DECISION is the design in one paragraph. Then EVIDENCE, REASONING,
and RISK, which carries assumed premises and surviving
counter-scenarios. Then CONFIDENCE, plus the spec file path.

## Turn hand-off

This workflow has a deliberate stop: it ends its turn waiting on the
user. That wait is never silent. The reply's final line states it:
"Awaiting: approve the spec, or name the section to revise. On approval, /cb-implement consumes it directly."
A named revision is a RECONSTRUCTION, not a chat reply. The affected
sections' owners
rewrite in their own windows, `spec-assemble` produces the new head
(version bumped, old head archived), and the loss gate applies
(memory-policy R-1/R-2). If this workflow was started as a background task, tell the user one
more thing. Its completion will not auto-continue the conversation
and any message
resumes it. The spec is written to its `.claude/cereblnk/` destination before the
turn ends. Never parked in a temp path (context-policy R-5) — so even an interrupted hand-off loses nothing.

## Execution discipline

`policies/run-discipline.md` binds this run in full — ledger +
digests, conductor-context budget, synchronous stages, path
anchoring, flag lifecycle, context-error recovery.

## Run flag (RunGuardHook wiring)

Arm at execution start:
`mkdir -p "$CB_DIR/flags" && touch "$CB_DIR/flags/run-active"`.
Here `$CB_DIR` is `<project root>/.claude/cereblnk`.
Remove it before ANY turn that ends awaiting the user.
Remove it at final synthesis.
Full lifecycle semantics live in `policies/run-discipline.md` §5.
That is the authoritative copy. This section does not restate it.
