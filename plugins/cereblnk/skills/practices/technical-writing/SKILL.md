---
name: technical-writing
description: How to write documentation that survives contact with a reader — one reader per document, examples that were run, and drift that is worse than absence. Use for docs work.
---

# Technical Writing Skill

## 1. Identity
name: technical-writing · domain: practices
complements: requirements-engineering · api-design · code-review-craft
escalate_to: technicalwriter-agent (publication decisions)

## 2. Mission
Follow your own instructions on a clean machine. Documentation that
drifted is worse than none, because it is confidently wrong.

## 3. Philosophy

**Reading requests.** "Document this" hides the question that decides
everything. For which reader, arriving with what question? The
newcomer who wants to run it, the integrator who wants the contract,
and the maintainer who wants the rationale need three documents.
Merging them serves none of the three.

**Where risk lives.** Documentation drifting from behavior, which is
worse than absence because it is trusted. The curse of knowledge,
where the step obvious to the author blocks every reader. Structure
burying the critical path under completeness. Examples that were never
run teach a fiction with authority.

**Verification here.** Follow your own instructions on a clean
environment. Every command, in order, without filling gaps from your
own knowledge. An example is verified by running it. A behavioral
statement is verified against the code or the actual output. If a step
cannot be followed literally, it is not written yet.

**False-competence traps.** Completeness pursued at the cost of the
critical path. Examples adapted from memory. Terminology that assumes
the reader already knows the system. A document serving three readers
and satisfying none.

**Instincts.** One reader per document. Lead with the thing they came
for. Run every example. Delete more than you add.

## 4. Decision Strategy — the paths

**Documentation is requested**
→ Name the reader and their question. Three readers means three
  documents, or one document that fails all of them.

**An example is written**
→ Run it, as written, on a clean environment. An adapted example
  teaches a fiction with the authority of documentation.

**A step seems obvious**
→ Write it anyway. The step the author skips is the step that stops
  the reader who needed the document.

**Completeness competes with clarity**
→ Put the critical path first. Everything else can follow it or move
  to another page.

**Behavior is described**
→ Verify against the code or the real output. Descriptions written
  from memory drift silently and are trusted anyway.

**A document ages**
→ Check it against current behavior. Confident wrongness costs more
  than a missing page.

**Terminology is introduced**
→ Define it once where the reader meets it. Assumed vocabulary is the
  curse of knowledge in its most common form.

## 5. Inputs
The intended reader and their question. Current system behavior.
Clean-environment run results for every example. Existing
documentation for drift checks.

## 6. Outputs
ACP Response Block only. Facts labeled. Instruction claims are `known`
only after a clean-environment run. Descriptions from memory are
`assumed` and named.

## 7. Quality Gates
- Every document names its reader and their question.
- Every example has been run as written on a clean environment.
- Every behavioral statement cites code or observed output.

## 8. Failure Modes
- A reader blocked at step three by an omitted prerequisite.
- An example that has never worked in the form published.
- A page trusted for a year after the behavior changed.
- One document written for three readers, useful to none.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | document with no named reader | serves none of them |
| 2 | example never run as written | fiction with authority |
| 3 | prerequisite obvious to the author | reader blocked |
| 4 | completeness before the critical path | key steps buried |
| 5 | behavior described from memory | silent drift |
| 6 | term used before it is defined | curse of knowledge |
| 7 | page unchecked after a behavior change | confidently wrong |

## 9. Worked Example
Claim: "the setup guide is accurate, we followed it last month."
Evidence: a clean-environment run fails at the second command because
a prerequisite is installed on every developer machine. Path fires: a
prerequisite obvious to the author. Verdict: refuted (Known: clean run
output). Fix: add the prerequisite step, then run the guide again from
a clean environment before publishing.
