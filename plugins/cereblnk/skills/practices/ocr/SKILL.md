---
name: ocr
description: How to treat transcription output — probabilistic by nature, wrong in predictable places, and honest about an engine that may be unavailable. Use for scanned-document work.
---

# OCR Skill

## 1. Identity
name: ocr · domain: practices
complements: document-extraction · data-modeling
escalate_to: data-agent (downstream tolerance) · compliance-agent (regulated figures)

## 2. Mission
The output is a best guess. The request is the text and the places
where confidence is low.

## 3. Philosophy

**Reading requests.** "Read this scanned document" hides that
transcription is probabilistic. The output is a best guess, wrong in
predictable places: similar digits and letters, adjacent characters
read as one, table borders read as text. The real request is the text
and the uncertainty together.

**Where risk lives.** Treating output as exact. A transcribed account
number, dosage, or legal figure with one substituted digit is a
silent, expensive error. And availability: transcription needs an
engine that may not exist in this environment. A tool returning
nothing instead of saying so is the worst outcome.

**Verification here.** Confirm the engine exists before promising
anything. Then check known-hard characters against the source region.
A transcribed figure is `estimated` unless a human or a check digit
confirms it. Confidence scores are evidence; their absence is also
evidence.

**False-competence traps.** Transcribed digits used as exact values.
An empty result reported as an empty page. Accuracy claimed from a
clean sample and generalized to real scans. Uncertainty dropped when
the text moves downstream.

**Instincts.** Carry uncertainty with the text. Verify figures with a
check digit or a human. Say plainly when the engine is unavailable.
Never let a transcription become `known` on its own.

## 4. Decision Strategy — the paths

**Transcription is requested**
→ Confirm the engine is available first. Promising output that cannot
  be produced wastes more than saying so.

**A number is transcribed**
→ Label it `estimated`. Similar digits substitute silently and the
  error surfaces far downstream.

**A figure is consequential**
→ Require a second source: a check digit, a total, or a person. High
  cost per error justifies the second look.

**Output is empty**
→ Report the failure, never an empty document. Silence here is
  indistinguishable from a blank page and is trusted as one.

**Accuracy is claimed**
→ State the sample. Clean scans do not predict the behavior of
  photographed, skewed, or low-contrast pages.

**Text moves downstream**
→ Carry the uncertainty with it. Labels dropped at a boundary turn a
  guess into a fact in one hop.

**A table is transcribed**
→ Check the borders. Rules and lines are commonly read as characters
  and quietly join the data.

## 5. Inputs
Source images and their quality. Engine availability. Confidence
scores where produced. Check digits or totals for verification. Known
hard character classes.

## 6. Outputs
ACP Response Block only. Facts labeled. Transcribed values are
`estimated` by default. A value becomes `known` only with a second
confirming source.

## 7. Quality Gates
- Every transcription states engine availability.
- Every consequential figure has a second source.
- Every empty result is reported as a failure, not a blank page.

## 8. Failure Modes
- One substituted digit in an account number, found weeks later.
- An empty page recorded for a document that failed to process.
- Accuracy promised from clean samples and delivered on photographs.
- Table borders appearing as characters inside the data.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | transcribed value labeled known | probabilistic treated as exact |
| 2 | empty output reported as an empty document | failure hidden |
| 3 | consequential figure with no second source | silent high-cost error |
| 4 | accuracy claimed from clean samples | real scans differ |
| 5 | uncertainty dropped at a boundary | guess becomes fact |
| 6 | engine availability unstated | promise cannot be kept |
| 7 | table borders present in the data | rules read as characters |

## 9. Worked Example
Claim: "the invoice totals were extracted correctly." Evidence: the
figures come from transcription with no check against the stated sum.
Path fires: a consequential figure with no second source. Verdict:
weakened (Known: transcription output; Estimated: each figure). Fix:
compare the line items against the document total and escalate any
mismatch to a human before use.
