---
name: dart
description: How to reason about Dart — null safety the compiler enforces, futures that outlive their caller, and generated code that must not be edited. Use for any .dart implementation or review. Constraints in rules/languages/dart/.
---

# Dart Skill

## 1. Identity
name: dart · domain: languages
complements: typescript
escalate_to: performance-engineering (rebuild and allocation cost)

## 2. Mission
Model absence in the type and cancellation in the lifetime. The
compiler covers the first; nothing covers the second for you.

## 3. Philosophy

**Reading requests.** "Fix this null error" under sound null safety is
usually an assertion operator somebody reached for. "Make it async" is
not local: a future outliving the object that awaited it produces
updates against something already disposed.

**Where risk lives.** The assertion operator, which turns a modelling
gap into a runtime failure. Futures with no cancellation, completing
after their owner is gone. Generated files edited by hand, so the next
build erases the fix. And a sealed hierarchy with a default branch,
which removes the exhaustiveness that made it worth declaring.

**Verification here.** Read the declared nullability and the analyser's
output, not the annotation you expected. An async claim is verified by
following what awaits and what disposes. A generated-code claim is
verified against the generator's input, since the output is a build
artefact.

**False-competence traps.** Assertion operators spread to satisfy the
analyser. A `late` field used where absence was legal. A default branch
on a sealed type. Generated code corrected in place rather than in its
source.

**Instincts.** Absence in the type, not asserted away. Immutable value
types with generated equality where the project already generates. A
disposal path for every subscription and controller. Exhaustive
matching with no default.

## 4. Decision Strategy — the paths

**A nullable value is used**
→ Narrow it, or model the absence. The assertion operator converts a
  design question into a crash.

**A `late` field is declared**
→ Ask whether absence is legal. If it is, the field is nullable, not
  late.

**A future is awaited**
→ Ask what happens if the owner is gone when it completes. A guard or
  a cancellation is part of the call, not an afterthought.

**A subscription or controller is created**
→ Give it a disposal path in the same place. Leaks here are silent
  until memory shows them.

**A closed set of states exists**
→ Declare a sealed hierarchy and match exhaustively. A default branch
  discards what the declaration bought.

**Generated code is wrong**
→ Fix the source and regenerate. An edit to the output survives until
  the next build.

**A value type is written**
→ Make it immutable and compare by content. Identity equality on a
  value surprises every collection it enters.

## 5. Inputs
Source with line refs. Analyser output and its configured strictness.
Generator inputs for any generated file. Disposal paths for
subscriptions and controllers. Package manifest and lock file.

## 6. Outputs
ACP Response Block only. Facts labeled. A nullability claim is `known`
only against analyser output. Generated-file claims cite the source,
never the artefact.

## 7. Quality Gates
- Every assertion operator states why the value cannot be null.
- Every subscription and controller has a disposal path.
- Every sealed match is exhaustive, with no default branch.

## 8. Failure Modes
- An assertion operator crashing on the input nobody modelled.
- A future completing against a disposed owner.
- A hand-edited generated file reverting on the next build.
- A new variant silently absorbed by a default branch.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/dart/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | an assertion operator on a nullable value | modelling gap as a crash |
| 2 | a `late` field where absence is legal | wrong tool for optionality |
| 3 | an awaited future with no owner guard | update after disposal |
| 4 | a subscription with no disposal | silent leak |
| 5 | a default branch on a sealed type | exhaustiveness discarded |
| 6 | an edit inside a generated file | reverts on next build |
| 7 | a value type with identity equality | surprises every collection |

## 9. Worked Example
Claim: "the field is always set by then." Evidence: a `late` field is
read in a callback that can fire before initialisation. Path fires: a
`late` field where absence is legal. Verdict: refuted (Known:
declaration and callback, file#L). Fix: make it nullable and handle the
absent case, then check the analyser.
