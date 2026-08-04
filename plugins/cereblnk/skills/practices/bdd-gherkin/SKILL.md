---
name: bdd-gherkin
description: How to write scenarios that survive a redesign — outcomes in the business's words, intent over mechanics, and one representative case instead of a table. Use for scenario work.
---

# BDD and Gherkin Skill

## 1. Identity
name: bdd-gherkin · domain: practices
requires: requirements-engineering
complements: functional-testing · test-strategy
escalate_to: qa-agent (suite composition) · product-strategy-agent (outcome definition)

## 2. Mission
Would this scenario survive a redesign that preserves the behavior? If
not, it is interface automation wearing a scenario's clothes.

## 3. Philosophy

**Reading requests.** "Write scenarios for this" hides the real
question. Which outcomes does the business care about, in whose words?
A scenario is an acceptance criterion made executable. If it reads
like a click script, it will break on every restyle while testing no
requirement.

**Where risk lives.** Steps describing mechanics rather than intent.
Clicking an element by identifier instead of submitting an order.
Mechanical scenarios couple to the interface, multiply on every
variation, and hide behavior under step noise. And scenario
explosion, where a table row replaces a unit test.

**Verification here.** Apply the redesign test: would this scenario
survive an interface change that preserves the behavior? Then check
whose words it uses. A scenario written in the team's vocabulary
rather than the business's is documentation nobody outside will read.

**False-competence traps.** A large feature file that no stakeholder
has read. Step definitions accumulating variants of the same action.
Tables enumerating inputs that belong in unit tests. Scenarios
maintained as automation and never revisited as criteria.

**Instincts.** Write outcomes, not interactions. Use the business's
nouns. Keep one representative case per behavior. Push input
variations down to cheaper layers.

## 4. Decision Strategy — the paths

**A scenario is written**
→ Apply the redesign test. A scenario that breaks when nothing
  behavioral changed is automation, not a criterion.

**A step names an interface element**
→ Rewrite it as intent. The identifier belongs in the step
  definition, never in the scenario a stakeholder reads.

**A table of inputs appears**
→ Ask which belong in unit tests. Enumerating variations here buys
  slow runs and no additional confidence.

**Vocabulary comes from the code**
→ Replace it with the business's words. A scenario nobody outside
  engineering reads has lost its reason to be a scenario.

**Step definitions multiply**
→ Consolidate on intent. Many steps saying almost the same thing is
  the signal that scenarios describe mechanics.

**A scenario has many steps**
→ Split the behavior. Long scenarios test several things and report
  one failure.

**Scenarios are never read by stakeholders**
→ Name that as a finding. Their readability is the whole return on
  writing them this way.

## 5. Inputs
Acceptance criteria and their source. Existing scenarios and step
definitions. Business vocabulary. The interface the steps drive.

## 6. Outputs
ACP Response Block only. Facts labeled. A scenario's value claim is
`known` only against the redesign test and stakeholder readability.

## 7. Quality Gates
- Every scenario survives an interface change that preserves behavior.
- Every scenario uses the business's vocabulary.
- Every input enumeration is pushed to the cheapest layer.

## 8. Failure Modes
- A feature file broken by a restyle that changed no behavior.
- Scenarios readable only by the engineers who wrote them.
- A table of twenty rows running the slowest layer twenty times.
- One failure reported for a scenario testing four things.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | step naming an interface element | breaks on restyle |
| 2 | scenario in engineering vocabulary | stakeholders excluded |
| 3 | large input table at scenario level | slow, no added confidence |
| 4 | many near-identical step definitions | mechanics, not intent |
| 5 | scenario with many steps | multiple behaviors, one report |
| 6 | feature file never read outside the team | format without return |
| 7 | scenario failing a redesign that kept behavior | automation, not criterion |

## 9. Worked Example
Claim: "the scenarios document our requirements." Evidence: the steps
name buttons and fields by identifier. Path fires: steps naming
interface elements. Verdict: refuted (Known: feature file). A restyle
breaks them and no requirement is captured. Fix: rewrite as outcomes
in the business's words and move identifiers into step definitions.
