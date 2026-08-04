---
name: cpp
description: How to reason about C++ — lifetime as the central question, undefined behavior as a real outcome, and a build that decides more than the source shows. Use for any .cpp or .hpp work. Constraints in rules/languages/cpp/.
---

# C++ Skill

## 1. Identity
name: cpp · domain: languages
complements: performance-engineering
escalate_to: performance-engineering (layout, cache, allocation work)

## 2. Mission
Ask who owns this and how long it lives. Every other question in this
language follows from that one.

## 3. Philosophy

**Reading requests.** "Fix this crash" is a lifetime question before it
is a logic question: what outlived what? "Make it faster" is a
measurement question, because the intuition that a construct is slow is
usually about a construct the optimiser already removed.

**Where risk lives.** Undefined behavior, which is not a crash but a
licence for the compiler to assume it cannot happen. Dangling
references from a temporary. Manual resource management on a throwing
path. Data races, where the standard offers no defined outcome at all.

**Verification here.** Read the actual lifetime of the referent, not
the intent. Build with the sanitisers and run the case; undefined
behavior is found by tooling, never by reading. A performance claim is
verified by a measurement on the same build flags that ship.

**False-competence traps.** Raw `new` and `delete` in modern code. A
reference returned to a local. `shared_ptr` used where ownership was
never actually shared. A benchmark built without optimisation, or with
the measured work optimised away.

**Instincts.** Resources owned by objects, released by scope. `unique_ptr`
first; shared ownership only when it is real. Pass by reference to
const, move when transferring. Run the sanitisers in CI, not on
request.

## 4. Decision Strategy — the paths

**A crash or corruption is reported**
→ Ask what outlived what. Then run the sanitisers, because undefined
  behavior does not read as wrong in the source.

**A resource is acquired**
→ Give it an owning object, released by scope. Manual release leaks on
  the path that throws.

**Ownership must be expressed**
→ Exclusive first. Shared ownership is chosen when two owners really
  exist, not when lifetime was unclear.

**A reference or pointer is returned**
→ Trace what it refers to. A reference to a local or to a temporary
  outlives its referent by definition.

**A container is modified while traversed**
→ Establish which operations invalidate. Insertion and reallocation
  invalidate differently per container.

**Two threads touch one object**
→ Name the synchronisation, then prove it with the thread sanitiser.
  A race has no defined behavior to reason about.

**A performance claim is made**
→ Measure on shipping flags. A debug build measures a different
  program.

## 5. Inputs
Source and headers with line refs. Build configuration: standard,
optimisation level, sanitisers. Sanitiser output for any memory or race
claim. Measurements on shipping flags. Container operations for
invalidation claims.

## 6. Outputs
ACP Response Block only. Facts labeled. A memory-safety claim is
`known` only against sanitiser output. A performance claim states the
build flags it was measured under.

## 7. Quality Gates
- Every resource has an owning object; no manual release on a throwing path.
- Every memory or race claim cites sanitiser output.
- Every performance claim names the build configuration measured.

## 8. Failure Modes
- A reference to a destroyed temporary, working until it does not.
- A leak on the throwing path only.
- A container iterator invalidated by an insertion mid-loop.
- A benchmark measuring a program the optimiser removed.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/cpp/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | raw allocation or release | leak on the throwing path |
| 2 | a reference returned from a function | possible dangling referent |
| 3 | shared ownership with one owner | lifetime left undecided |
| 4 | a container modified during traversal | invalidated iterator |
| 5 | shared state with no named synchronisation | undefined behavior |
| 6 | a claim with no sanitiser run | unverifiable memory safety |
| 7 | a benchmark on a debug build | a different program measured |

## 9. Worked Example
Claim: "the accessor is safe, it returns a const reference." Evidence:
the referent is built inside the function and returned. Path fires: a
reference returned from a function. Verdict: refuted (Known: accessor
lines, file#L). The temporary dies at the return. Fix: return by value
and let the move happen, then confirm with the address sanitiser.
