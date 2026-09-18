---
name: python
description: How to reason about Python — mutable defaults, duck typing meeting untrusted data, the GIL, hints the interpreter ignores. Use for any .py implementation or review. Constraints in rules/languages/python/.
---

# Python Skill

## 1. Identity
name: python · domain: languages
complements: junit-testing
escalate_to: performance-engineering (profiling beyond code style)

## 2. Mission
Hints are documentation the interpreter ignores. The type bug appears
at runtime, so the test must exercise the type.

## 3. Philosophy

**Reading requests.** "Make this faster" usually means stop doing the
wrong thing in a loop. The profiler decides, not intuition. "Add type
hints" hides two questions. Which invariants should the checker
enforce? Is anything at the boundary validated at runtime?

**Where risk lives.** Mutable default arguments. The seam where duck
typing meets untrusted data. The interpreter lock fooling you about
parallelism. Truthiness on real data. Environment drift across
versions and pinned packages.

**Verification here.** Run it and read it. A type claim is verified by
the checker on the actual code, not by an annotation that looks right.
A performance claim needs a profile on realistic data. A "handles bad
input" claim needs the bad input fed to it.

**False-competence traps.** Nested comprehensions that read clever and
hide a bug. Type hints treated as safety while parsed data flows in
unchecked. A bare except that passes. Threads used for computation,
where the lock makes it slower.

**Instincts.** Explicit over implicit. Never a mutable default.
Validate at the boundary, then trust inside. Profile before
optimizing. Pin the interpreter and the dependencies. Reach for the
standard library first.

## 4. Decision Strategy — the paths

**A default argument is a list, dict, or set**
→ Use a sentinel and build inside. The default is created once and
  shared across every call forever.

**Parsed or external data enters**
→ Validate at the boundary and produce a typed object. Annotations
  alone are Assumed, whatever the checker reports.

**A performance change is proposed**
→ Profile first, on realistic data. An optimization with no before
  measurement cannot be shown to have worked.

**Work is CPU-bound and parallelism is wanted**
→ Processes, not threads. The interpreter lock makes the threaded
  version slower while looking parallel.

**A value is checked for presence**
→ Compare against None explicitly. Zero, empty string, and empty list
  are data that a truthiness check silently discards.

**An exception is caught broadly**
→ Name the exceptions expected. A bare catch that passes converts a
  failure into corrupted state.

**A comprehension nests more than twice**
→ Rewrite it as a loop to verify, then decide which one ships.
  Cleverness that cannot be re-derived is not verified.

## 5. Inputs
Source chunks with line refs. Dependency and interpreter versions.
Type checker output. Profile output for performance claims. The
failing input when debugging.

## 6. Outputs
ACP Response Block only. Facts labeled. Type claims are `known` only
against checker output. Performance claims are `estimated` with the
profile and data size stated.

## 7. Quality Gates
- No mutable value stands as a default argument.
- Every external boundary has one runtime validation.
- Every performance verdict cites a profile on realistic data.

## 8. Failure Modes
- State accumulating in a default argument across calls.
- Well-annotated code trusting an unvalidated payload.
- A threaded rewrite slower than the original.
- A bare except turning a failure into silent corruption.

## Constraints

The constraint form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/python/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules --constraints --task "<the
task in one sentence>" <path>` for the files the task touches. Without
`--task` the architecture, governance and security rules attach to nothing,
because they declare a task signal and no file glob. It applies the glob and the stack gate and then
emits the constraints themselves — do not read the rule files, which costs
three times the tokens for the same constraints. `rules/common/` already
arrived at session start. Every block is headed by its source path and keeps
its section headings, so cite a violated constraint by file and section as
before. Examples, and the failure shapes outside security, are projected
away: read the source file when an example is genuinely needed. Selection
rules: agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | mutable literal as a default argument | shared across calls |
| 2 | parsed data used with only annotations | unvalidated boundary |
| 3 | threads used for computation | lock serializes the work |
| 4 | bare except with pass or log only | corruption hidden |
| 5 | truthiness check on numeric or string data | zero treated as absent |
| 6 | optimization with no before profile | unmeasurable claim |
| 7 | comprehension nested three deep | unverifiable logic |

## 9. Worked Example
Claim: "the cache starts empty on each call." Evidence: the parameter
defaults to an empty dict in the signature. Path fires: a mutable
default argument. Verdict: refuted (Known: signature, file#L). The
dict is created once at definition and shared by every caller. Fix:
default to None and build inside. A test calls twice and asserts
independence.
