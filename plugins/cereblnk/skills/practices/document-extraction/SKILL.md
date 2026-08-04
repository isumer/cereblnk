---
name: document-extraction
description: How to extract from documents without silent loss — structure that must survive, parsers that report success on nothing, and fixtures that prove fidelity. Use for parsing work.
---

# Document Extraction Skill

## 1. Identity
name: document-extraction · domain: practices
complements: ocr · xml-processing · data-modeling
escalate_to: data-agent (downstream schema) · security-agent (untrusted files)

## 2. Mission
Ask what structure must survive before flattening anything. A
confident empty result is the worst outcome here.

## 3. Philosophy

**Reading requests.** "Read this document" hides which faithfulness
matters. Raw prose, or the table whose columns carry the meaning? A
financial document extracted as flat prose has lost the thing the
reader needed. Establish what structure must survive before flattening
anything.

**Where risk lives.** Silent loss. A parser that drops a table, merges
columns, or returns nothing from a scanned file while reporting
success has produced a confident lie. Downstream trusts it. Encoding
and format edge cases are where fidelity quietly breaks.

**Verification here.** Round-trip a known fixture. Extract a document
whose content you know and confirm every heading, row, and cell
survived. An extraction claim is `known` only against that comparison.
Empty output is treated as failure until proven to be an empty
document.

**False-competence traps.** Success reported from an exit code rather
than from content. Tables flattened into prose because the parser
offered it. One format tested and the conclusion generalized. Encoding
problems noticed only when a downstream report looks strange.

**Instincts.** Name the structure that must survive. Compare against a
known fixture. Treat empty as suspicious. Report what was lost rather
than silently dropping it.

## 4. Decision Strategy — the paths

**Extraction is requested**
→ Ask which structure carries the meaning. Tables, headings, and
  ordering are lost first and noticed last.

**A parser returns success**
→ Check the content, not the status. Success with no rows is the
  failure mode this domain is known for.

**Output is empty**
→ Treat it as failure until proven otherwise. Scanned pages and
  unsupported encodings both present as empty.

**A table is present**
→ Preserve the grid. Flattened cells read fine and mean something
  else entirely.

**A new format appears**
→ Test it with a known fixture. Conclusions from one format do not
  transfer, and the failure is silent.

**Text looks slightly wrong**
→ Suspect encoding before content. Substituted characters propagate
  into every downstream comparison.

**Something could not be extracted**
→ Report the gap explicitly. A silent omission becomes a fact
  downstream within one hop.

## 5. Inputs
The source documents and their formats. Known fixtures with expected
content. Extraction output for comparison. Encoding details. Structure
requirements from the consumer.

## 6. Outputs
ACP Response Block only. Facts labeled. Fidelity claims are `known`
only against a fixture comparison. Unverified extraction is `assumed`
and names what was not checked.

## 7. Quality Gates
- Every extraction states which structure had to survive.
- Every result is compared against a known fixture.
- Every gap is reported rather than silently dropped.

## 8. Failure Modes
- A table read as prose, changing every number's meaning.
- An empty result accepted as an empty document.
- Substituted characters propagating into downstream matching.
- One format proven and three assumed.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | success taken from a status code | content unverified |
| 2 | empty output accepted | scan or encoding failure |
| 3 | table flattened into prose | meaning lost |
| 4 | no fixture comparison | fidelity assumed |
| 5 | conclusion generalized across formats | silent transfer of trust |
| 6 | odd characters ignored | encoding problem downstream |
| 7 | gap omitted rather than reported | becomes a fact in one hop |

## 9. Worked Example
Claim: "extraction works, the job reports success." Evidence: the
output contains headings and no table rows. Path fires: success taken
from a status code. Verdict: refuted (Known: fixture comparison). The
parser dropped the grid and exited cleanly. Fix: extract with table
support, compare against the fixture, and fail the job when rows are
missing.
