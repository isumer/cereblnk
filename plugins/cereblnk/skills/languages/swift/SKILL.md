---
name: swift
description: How to reason about Swift — value semantics by default, optionals as a modelling decision, and concurrency the compiler now checks. Use for any .swift implementation or review. Constraints in rules/languages/swift/.
---

# Swift Skill

## 1. Identity
name: swift · domain: languages
complements: accessibility
escalate_to: performance-engineering (allocation and retain traffic)

## 2. Mission
Value or reference is a design decision, not a default. Choose it out
loud, because everything downstream inherits the choice.

## 3. Philosophy

**Reading requests.** "Fix this crash" is usually a force-unwrap or an
index, and both mean an absence the model never expressed. "Make it
concurrent" asks which actor owns the state, and what crosses an
isolation boundary.

**Where risk lives.** Force unwrapping and forced casts, which turn a
recoverable absence into a termination. Reference cycles in closures
that capture self. Main-thread work that should not be there. And
mutable state shared across concurrency domains.

**Verification here.** Read the actual optionality, not the annotation
that reads reassuringly. A concurrency claim is checked against the
compiler's isolation checking, not against reasoning about queues. A
retain-cycle claim is verified by watching the object deallocate.

**False-competence traps.** Force unwrap justified by "it cannot be
nil here". A class chosen where a struct fits, so identity becomes an
accidental feature. Weak captures added everywhere, including where
they cause a silent no-op. Async added around synchronous work.

**Instincts.** `let` until the compiler objects. Struct until identity
is required. Model absence rather than unwrapping it. Give mutable
state one owner and let the compiler check the boundary.

## 4. Decision Strategy — the paths

**A value may be absent**
→ Model the absence and handle it. Force unwrapping converts a
  recoverable case into a crash.

**A type is declared**
→ Struct unless identity or shared mutation is required. Choosing a
  class makes reference semantics part of the contract.

**A closure captures self**
→ Decide the capture explicitly. Strong creates a cycle; weak can make
  the body silently skip.

**State is shared across tasks**
→ Give it one owner and let isolation checking prove the boundary.
  Queue discipline reasoned about by hand is not evidence.

**Work happens on the main actor**
→ Ask whether it must. Anything slow there is a frozen interface, and
  the compiler will not tell you.

**A protocol is added**
→ Trace one conformance end to end. A protocol with associated types
  can be unusable exactly where you meant to use it.

**An error is thrown**
→ Type it where the version allows, and translate at the boundary. A
  generic error at the edge tells the caller nothing.

## 5. Inputs
Source with line refs. Package manifest and language mode. Compiler
and lint output, including concurrency diagnostics. Deallocation
evidence for lifecycle claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Concurrency claims are `known`
only against compiler isolation diagnostics. Lifecycle claims cite an
observed deallocation.

## 7. Quality Gates
- No force unwrap or forced cast outside a proven-safe path.
- Every shared mutable state has one named owner.
- Every closure capturing self states its capture semantics.

## 8. Failure Modes
- A crash where an absence should have been handled.
- An object never deallocated because a closure held it.
- A frozen interface from slow work on the main actor.
- A data race the code reasoned itself out of and the compiler caught.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/swift/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | a force unwrap or forced cast | crash on a real input |
| 2 | a class where a struct fits | identity as an accident |
| 3 | a closure capturing self strongly | retain cycle |
| 4 | shared mutable state with no owner | data race |
| 5 | slow work on the main actor | frozen interface |
| 6 | a protocol never conformed to in practice | unusable abstraction |
| 7 | a generic error at a boundary | caller cannot act |

## 9. Worked Example
Claim: "the view model releases when the screen closes." Evidence: a
closure passed to the network layer captures self strongly. Path
fires: a closure capturing self strongly. Verdict: refuted (Known:
capture site, file#L). Fix: capture weakly and guard, then confirm the
object deallocates.
