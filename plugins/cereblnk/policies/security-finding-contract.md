# Security Finding Contract

Governs security findings: level-3 gate policy, ACP epistemic labels,
and the risk model. Class: M (the enforcer
script) + D (this contract). Consumed by `/cb-security-audit` before
synthesis; the enforcer script blocks assembly on violation.

## 1. Label mapping (no new vocabulary — ACP only)

Prior security-craft material used a "derived / inferred" evidence
model. It maps onto the existing ACP labels; the enforcer
speaks ACP:

| Prior term | ACP label | Meaning here |
|---|---|---|
| observed | `known` | directly seen in code/config/output, with an evidence ref |
| derived | `derived` | follows from known facts, chain stated |
| (quantified) | `estimated` | exploit window / blast radius, basis stated |
| inferred | `speculative` | a suspected vuln not yet dynamically confirmed |
| (unverified premise) | `assumed` | a mitigation believed without evidence |

Rule L-1: a finding whose exploitability is `speculative` or rests on
an `assumed` mitigation MUST name the concrete dynamic test that would
confirm/refute it (the "proof" field). A speculative finding with no
named test is not a finding — it is noise (: speculative facts
never drive a decision alone). **Checker:** security-findings-lint.

## 2. Required fields per finding

- `id`
- `severity`: one of CRITICAL | HIGH | MEDIUM | LOW | INFO
- `label`: an ACP label
- `surface`: the mapped attack surface / evidence ref (file#lines,
  endpoint, config key). Absence-of-control findings ("no rate limit")
  MUST cite the surface where the control is absent.
- `exploit_precondition`: the concrete condition that makes it
  exploitable
- `proof`: evidence ref for `known`/`derived`; a NAMED dynamic test for
  `speculative`/`assumed`
- `fix`: minimal remediation
- `falsified_by`: what evidence downgrades or closes it

## 3. Artifact-level requirements

- `authorized_scope`: an explicit statement that the audit is within
  authorized scope. Missing → the artifact is refused (ethics posture,
  restated verbatim from the security craft: authorized targets only,
  no weaponized exploit code).
- `surfaces_walked`: the list of surfaces examined — so an
  absence-of-control finding maps to a walked surface and OWASP
  categories with no surface can be ruled not-applicable, not skipped.
- Findings are ordered by **impact × exploitability, highest first**
  (09 Procedure 3 — lead with what hurts most).

## 4. Enforcement flow

`/cb-security-audit` produces the findings artifact →
`${CLAUDE_PLUGIN_ROOT}/scripts/security-findings-lint <artifact>` →
exit 0 admits it to synthesis; exit 1 blocks synthesis and the
orchestrator discards + re-issues. **Checker:**
VerifierAgent confirms during the gate that the enforcer actually ran
on this run's artifact (a level-3 security synthesis with no enforcer
pass is a `weakened` verdict and a re-plan trigger).
