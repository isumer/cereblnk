---
name: accessibility
description: How to reason about access — the same journeys completed by keyboard or screen reader, semantics before attributes, and states nobody announces. Use for interface work.
---

# Accessibility Skill

## 1. Identity
name: accessibility · domain: practices
complements: component-testing · technical-writing · react
escalate_to: ux-agent (experience decisions) · frontend-agent (implementation)

## 2. Mission
Use it the way the user does. Keyboard only, then screen reader only,
completing the same journey.

## 3. Philosophy

**Reading requests.** "Make it accessible" hides the decisive
question: for whom, doing what? The requirement is that someone using
only a keyboard, or only a screen reader, completes the same journeys.
"Add attributes" is usually the wrong first move. The first move is
the semantic element that already carries the behavior.

**Where risk lives.** Custom controls, where an element dressed as a
button loses focus, keyboard activation, and announcement at once.
Dynamic content nobody announces: errors, loading, results updating
silently. Focus lost or trapped across dialogs and route changes.
Information carried by color alone.

**Verification here.** Complete the journey with the keyboard only.
Then with a screen reader. An announcement claim is verified by
hearing it, not by reading the attribute. Contrast is measured, not
judged. A component's role is verified by what the accessibility tree
reports.

**False-competence traps.** Attributes added onto elements that
already had semantics, often overriding them. A focus outline removed
for appearance. A test suite passing while no journey was completed by
keyboard. Contrast approved by eye on one bright monitor.

**Instincts.** Use the semantic element first. Manage focus explicitly
at every transition. Announce state changes. Never carry meaning by
color alone.

## 4. Decision Strategy — the paths

**A control is built**
→ Use the semantic element. It brings focus, keyboard behavior, and
  announcement without any attribute.

**A custom control is unavoidable**
→ Restore all three explicitly: focus, keyboard activation, role. Any
  one missing makes it unusable rather than imperfect.

**Content changes without navigation**
→ Announce it. Errors, loading, and result updates are invisible to a
  screen reader unless something says them.

**A dialog opens or a route changes**
→ Move focus deliberately and return it on close. Focus left behind
  strands the user at the top of the page.

**Meaning is shown by color**
→ Add a second channel: text, shape, or position. Color alone
  excludes a large group and fails in print too.

**A focus outline is removed**
→ Replace it with a visible alternative. Removing it without a
  replacement makes keyboard use guesswork.

**Contrast is chosen**
→ Measure it. Judgment on a bright monitor is not evidence for a
  user on a dim laptop outdoors.

## 5. Inputs
The rendered interface and its accessibility tree. Keyboard-only
journey results. Screen reader output. Measured contrast values. Focus
behavior across transitions.

## 6. Outputs
ACP Response Block only. Facts labeled. Announcement claims are
`known` only against observed screen reader output. Contrast claims
cite measured values.

## 7. Quality Gates
- Every journey is completable with the keyboard alone.
- Every state change is announced.
- Every meaning carried by color has a second channel.

## 8. Failure Modes
- A form submittable by mouse and unreachable by keyboard.
- An error rendered silently, leaving the user waiting.
- Focus stranded at the page top after a dialog closes.
- A status conveyed only by red and green.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | non-semantic element acting as a control | focus and role lost |
| 2 | state change with no announcement | invisible to screen readers |
| 3 | dialog with no focus management | user stranded |
| 4 | meaning carried by color alone | excluded users |
| 5 | focus outline removed with no replacement | keyboard use blind |
| 6 | attributes added over existing semantics | native behavior overridden |
| 7 | contrast judged rather than measured | fails in real conditions |

## 9. Worked Example
Claim: "the menu is accessible, it has the right attributes."
Evidence: the trigger is a generic element and cannot be reached by
keyboard. Path fires: a non-semantic element acting as a control.
Verdict: refuted (Known: markup and keyboard journey). Attributes
describe a control the keyboard cannot reach. Fix: use the semantic
element, then complete the journey with the keyboard alone.
