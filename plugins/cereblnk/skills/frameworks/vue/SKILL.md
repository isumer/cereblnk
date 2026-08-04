---
name: vue
description: How to reason about Vue — reactivity that tracks what you read, state that belongs somewhere specific, and templates that should not compute. Use for any .vue implementation or review. Constraints in rules/frameworks/vue/.
---

# Vue Skill

## 1. Identity
name: vue · domain: frameworks
requires: typescript
escalate_to: nuxt (routing and rendering strategy)

## 2. Mission
Reactivity tracks what a computation reads. Break the read and the
update stops, silently.

## 3. Philosophy

**Reading requests.** "It doesn't update" is a reactivity question:
which read was lost? Destructuring, a plain assignment, or a value
copied out of its reactive container all break tracking. "Add a store"
usually means state was placed too high or too low, not that a store
was missing.

**Where risk lives.** Lost reactivity, which fails silently rather than
loudly. Watchers doing work a computed value should do, so effects fire
in orders nobody chose. Lifecycle cleanup skipped, leaving listeners
after unmount. And templates computing, so a method runs on every
re-render.

**Verification here.** Trace the read path from the source to the
consumer, and confirm the reactive wrapper survives every hop. A
"reacts to" claim is verified by changing the source and observing, not
by reading the declaration. Lifecycle claims are verified by unmounting.

**False-competence traps.** A watcher chain that a computed value would
express in one line. Destructuring a reactive object and wondering why
it froze. A store introduced for one component's local state. Deep
watching applied to a large object because a shallow one missed
something.

**Instincts.** Computed for derivation, watchers for effects. State at
the lowest component that needs it. Every listener and timer removed on
unmount. Keep templates reading, not computing.

## 4. Decision Strategy — the paths

**A value does not update**
→ Trace where the read was lost. A destructure, a copy, or an
  assignment that replaced the container all break tracking.

**A derived value is needed**
→ Use a computed value. A watcher that writes state is an effect
  pretending to be a derivation.

**A watcher is added**
→ Ask what external thing it synchronises. Two watchers writing each
  other's sources is an order nobody chose.

**A listener, timer or subscription starts**
→ Remove it on unmount, in the same block that created it.

**State is shared by two components**
→ Lift it to their nearest common ancestor. A store is for genuinely
  application-wide or persisted state.

**A template calls a method**
→ Move it to a computed value. A method in a binding runs on every
  re-render.

**Deep watching is proposed**
→ Ask what changed that a shallow watch missed. Deep watching a large
  object costs on every mutation anywhere inside it.

## 5. Inputs
Component source with line refs. The reactive source and every hop to
its consumer. Lifecycle hooks for cleanup claims. Store definitions and
their readers. Rendered output for template claims.

## 6. Outputs
ACP Response Block only. Facts labeled. A reactivity claim is `known`
only against an observed update. Reading a declaration yields `derived`
at best.

## 7. Quality Gates
- Every derived value is computed, not watched into a variable.
- Every listener or timer is removed on unmount.
- Every reactivity claim cites an observed change.

## 8. Failure Modes
- A view frozen because a reactive object was destructured.
- Watchers firing in an order that changes between releases.
- A listener surviving unmount and firing on a dead component.
- A method in a template running on every unrelated re-render.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/vue/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | a reactive object destructured | tracking lost silently |
| 2 | a watcher writing state | derivation as an effect |
| 3 | a listener with no unmount cleanup | fires after teardown |
| 4 | a method call in a binding | runs every re-render |
| 5 | a store holding one component's state | wrong placement |
| 6 | deep watching a large object | cost on every inner change |
| 7 | two watchers writing each other's sources | unchosen order |

## 9. Worked Example
Claim: "the total updates when items change." Evidence: the total is
assigned once from a destructured property. Path fires: a reactive
object destructured. Verdict: refuted (Known: component lines, file#L).
The read happened once and tracking never began. Fix: express the total
as a computed value, then change an item and observe.
