---
name: ruby
description: How to reason about Ruby — a language that lets you change anything at runtime, so the question is always what the code becomes rather than what it says. Use for any .rb implementation or review. Constraints in rules/languages/ruby/.
---

# Ruby Skill

## 1. Identity
name: ruby · domain: languages
complements: api-design
escalate_to: performance-engineering (allocation and query load)

## 2. Mission
Read what the code becomes, not what it says. Anything may be
redefined, so the definition you found is a hypothesis.

## 3. Philosophy

**Reading requests.** "Add a method" hides where it should live —
a class, a module, a concern that three others already include.
"It's slow" in a Ruby application is usually the database or object
allocation, rarely the interpreter.

**Where risk lives.** Metaprogramming that moves behavior out of the
file where a reader looks. Monkey patches on library or core classes.
Callback chains where saving one record triggers four more. And
mutation of shared state, since strings and arrays pass by reference.

**Verification here.** Ask the object what it actually responds to and
where that came from — the method's source location, not the class you
expected. A query-count claim is verified by counting statements, never
by reading the model. Behavior added by a concern is verified on an
instance.

**False-competence traps.** A DSL built for one caller. Core classes
reopened for convenience. Callbacks doing work that belongs in a
service, so a test fixture triggers an email. Nil guards everywhere
because absence was never modelled.

**Instincts.** Boring Ruby over clever Ruby. Metaprogramming behind a
narrow, tested boundary. Plain objects for domain rules; callbacks only
for the record's own integrity. Freeze what should not change.

## 4. Decision Strategy — the paths

**A method's origin is unclear**
→ Ask the object for its source location. Inheritance, modules and
  patches all answer, and the answer is often not the file you opened.

**Metaprogramming is proposed**
→ Ask what a reader will grep for. Behavior no search finds is
  behavior the next person breaks.

**A core or library class is reopened**
→ Refuse by default. A refinement or a wrapper keeps the change local
  and findable.

**A callback is added**
→ Ask whether it protects the record's own integrity. External
  effects belong in a service the caller invokes.

**A collection is loaded and iterated**
→ Count the queries. One statement per row is this domain's most
  common performance defect.

**A string or array crosses a boundary**
→ Decide who may mutate it. Passing by reference means a caller's
  change is visible to everyone holding it.

**A nil check appears**
→ Ask whether absence is legal. Guards multiplying is a sign the model
  never decided.

## 5. Inputs
Source with line refs. Ruby version and frozen-literal convention.
Query logs or statement counts for performance claims. Method source
locations for anything inherited or patched. Callback chains on
touched models.

## 6. Outputs
ACP Response Block only. Facts labeled. A behavior claim is `known`
only with the method's source location cited. Query-count claims cite
the count, not the model code.

## 7. Quality Gates
- Every metaprogrammed behavior has a test naming what it defines.
- Every callback is justified as the record's own integrity.
- Every collection iteration states its query count.

## 8. Failure Modes
- Behavior defined at runtime that no search reveals.
- A patch on a core class breaking an unrelated gem.
- A test fixture sending mail through a callback chain.
- One query per row discovered under production volume.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/ruby/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | a method defined at runtime | invisible to search |
| 2 | a core or library class reopened | breakage far away |
| 3 | a callback with an external effect | fixtures cause side effects |
| 4 | iteration over an association | one query per row |
| 5 | a mutable string or array shared | change at a distance |
| 6 | nil guards multiplying | absence unmodelled |
| 7 | a DSL with one caller | speculative complexity |

## 9. Worked Example
Claim: "the report is fast, it is one query." Evidence: the view calls
an association inside the loop over its rows. Path fires: iteration
over an association. Verdict: refuted (Known: view and model, file#L).
One statement becomes one per row. Fix: load the association up front
and assert the statement count in a test.
