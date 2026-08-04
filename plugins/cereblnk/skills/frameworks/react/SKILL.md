---
name: react
description: How to reason about React work — render cycles, state ownership, effects, identity. Use for any .tsx/.jsx implementation or review. Recipes live in PATTERNS.md;. Constraints in rules/frameworks/react/.
---

# React Skill

## 1. Identity
name: react · domain: frameworks
requires: javascript
complements: typescript · component-testing · redux · react-virtualization
escalate_to: nextjs (SSR/routing) · accessibility (a11y evaluation)
recipes: PATTERNS.md (loaded for build/implement tasks only)

## 2. Mission
Reason in render cycles: what re-renders, why, with which captured
values — and where state actually lives.

## 3. Philosophy

**Reading requests.** "Renders twice" or "shows stale data" is an
identity question. Find which dependency changed. Find which closure
holds yesterday's value. "Add a feature" hides a second question: who
owns this state, and is it really client state?

**Where risk lives.** Effects. Dependency arrays that lie. Cleanup
that never runs. Stale closures in timers. Caches mutated without
invalidation. New object identities created every render.

**Verification here.** Count renders with instrumentation. Check the
dep array against every value the closure reads. Assert behavior
through testing-library, never internals. Feel is not evidence.

**False-competence traps.** Memoization added without measurement.
Effect chains as data flow. Derived state copied into useState.
Lint suppression presented as a fix.

**Instincts.** Keep state low. Derive before storing. Server state
goes to a query layer. Every effect names the external system it
synchronizes, or it dies.

## 4. Decision Strategy — the paths

Follow the first matching path. Recipes are in PATTERNS.md; do not
inline them here.

**A value is computable from props or state**
→ Compute it during render. Do not create state for it.
→ Expensive and measured? PATTERNS §1 (memoized derivation).

**New state is being added**
→ One subtree uses it: keep it local.
→ Two distant consumers: lift, or apply the redux skill's global test.
→ It came from the server: it is cache, not state → PATTERNS §2
  (query layer with invalidation).

**An effect is being written**
→ Name the external system it synchronizes. Cannot name one?
  Move the logic to render or an event handler.
→ It stays: deps = the closure's full read set, cleanup returned
  → PATTERNS §3 (debounce, subscription, abortable fetch).

**A list is being rendered**
→ Key by stable id, never index.
→ Rows exceed ~100 or frames drop: escalate to react-virtualization.

**A fetch responds to changing input**
→ Guard against stale overwrites → PATTERNS §4 (AbortController).

**A component is growing**
→ More than ~7 props or boolean mode flags: split or compose
  → PATTERNS §5 (composition, compound components).
→ Logic mixed with markup: extract the hook → PATTERNS §6.

**Performance is claimed or requested**
→ Measure first. No number, no memo. State the number in the output.

**Raw HTML, tokens, or redirects appear**
→ Stop. Sanitize at the boundary, or render as text.
  SecurityAgent decides.

## 5. Inputs
Component and hook source. State ownership map. Render/effect
instrumentation or test evidence. Cache configuration.

## 6. Outputs
ACP Response Block only. Render-behavior claims are `known` with
instrumented or test evidence. Dependency claims are `derived` with
the read set stated.

## 7. Quality Gates
- Every touched effect answers: which external system, which read set,
  which cleanup.
- No new derived-state copies without a stated reason.
- Behavior asserted via testing-library, not internals.

## 8. Failure Modes
- Subscription firing with stale props after a prop change.
- Double-fetch under StrictMode exposing a non-idempotent effect.
- Index-keyed list corrupting rows after reorder.
- Cache serving deleted data after a mutation.
- Effect chain: setState in effect A triggering effect B.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/react/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | `key={index}` in a list | identity |
| 2 | `useState` seeded from props or other state | derived-state copy |
| 3 | effect dep missing from its read set, or lint suppressed | stale closure |
| 4 | timer/listener/subscription without cleanup | leak |
| 5 | setState in one effect triggering another | effect chain |
| 6 | fetch in effect with no abort or sequence guard | stale overwrite |
| 7 | memo/useMemo with no measurement cited | optimization theater |
| 8 | `dangerouslySetInnerHTML` with non-constant input | XSS → SecurityAgent |

## 9. Worked Example
Claim: "search debounces correctly; the timeout is in an effect."
The effect closes over `query`; the dep array is empty. Every
keystroke after mount debounces the first query. Verdict: refuted
(Known: dep array vs read set, file#L). Fix: PATTERNS §3 debounce;
the test asserts one call with the last value.
