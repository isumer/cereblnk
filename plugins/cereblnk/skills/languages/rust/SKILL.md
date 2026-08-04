---
name: rust
description: How to reason about Rust — ownership as design, error paths as types, and the unsafe boundary where the compiler stops helping. Use for any .rs implementation or review. Constraints in rules/languages/rust/.
---

# Rust Skill

## 1. Identity
name: rust · domain: languages
complements: performance-engineering
escalate_to: performance-engineering (allocation and layout work)

## 2. Mission
The compiler proves memory safety. It proves nothing about your
lifetimes being the right ones.

## 3. Philosophy

**Reading requests.** "Fix this borrow error" is rarely about the
borrow. It is about ownership the design never decided. Who owns this
value, and for how long? "Make it faster" often means fewer clones —
but a clone is cheap next to a wrong lifetime that forces a rewrite.

**Where risk lives.** The `unsafe` block, where every guarantee
becomes yours. Panics on a path that must not unwind. Blocking calls
inside async code, which stall an executor. And integer arithmetic in
release builds, where overflow wraps silently.

**Verification here.** Read the actual lifetime, not the elided one.
A soundness claim about `unsafe` is verified by naming the invariant
upheld and what would break it. Concurrency claims are checked against
the trait bounds the compiler required, not against intuition.

**False-competence traps.** Cloning to silence the borrow checker.
`unwrap` in library code. Lifetime parameters spread across a
signature nobody can read. `unsafe` justified by a comment rather than
an invariant.

**Instincts.** Borrow by default, own deliberately. Model failure in
the return type. Keep `unsafe` in a small audited module with its
invariant written down. Let the type system carry what a comment
would.

## 4. Decision Strategy — the paths

**A borrow error appears**
→ Ask who owns the value and for how long. Cloning answers the
  compiler, not the design.

**A function can fail**
→ Return a result carrying a typed error. A panic is for a broken
  invariant, never for expected failure.

**`unwrap` or `expect` is written**
→ Justify it. In a library it is a bug waiting; in a test or a
  provably-safe path, state which.

**`unsafe` is used**
→ Name the invariant it upholds and what would violate it. Keep it in
  the smallest module and audit its boundary.

**Async code calls something blocking**
→ Move it off the executor. A blocking call starves every task the
  runtime was scheduling.

**Arithmetic can overflow**
→ Choose the behavior explicitly: checked, saturating, or wrapping.
  Debug panics and release wraps is a difference that ships.

**A trait bound is added**
→ Trace one concrete instantiation. Bounds that satisfy the compiler
  can still make the type unusable for real callers.

## 5. Inputs
Source with line refs. Cargo manifest and edition. Compiler and clippy
output. Any `unsafe` block with its stated invariant. Async runtime
configuration for scheduling claims.

## 6. Outputs
ACP Response Block only. Facts labeled. A soundness claim is `known`
only with the invariant named and traced. Performance claims cite a
measurement, never a clone count.

## 7. Quality Gates
- Every `unsafe` block states the invariant it upholds.
- Every fallible path returns a typed error rather than panicking.
- Every concurrency claim rests on a trait bound, not on reading.

## 8. Failure Modes
- Clones added until the borrow checker relents, hiding the design.
- A library panic taking down its caller's process.
- An executor starved by a blocking call inside a task.
- Release arithmetic wrapping where debug had panicked.


## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/rust/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | a clone added near a borrow error | ownership undecided |
| 2 | `unwrap` in library code | panic on a caller's thread |
| 3 | `unsafe` with a comment, no invariant | unaudited soundness |
| 4 | a blocking call inside async | executor starved |
| 5 | arithmetic with no overflow decision | debug and release differ |
| 6 | lifetimes spread across a signature | design pushed into types |
| 7 | a trait bound never instantiated | unusable for real callers |

## 9. Worked Example
Claim: "the parser is safe, it never panics." Evidence: the slice
index is computed from a length read earlier, and `unwrap` follows.
Path fires: `unwrap` in library code. Verdict: refuted (Known: parse
function, file#L). A truncated input panics in the caller's thread.
Fix: return a typed error and let the caller decide.
