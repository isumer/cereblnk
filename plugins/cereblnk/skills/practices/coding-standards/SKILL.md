---
name: coding-standards
description: How to decide which standard is real — declared, enforced, or observed — and where a style rule carries runtime behavior. Use when conventions govern a change.
---

# Coding Standards Skill

## 1. Identity
name: coding-standards · domain: practices
complements: code-review-craft · legacy-modernization
escalate_to: architect-agent (convention conflicts) · technicalwriter-agent (documenting decisions)

## 2. Mission
Three standards usually disagree: the written one, the enforced one,
and the one the code exhibits. Establish precedence before writing.

## 3. Philosophy

**Reading requests.** "Follow our standards" hides which standards are
real. The written document, the machine-enforced configuration, or the
style the codebase actually exhibits. These routinely disagree. Fix
the precedence first: declared, then enforced, then observed. A
conflict between them is a finding, not a silent choice.

**Where risk lives.** Enforcement drift and convention overreach.
Drift makes reviews flag what the pipeline accepts, and the standard
stops being trusted. Overreach rewrites code beyond the task, which is
untraceable diffs and new risk in untouched features. The highest-risk
rules are the ones with runtime consequences dressed as style.

**Verification here.** Read the enforcement configuration, not the
document. A claim that something is required is verified by the rule
that fails a build. Observed style is measured across the module, not
inferred from one file. When a rule carries behavior, trace what
bypassing it changes.

**False-competence traps.** Formatting a whole file while changing
three lines. A written standard cited that no tool enforces. Personal
preference presented as convention. A mandated wrapper bypassed
because it looked like decoration.

**Instincts.** Match the surrounding code even when you would choose
differently. Report conflicts rather than resolving them silently.
Keep changes traceable to the request. Ask what a style rule enforces
at runtime before treating it as cosmetic.

## 4. Decision Strategy — the paths

**Standards conflict**
→ Report the conflict. Choosing silently makes the next reader
  believe the codebase agrees with itself.

**A rule is cited**
→ Find what enforces it. An unenforced rule is a preference, and
  preferences do not block a change.

**Formatting differs from the file's style**
→ Match the file. Reformatting beyond the task obscures the diff that
  reviewers must read.

**A convention carries runtime behavior**
→ Trace what bypassing it changes. Wrappers that carry cancellation,
  authentication, or context are behavior, not style.

**Observed style is inconsistent**
→ Measure across the module before declaring a dominant style. One
  file is not evidence of a convention.

**A standard has drifted from enforcement**
→ Name it as a finding. Reviews that contradict the pipeline erode
  both.

**Personal preference appears in review**
→ Separate it explicitly. Preferences stated as standards spend the
  team's trust on nothing.

## 5. Inputs
The declared standards document. Enforcement configuration for
linters, formatters, and compiler flags. Observed style across the
module. Runtime behavior of mandated wrappers.

## 6. Outputs
ACP Response Block only. Facts labeled. A requirement is `known` only
against an enforcing configuration. Observed style is `derived` from
a stated sample.

## 7. Quality Gates
- Every cited rule names what enforces it.
- Every conflict between declared and enforced is reported.
- Every changed line traces to the request, not to preference.

## 8. Failure Modes
- A reformatted file hiding a three-line behavior change.
- Reviews flagging what the pipeline accepts, and the reverse.
- A mandated wrapper bypassed, dropping cancellation silently.
- Preference enforced as standard, spending trust for nothing.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | rule cited with nothing enforcing it | preference as standard |
| 2 | whole-file formatting in a small change | diff unreadable |
| 3 | declared and enforced rules disagreeing | standard untrusted |
| 4 | mandated wrapper bypassed | behavior change as style |
| 5 | convention inferred from one file | sample too small |
| 6 | style comments dominating a review | attention misallocated |
| 7 | silent resolution of a standards conflict | codebase appears coherent |

## 9. Worked Example
Claim: "the change follows our standards, the file is formatted."
Evidence: the diff reformats two hundred lines around a four-line
change and bypasses the shared request wrapper. Two paths fire:
whole-file formatting, and a mandated wrapper bypassed. Verdict:
refuted (Known: diff and wrapper implementation). The wrapper carried
cancellation. Fix: revert the formatting and restore the wrapper.
