---
name: xml-processing
description: How to handle XML safely — well-formed is not valid, external entities disabled always, and producer and consumer validating the same schema version. Use for XML work.
---

# XML Processing Skill

## 1. Identity
name: xml-processing · domain: practices
complements: document-extraction · api-design · devsecops
escalate_to: security-agent (untrusted input) · architect-agent (contract ownership)

## 2. Mission
Parse untrusted XML with entity resolution disabled, always. Then ask
which schema version is authoritative.

## 3. Philosophy

**Reading requests.** "Parse this" hides the real question: against
which contract? Well-formed and valid are different claims. A document
can parse perfectly and violate every business rule the schema
encodes. "Create a schema" hides whose reality it must encode — the
sample at hand, or the contract partners already depend on.

**Where risk lives.** Trust boundaries. XML from outside is an
injection vector: entity expansion exhausts memory, and external
entity resolution turns a parser into a file reader. Then contract
drift: producer and consumer validating against different versions
fail in production rather than in tests.

**Verification here.** A safety claim is verified by reading the
parser configuration, not the library's reputation. A validity claim
is verified by validating against the authoritative schema, named and
located. Well-formedness alone supports no contract claim.

**False-competence traps.** Parsing success reported as validation.
Entity resolution left at library defaults. A schema generated from
one sample and treated as the contract. Version drift discovered when
a partner's message stops working.

**Instincts.** Disable entity resolution before anything else. Name
the authoritative schema and its location. Validate at the boundary.
Version schemas explicitly and additively.

## 4. Decision Strategy — the paths

**XML arrives from outside**
→ Disable external entity resolution and limit expansion. This is the
  first configuration, not a hardening step for later.

**A document parses successfully**
→ Ask whether it validated. Well-formed says the syntax holds and
  nothing about the contract.

**A schema is needed**
→ Establish which version is authoritative and where it lives.
  Generating one from a sample encodes today's data as the contract.

**Producer and consumer differ**
→ Compare their schema versions. Silent drift here fails in
  production, on the message nobody tested.

**A schema changes**
→ Add rather than alter. Both versions travel in flight while
  independently deployed systems catch up.

**Large documents arrive**
→ Stream rather than load. Whole-document parsing meets its limit at
  the size an attacker chooses.

**Validation fails in production only**
→ Suspect version mismatch before content. The message is usually
  fine against the schema its producer holds.

## 5. Inputs
Parser configuration for entity handling. The authoritative schema and
its version. Producer and consumer schema versions. Sample and
production documents. Size limits.

## 6. Outputs
ACP Response Block only. Facts labeled. Safety claims are `known` only
against parser configuration. Validity claims name the schema and
version used.

## 7. Quality Gates
- Every external parser has entity resolution disabled.
- Every validity claim names the authoritative schema and version.
- Every boundary validates rather than only parsing.

## 8. Failure Modes
- A parser reading local files because entities resolved.
- Memory exhausted by a document the size of one line.
- A contract violated by a document that parsed cleanly.
- A partner's message rejected after an unannounced schema change.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | external parser with default entity handling | file read or exhaustion |
| 2 | parse success reported as validation | contract unchecked |
| 3 | schema generated from one sample | today's data as contract |
| 4 | producer and consumer versions unequal | production-only failure |
| 5 | schema field altered rather than added | in-flight messages break |
| 6 | whole-document parsing of large input | attacker-chosen limit |
| 7 | authoritative schema location unstated | drift undetectable |

## 9. Worked Example
Claim: "the import is safe, the file parses." Evidence: the parser
uses library defaults and resolves external entities. Path fires: an
external parser with default entity handling. Verdict: refuted (Known:
parser configuration). A crafted document reads local files through
it. Fix: disable entity resolution, cap expansion, then validate
against the named schema.
