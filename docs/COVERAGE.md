# Capability Coverage Map

> Produced by task CB-036. Maps every reference-toolkit capability class
> (per `08_PLATFORM_CATALOG.md` §1 synthesis) to its Cereblnk
> realization and phase — or marks it deferred with the reason.
> Reference projects contributed **ideas only**; all names, commands,
> structures, and prompt text here are original (01 §7, verified below).

## 1. Capability mapping

| Reference capability class | Cereblnk realization | Phase | Status |
|---|---|---|---|
| Intent/product framing before code | `/cb-frame` (IntentFramingWorkflow) | 2 | **shipped** |
| Feature design / spec | `/cb-design` (FeatureDesignWorkflow) | 2 | **shipped** |
| Plan → build execution | `/cb-implement` (ImplementationWorkflow) | 2 | **shipped** |
| Code review | `/cb-pr-review` (PRReviewWorkflow) | 1 | **shipped** |
| Bug investigation / debugging | `/cb-bug` + DebuggerAgent | 1–2 | **shipped** |
| Test pass / QA | `/cb-qa` (QAWorkflow) | 2 | **shipped** |
| Refactoring | `/cb-refactor` + RefactoringAgent | 2 | **shipped** |
| Security audit | `/cb-security-audit` + owasp-threat-modeling skill | 2 | **shipped** |
| Documentation sync | `/cb-docs` + docs/technicalwriter agents | 2 | **shipped** |
| Safety guardrails | 4 hooks (destructive, boundary, post-edit test, secret guard) | 1 | **shipped** |
| Specialist expertise ("modes") | 20 subagents with isolated context + Law 1 boundaries (not persona prompts — 08 §7.1) | 1–2 | **shipped** |
| Stack thinking styles | 28 domain skills, 09 Part IV philosophies | 2 | **shipped** |
| Product gate ("CEO review" class) | `/cb-product-gate` | 3 | deferred by design |
| UX gate ("design review" class) | `/cb-ux-gate` | 3 | deferred by design |
| Plan pipeline + readiness dashboard | `/cb-plan-pipeline` | 3 | deferred by design |
| Release / ship | `/cb-release` | 3 | deferred by design |
| Deploy + post-deploy watch | `/cb-deploy`, `/cb-watch` | 3 | deferred; watch degraded until Reality Map confirms log/browse tooling |
| Incident response | `/cb-incident` | 3 | deferred by design |
| Retro / metrics | `/cb-retro` | 3 | deferred by design |
| ADR / changelog / health score | `/cb-adr`, `/cb-changelog`, `/cb-health` | 3 | deferred by design |
| Session memory / continuity | `/cb-memory`, `/cb-save`, `/cb-resume` | 4 | deferred by design |
| Real-browser / live-device QA | none | — | **F-class**: no plugin-compatible mechanism confirmed (05 Reality Map, 08 §7.4); /cb-qa ships evidence-based instead |
| Remaining catalog skills (kotlin, go, python, nodejs, nextjs, oracle, redis, elasticsearch, nginx, linux-ops, cloud-architecture, observability, release-engineering, artifact-management, event-driven-architecture, microservices, performance-engineering, accessibility, technical-writing, legacy-modernization) | skills catalog 08 §5 | 3 | deferred by design |

Every reference capability is therefore **mapped or explicitly
deferred with a reason** — nothing is silently missing.

## 2. What Cereblnk adds beyond the references (08 §7)

Cross-agent contradiction detection (ConsistencyAgent) · risk-scaled
mandatory verification on every workflow · epistemic labels surviving
to the user · context budgeting with the Tree of Context.

## 3. Originality audit result

Command run at CB-036 (2026-07-17), scoped to shipped artifacts
(`plugins/`, `tests/`, root READMEs):

```
./scripts/verify        # the "leakage scan" suite
```

The strings themselves are deliberately absent from this document. A
check that names what it is hiding publishes it in the same repository;
`scripts/check-leakage` reads an uncommitted wordlist and reports only
`path:line` and an entry number, never the match.

Known: zero reference-project names, commands, or file structures in
any shipped artifact. Core documents under `docs/` mention reference
projects **by name only as prior art** (00 §6, 06 §3) — which is the
documented, permitted usage. All command names use the original
`/cb-` prefix; all agent/workflow names follow 01 §7.

## 4. Falsifiers

- A reviewer finding any reference-toolkit command name, directory
  convention, or prompt text reproduced in `plugins/` refutes §3.
- A reference capability absent from the §1 table refutes the
  completeness claim — add the row and classify it.
