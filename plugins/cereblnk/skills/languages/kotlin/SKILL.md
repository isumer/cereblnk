---
name: kotlin
description: How to reason about Kotlin — platform types at the Java boundary, coroutine scope and cancellation, null safety that stops at interop. Use for any .kt implementation or review. Constraints in rules/languages/kotlin/.
---

# Kotlin Skill

## 1. Identity
name: kotlin · domain: languages
complements: java · junit-testing
escalate_to: spring-boot (framework wiring)

## 2. Mission
Null safety ends where Java begins. Structured concurrency ends where
the scope is unowned.

## 3. Philosophy

**Reading requests.** "Make this suspend" hides three questions. Which
dispatcher? Whose scope? Cancelled by what? A coroutine without a
structured scope is a leak. "It is null-safe, it is Kotlin" ignores the
interop boundary, where platform types bypass the checker entirely.

**Where risk lives.** Platform types arriving from Java with unknown
nullability. Scopes not tied to a lifecycle. Blocking calls on the
main dispatcher. Cancellation exceptions caught and swallowed with
everything else.

**Verification here.** For a null-safety claim, trace the value to its
origin. Crossing from Java makes it a platform type, and the safety is
Assumed until a check exists. For a coroutine claim, name the scope,
dispatcher, and cancellation path. Cancel the parent and confirm
children stop.

**False-competence traps.** The not-null assertion used to fix an
error, relocating the failure. A global scope launch, detached from
any lifecycle. Blocking inside the dispatcher the coroutines were
meant to free. A broad catch swallowing cancellation.

**Instincts.** Answer nullability, never silence it. Bind scopes to
lifecycles and pick the dispatcher deliberately. Validate platform
types at the boundary. Use sealed hierarchies to make illegal states
unrepresentable. Immutable by default.

## 4. Decision Strategy — the paths

**A value crosses from Java**
→ Treat nullability as unknown. Check at the boundary, then trust
  inside. The compiler cannot warn about what it cannot see.

**A not-null assertion appears**
→ It is a claim. Justify it against the origin, or replace it with a
  check. Silencing the checker relocates the failure.

**A coroutine is launched**
→ Name the scope and its lifecycle owner. A scope with no owner
  outlives the work it was started for.

**A dispatcher is chosen**
→ Blocking work goes to the IO dispatcher, computation to the default
  one. Blocking the main dispatcher freezes what coroutines freed.

**An exception is caught inside a coroutine**
→ Re-throw cancellation. Catching it with everything else breaks
  structured concurrency silently.

**A state has a fixed set of shapes**
→ A sealed hierarchy, not a flag plus nullable fields. Exhaustive
  matching then becomes the compiler's job.

**A data class carries mutable fields**
→ Ask who mutates it. Copy semantics and shared mutation together
  produce surprises far from the assignment.

## 5. Inputs
Source chunks with line refs. The Java interop surface. Scope and
dispatcher declarations. Cancellation paths. Build file for versions.

## 6. Outputs
ACP Response Block only. Facts labeled. Null-safety claims across
interop are `assumed` until a boundary check is cited. Coroutine
claims name scope, dispatcher, and cancellation.

## 7. Quality Gates
- Every value from Java is checked at the boundary or labeled Assumed.
- Every coroutine scope has a named lifecycle owner.
- Every catch inside a coroutine re-throws cancellation.

## 8. Failure Modes
- A null failure at a boundary the compiler declared safe.
- Work continuing after its owner was destroyed.
- A frozen main thread inside a coroutine-based path.
- Cancellation swallowed, leaving children running.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/kotlin/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | Java-origin value used without a check | platform type gap |
| 2 | not-null assertion near a former error | silenced, not answered |
| 3 | launch on a global or unowned scope | lifecycle detached |
| 4 | blocking call on the main dispatcher | frozen thread |
| 5 | broad catch inside a coroutine | cancellation swallowed |
| 6 | flag plus nullable fields for one state | illegal shape reachable |
| 7 | shared data class with mutable fields | surprise at a distance |

## 9. Worked Example
Claim: "the name cannot be null, the type says so." Evidence: the
value is returned by a Java client with no annotation. Path fires: a
value crossing from Java. Verdict: weakened (Known: call site; Assumed:
nullability). Fix: check at the boundary and model absence explicitly.
A test feeds a null from the Java side and expects a handled result.
