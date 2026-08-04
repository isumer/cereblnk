---
name: cb-requirements
description: Turn a vague request into numbered, testable requirements — measurable acceptance criteria, surfaced assumptions, explicit out-of-scope — written to a requirement doc
argument-hint: <what you want, however roughly stated>
---

# RequirementsWorkflow (/cb-requirements)

**Trigger intent:** pin down what we actually need. Before design, or when a downstream task cannot answer what done
means here. Distinct from `/cb-frame`, which chooses a path): this specifies what
"done" means, testably, for the thing being built.

## Method

1. **Three-level read** (09 Procedure 1): literal request · operational
   need · the constraint that matters. State them back briefly.
2. **Decompress with the user, not for them.** Invoke
   `requirements-agent` with an ACP Task Block. It produces numbered requirements. Each carries actor, trigger,
behavior, measurable acceptance, and out-of-scope. Every hidden
premise surfaces as an `assumed`
   fact. Present the premises for rulings — do not invent answers.
3. **Enforce testability**, per the
`skills/practices/requirements-engineering` quality gates. Every
acceptance criterion is expressible as a check that could become a Verify line in a plan (CB-051). Adjective
   acceptance ("fast", "robust") is sent back for a number or a
   concrete condition.
4. **Strip solution leakage.** A mechanism stated as a requirement is
rewritten as the observable behavior. The mechanism becomes a design
note for `/cb-design`.
5. **Write the doc** to `.claude/cereblnk/memory/requirements/<slug>-<date>.md`
   — numbered requirements, rulings recorded, out-of-scope explicit,
   open unknowns listed.

## Gate

Level 2 by default. Verifier confirms each acceptance criterion is a
real, checkable condition. Consistency checks that no two
requirements contradict). The doc has a downstream job. `/cb-design` consumes it as what must
be true. `/cb-frame` may precede it: path first, then requirements
for the chosen path).

## Output

DECISION states whether the requirement set is ready, or blocked on
rulings. EVIDENCE is the numbered requirements with acceptance. Then REASONING, covering how intent decomposed. Then RISK: unruled
premises, open unknowns, scope boundaries. Then CONFIDENCE, plus the
doc path.
