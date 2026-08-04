---
name: react-virtualization
description: Windowed lists and grids — when to virtualize, measurement, keys, scroll, accessibility. Use for long-list work. Constraints in rules/frameworks/react-virtualization/.
---

# React Virtualization Skill

## 1. Identity
name: react-virtualization · domain: frameworks
requires: react · javascript
complements: redux · performance-engineering · accessibility
escalate_to: performance-engineering (measurement methodology) · accessibility (windowed-list semantics)

## 2. Mission
Reason about DOM nodes that exist versus nodes the user can see.
Virtualization renders the window; the hard part is what it silently
removes — find-in-page, focus, screen readers.

## 3. Philosophy

**Reading requests.** "The list is slow" is node count, not the
framework. "Virtualize this" hides: keep selection, scroll, keyboard,
and screen-reader semantics intact.

**Where risk lives.** Wrong item measurement. Variable heights cached
once. Scroll lost on update. Index keys recycling stale content.
Accessibility silently destroyed.

**Verification here.** Count mounted row nodes against viewport
capacity — a number, not an impression. Capture scrollTop before and
after the update; assert equality. Measure a long-content row against
the declared height.

**False-competence traps.** Virtualizing a list that never needed it.
Fixed height over wrapping content that the short demo hid. "Feels
smoother" as a performance claim. Shipping with no a11y answer.

**Instincts.** Measure before virtualizing. Prefer fixed heights when
design allows; measure real heights when it does not. Key by id.
Decide the accessibility story before shipping.

## 4. Decision Strategy — the paths

**Virtualization is proposed**
→ Under ~100 realistic rows and no frame-budget measurement:
  recommend against. Complexity earns its place with evidence.
→ Above, or measured jank: proceed.

**Row keys are chosen**
→ Stable item id, never index. Index keys corrupt recycled rows
  after reorder.

**Item size is declared**
→ Content can wrap or vary: measure real heights; a constant is a
  finding. Demonstration: one long-content row versus the constant.

**A performance claim is made**
→ State mounted-node count versus viewport capacity. No number:
  the claim is speculative until counted.

**Data updates while the list is mounted**
→ Preserve scrollTop explicitly, or the jump is a finding.

**The list ships**
→ State the find-in-page, keyboard, and screen-reader answer.
  No answer: mandatory RISK entry; escalate to accessibility.

## 5. Inputs
List/grid source and config (item size, overscan, key). Realistic row
counts and content samples. Scroll-container structure. Update paths.
The stated a11y requirement, if any.

## 6. Outputs
ACP Response Block only. Key and measurement findings `known` with
refs. Node-count and scroll claims `known` once measured, `speculative`
before. The a11y gap is a named `unknown` blocking a ships-cleanly
verdict.

## 7. Quality Gates
- A measured justification exists before virtualization is recommended.
- Keys are stable ids, verified by reading the row key.
- Every performance claim carries a mounted-node number.
- The accessibility answer is stated, or the list is not ready.

## 8. Failure Modes
- Fixed height over wrapping text: overlap the demo data hid.
- Index keys corrupting rows after a sort.
- Scroll jumping to top on refetch.
- A 10,000-row list invisible to Ctrl-F, found by a user.
- Overscan so high the windowing saves nothing.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/react-virtualization/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | `key={index}` on windowed rows | recycled corruption |
| 2 | constant itemSize with wrappable content | overlap/gap |
| 3 | performance claim with no mounted-node count | unmeasured |
| 4 | update path with no scrollTop restore | scroll jump |
| 5 | windowed list with no stated a11y handling | invisible rows |
| 6 | virtualization added with no row-count evidence | needless complexity |

## 9. Worked Example
Claim: "the transaction list is virtualized and fast." Evidence:
itemSize 44, key by index, merchant names that wrap. Two knowns fire:
index keys (recycled rows show the wrong merchant after sort) and the
constant height against wrapping rows. The "fast" claim carries no
node count — speculative. No find-in-page answer — named unknown.
Verdict: not ready. Every trigger is code-visible or a missing number.
