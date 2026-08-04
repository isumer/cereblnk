---
name: javascript
description: How to reason about JavaScript — async ordering, stale state across awaits, swallowed rejections, coercion on user data. Use for any .js implementation or review. Constraints in rules/languages/javascript/.
---

# JavaScript Skill

## 1. Identity
name: javascript · domain: languages
complements: typescript
escalate_to: nodejs (server runtime concerns) · react (component specifics)

## 2. Mission
Most bugs here are ordering bugs. Map the async flow before reading
anything else.

## 3. Philosophy

**Reading requests.** "This sometimes does not work" almost always
means ordering. Which promise resolved first? Which handler ran on
stale state? The report hides one instruction: map the async flow.
"Modernize this" hides a constraint. Do not change observable timing.

**Where risk lives.** Promises never awaited. State mutated across an
await point. Rejections with no catch. Truthiness checks doing
validation work on real data.

**Verification here.** Trace the actual resolution order with a
minimal repro that logs the sequence. For an error path, throw inside
and watch where it surfaces. "Await makes it sequential" is verified
per await, never per function.

**False-competence traps.** Async added everywhere, converting sync
errors into rejections. Fire-and-forget calls kept for speed. Deep
cloning instead of naming a mutation owner. Falsy checks treating zero
and empty string as absence.

**Instincts.** Every promise is awaited, returned, or explicitly
detached with a reason. Mutation has one owner. Strict equality unless
coercion is the point. State read before an await is stale after it.

## 4. Decision Strategy — the paths

**A promise is created**
→ Await it, return it, or detach it deliberately with a comment. An
  unattended promise fails silently and reorders effects.

**State is read, then an await happens**
→ Re-read after the await, or prove nothing else can write. The value
  in hand is a snapshot from before the suspension.

**An async function can reject**
→ Find the catch that owns it. An unhandled rejection surfaces far
  from its cause, or not at all.

**A value is checked for presence**
→ Compare explicitly against null or undefined. Zero, empty string,
  and false are data, not absence.

**Two async operations must be ordered**
→ Express the dependency in the code. Timing that happens to work
  today is Assumed, not Known.

**An object is passed to another module**
→ Name who may mutate it. Defensive cloning everywhere hides the
  question instead of answering it.

**Equality is compared**
→ Strict by default. A loose comparison is a claim about coercion and
  needs a reason.

## 5. Inputs
Source chunks with line refs. The async entry points and their call
order. A minimal repro that logs sequence. Runtime and bundler
configuration when behavior differs across environments.

## 6. Outputs
ACP Response Block only. Facts labeled. Ordering claims are `known`
only against an observed sequence. Timing that merely works today is
`assumed`, and is named.

## 7. Quality Gates
- Every promise has an awaiter, a returner, or a stated detachment.
- Every rejection path has a named handler.
- Every presence check distinguishes absence from falsy data.

## 8. Failure Modes
- An effect applied after the state it was computed from changed.
- A rejection lost because nothing awaited the call.
- Zero or empty string treated as missing input.
- Two effects racing because their order was never expressed.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/javascript/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | async call with no await, return, or comment | silent failure |
| 2 | state captured before an await, used after | stale snapshot |
| 3 | falsy check gating on numeric or string data | zero treated as absent |
| 4 | loose equality on user input | coercion surprise |
| 5 | async work started in a handler with no catch | lost rejection |
| 6 | ordering that depends on resolution speed | unstated race |
| 7 | object shared with no stated mutation owner | action at a distance |

## 9. Worked Example
Claim: "the save is safe, the handler awaits it." Evidence: the
handler reads the form state, awaits the network call, then writes
that captured state back. Path fires: state read before an await and
used after. Verdict: weakened (Known: handler lines, file#L). Fix:
re-read after the await, or send only the fields the call owns. A test
edits during the request and asserts no overwrite.
