---
name: redux
description: Where state lives and when it changes — store placement, selectors, reducers, async flows. Use for store-touching work. Recipes in react/PATTERNS.md §2;. Constraints in rules/frameworks/redux/.
---

# Redux Skill

## 1. Identity
name: redux · domain: frameworks
requires: react · javascript
complements: typescript · react-virtualization
escalate_to: react (component-local state that never needed a store) · api-design (server-state caching belongs to a data layer)

## 2. Mission
Reason about WHERE state lives and WHEN it changes. Most Redux bugs
are placement bugs.

## 3. Philosophy

**Reading requests.** "Add Redux for this" hides: which part is truly
global? Usually little. "Re-renders too much" is a selector-identity
question. "Out of sync" means two sources of truth — find the copy.

**Where risk lives.** Selectors returning fresh references. Reducers
mutating outside Immer. Server data cached without invalidation.
Stored derived values. Overlapping thunks racing.

**Verification here.** Call the selector twice with unchanged input;
compare with Object.is. Table-test the reducer: (state, action) in,
expected state out. Reducers are pure — this is mechanical.

**False-competence traps.** Form and modal state in the store.
Whole-slice useSelector. "It works" as an immutability proof. A cache
with no invalidation story called a cache.

**Instincts.** Global only when shared across distant subtrees.
Derive in a memoized selector before storing. Server state goes to a
query layer. Every async write tolerates overlap.

## 4. Decision Strategy — the paths

**New state is proposed for the store**
→ Count distinct consumers. One subtree: keep it local (react skill).
→ Two distant consumers, no parent path: the store earns it.

**A selector is written or reviewed**
→ Return contains a literal, spread, map, filter, or reduce:
  memoize with createSelector, or narrow the selection.
→ Verify: two calls, same input, Object.is must hold.

**A reducer is written or reviewed**
→ Inside createSlice: draft mutation is fine — that is Immer.
→ Outside: assignment to state, or push/splice/sort on it, is a
  finding. Return new references for changed slices only.

**Fetched data lands in a slice**
→ Name the invalidation trigger, or move it to a query layer
  (react/PATTERNS §2).

**A field is computable from other fields**
→ Do not store it. Memoized selector instead.

**A thunk writes after an await**
→ Guard overlap: request id, sequence check, or abort. Name the
  interleaving that breaks without it.

## 5. Inputs
Store and slice source. Selectors in scope. The subtree's ownership
map. Thunk source. Any fetch landing in the store.

## 6. Outputs
ACP Response Block only. Placement verdicts `derived` with consumer
count. Selector and reducer findings `known` with file refs. Race and
stale-cache risks `speculative` until the interleaving is shown.

## 7. Quality Gates
- Every new slice names its two distant consumers, or is rejected.
- Every selector in scope passes the reference-stability check.
- No stored field derivable from siblings without a stated reason.

## 8. Failure Modes
- Inline-object selector re-rendering subscribers on every dispatch.
- Nested mutation Immer does not track, assumed safe.
- Slice serving deleted rows after a mutation.
- Slower thunk overwriting the newer result.
- Every keystroke a global dispatch (form state in the store).

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/redux/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | selector returning `{`/`[`/`.map`/`.filter` inline | identity churn |
| 2 | `state.x =` or push/splice/sort outside createSlice | impure reducer |
| 3 | slice fed from a response, no invalidation path | stale cache |
| 4 | slice field set from other fields at dispatch time | stored derived |
| 5 | thunk dispatching after await, no id/abort guard | race |
| 6 | useSelector returning a whole slice | over-subscription |

## 9. Worked Example
Claim: "the cart total selector is fine, it returns the sum."
Evidence: `useSelector(s => s.items.map(i => i.price * i.qty))`.
Selector path fires: map in the return. Two calls with identical
items are not Object.is-equal. Verdict: refuted (Known, file#L).
Every subscriber re-renders on every dispatch. Fix: createSelector on
items; the test asserts reference stability. Mechanical observation —
any model reaches the same verdict.
