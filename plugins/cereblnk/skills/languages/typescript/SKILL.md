---
name: typescript
description: How to reason about TypeScript — invariants the compiler enforces, boundaries it cannot see, and where compile-time confidence becomes a runtime lie. Use for any .ts/.tsx implementation or review. Constraints in rules/languages/typescript/.
---

# TypeScript Skill

## 1. Identity
name: typescript · domain: languages
requires: javascript
escalate_to: react (React specifics) · angular (Angular specifics) · nextjs (SSR and routing)

## 2. Mission
The compiler proves what you asked it to prove. At every boundary it
proves nothing, and says nothing about that.

## 3. Philosophy

**Reading requests.** "Add types to this" hides a real question. Which
invariants should the compiler enforce? Typing the current shape
blesses the current bugs. "Fix this type error" often means the types
found a design flaw. Ask which one is wrong first.

**Where risk lives.** Every place the compiler cannot see. Parsed
JSON. API responses. Casts. Any-typed seams. Third-party declarations
promising more than the runtime delivers. Compile-time confidence
about runtime data is the signature failure here.

**Verification here.** For a type claim, make the compiler prove it.
Introduce the invalid state and watch the build fail. For a boundary
claim, find the runtime check. An annotation on external data with no
validation is Assumed, whatever the editor shows.

**False-competence traps.** Type gymnastics encoding no new
invariant. Casts used to silence errors rather than answer them. A
sound-looking generic with an any-typed middle. A fully typed
codebase whose every boundary trusts the wire.

**Instincts.** Make illegal states unrepresentable first. Narrow once
at the boundary, then trust inside. Discriminated unions over boolean
flags. Strict flags on. A codebase arguing with strict null checks is
naming its own bugs.

## 4. Decision Strategy — the paths

**External data enters the program**
→ Parse and validate at the boundary. A schema parse, or a hand
  written guard that returns the narrowed type.
→ An annotation alone is Assumed. Label it that way in the block.

**A cast appears in a diff**
→ Ask what the compiler was objecting to. The objection is the
  finding. Casts move risk from build time to production.

**A type error blocks work**
→ Decide whether the type or the code is wrong. Suppressing the
  error answers neither question.

**Two states cannot both be true**
→ A discriminated union, not two booleans. Four representable states
  where two are legal invites the illegal pair.

**A generic is written**
→ Trace one concrete instantiation end to end. An any in the middle
  launders everything downstream and still compiles.

**A third-party type declaration is trusted**
→ Check it against the runtime once. Declarations describe intent,
  not behavior, and drift silently across versions.

**A value may be absent**
→ Model the absence in the type. Optional chaining hides the
  question; it does not answer it.

## 5. Inputs
Source chunks with line refs. Compiler configuration and strictness
flags. Boundary code: fetch, parse, and controller layers. The failing
build output when debugging.

## 6. Outputs
ACP Response Block only. Facts labeled. A type claim is `known` only
when a compile-time proof is named. Boundary claims are `known` only
against a runtime validation site.

## 7. Quality Gates
- Every external boundary has one named runtime validation.
- Every cast in the diff carries a stated reason.
- Every claimed invariant is one the compiler actually rejects.

## 8. Failure Modes
- Well-typed code trusting an unvalidated response.
- A cast hiding a real shape mismatch until production.
- Generic soundness broken by one any in the chain.
- Boolean pairs representing states that cannot coexist.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/typescript/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | parsed external data with no schema check | unvalidated boundary |
| 2 | cast introduced next to a former error | suppressed objection |
| 3 | any inside a generic signature | laundered soundness |
| 4 | two booleans encoding one state | illegal pair reachable |
| 5 | third-party declaration never runtime-checked | silent drift |
| 6 | optional chaining on a required value | absence unmodelled |
| 7 | strictness flag disabled for one file | localized blind spot |

## 9. Worked Example
Claim: "the response is typed, the handler is safe." Evidence: the
fetch result is annotated, with no parse step. Path fires: external
data entering with no runtime check. Verdict: weakened (Known:
annotation site; Assumed: wire shape). Fix: parse at the boundary and
return the narrowed type. A test feeds a malformed payload and
expects rejection, not a cast.
