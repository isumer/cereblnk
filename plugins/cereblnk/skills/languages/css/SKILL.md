---
name: css
description: How to reason about styling — the cascade, specificity, layout containment, and the fact that a local change has global reach. Use for stylesheet work in any framework. Constraints in rules/languages/css/.
---

# CSS Skill

## 1. Identity
name: css · domain: languages
complements: accessibility · react · angular
escalate_to: scss (preprocessor loading and output) · accessibility (perception and focus) · performance-engineering (rendering cost)

## 2. Mission
Every rule is global until something contains it. Ask what else this
selector reaches before asking whether it looks right.

## 3. Philosophy

**Reading requests.** "Make this look right" hides the containment
question: which other elements does this rule reach? "It works on my
screen" hides three more — narrower viewports, longer text, and a
user's own font size.

**Where risk lives.** Specificity wars, where each fix raises the
stakes until only an override wins. Layout that holds for the sample
content and breaks for real content. Values hardcoded where a token
exists. And anything that reads as decoration but changes behavior:
focus indicators, hit areas, motion.

**Verification here.** Look at it, at more than one width, with real
content. Read the computed style, not the rule you wrote — the cascade
decides, not the source order you had in mind. A containment claim is
checked by changing the rule and watching what else moves.

**False-competence traps.** An importance flag added to win an
argument with a selector. A magic pixel value that happens to line up.
A fixed height on content that grows. A hover state with no keyboard
equivalent.

**Instincts.** Lowest specificity that works. Tokens over literals.
Layout by the layout systems, not by offsets. Assume the text will be
longer and the screen narrower.

## 4. Decision Strategy — the paths

**A rule does not apply**
→ Read the computed style and find what won. Raising specificity
  answers the symptom and moves the problem.

**A value is written literally**
→ Ask whether a token exists. A hardcoded colour or spacing drifts
  from the system on the day the system changes.

**Layout holds for the sample**
→ Try longer text, a narrower viewport, and a larger root font size.
  Content is not the content you tested with.

**A style carries behavior**
→ Treat it as behavior. Focus visibility, hit area and motion are
  usability, not decoration.

## 5. Inputs
The stylesheet and the rendered result. Computed styles for any
cascade claim. The design tokens. The viewport range the product
supports.

## 6. Outputs
ACP Response Block only. Facts labeled. A cascade claim is `known`
only against computed style; reading a rule yields `derived`.

## 7. Quality Gates
- Every cascade verdict cites the computed style, not the source.
- Every layout claim states the widths and content it was checked at.
- Every focus indicator remains visible, or has a stated replacement.

## 8. Failure Modes
- A specificity ladder that ends in importance flags everywhere.
- A layout that breaks on the first long product name.
- A hardcoded value drifting from the token it copied.
- A focus outline removed for appearance, leaving keyboard use blind.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/css/`:
`coding-style` · `patterns`.

Before producing or reviewing styles, read the files whose `paths:`
glob matches what the task touches, plus `rules/common/` once per run.
Cite a violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | an importance flag added | specificity ladder |
| 2 | a literal colour or spacing value | token drift |
| 3 | a fixed height on text content | overflow at real length |
| 4 | a hover state with no focus equivalent | keyboard excluded |
| 5 | a cascade claim from source order | computed style unread |
| 6 | a layout checked at one width | untested range |

## 9. Worked Example
Claim: "the override does not work, so it needs an importance flag."
Evidence: the computed style shows a more specific selector winning.
Path fires: a rule not applying, answered by raising specificity.
Verdict: refuted (Known: computed style). Fix: lower the competing
selector instead, and re-read the computed style to confirm.
