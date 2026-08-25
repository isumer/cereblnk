---
name: cb-security-audit
description: OWASP Top 10 + threat-model sweep — always gate level 3; every finding carries severity, evidence reference, and a fix
argument-hint: [scope: path, module, or whole service]
---

# SecurityAuditWorkflow (/cb-security-audit)

**Trigger intent:** audit this for security. Always verification
level 3. Verifier, Challenger, and Consistency. No exceptions, no
fast path, regardless of how small the scope looks (policies/risk-model.md
always-level-3 list).

A Task Block that says otherwise does not lower it. The floor beats the
assigned `verification_level` and the assigned `risk` alike — see
`policies/risk-model.md`, "Precedence: the domain floor beats the
assigned level". Issue every block in this workflow at level 3; a lower
number is a malformed block, and `scripts/acp-lint` T-2 refuses it.

## Agent topology

```
Orchestrator → planner-agent    (slice scope into audit surfaces:
                                 entry points, authn/authz, data flows,
                                 secrets, dependencies)
            → security-agent    (leads every surface; uses
                                 skills/practices/owasp-threat-modeling
                                 when installed)
            → database-agent    (injection/permission surfaces, if data)
            → infra-agent       (exposure/config surfaces, if infra in scope)
            → verifier-agent    (re-derives each finding from evidence)
            → challenger-agent  (MANDATORY: attacks both directions —
                                 constructs the exploit path for
                                 disputed findings AND the bypass of
                                 claimed mitigations)
            → consistency check → synthesizer-agent
```

Budgets: Planner 4K · Security 6K per surface · Database/Infra 6K ·
Verifier 4K · Challenger 4K · Synthesis 6K.

## Sweep coverage (minimum)

The OWASP Top 10 is mapped to this codebase's actual surfaces. A
category with no surface is recorded as not applicable, with its
reason. Never skipped silently) + trust-boundary walk: every place data crosses a privilege
level, with the validation evidence at that crossing.

## Finding contract

Every finding carries four parts. **Severity**, with the concrete
precondition that makes it exploitable. An **evidence reference** to
file and lines. A **fix** (minimal, the cognitive contract) · **falsified_by** (what evidence would
downgrade it). Claimed mitigations are `known` only with their own
evidence refs — "the gateway probably handles it" is `assumed` and
caps nothing.

## Finding contract enforcement (CB-048)

Before synthesis, the findings are emitted as a structured artifact and
validated by `${CLAUDE_PLUGIN_ROOT}/scripts/security-findings-lint`
against `policies/security-finding-contract.md`. Exit 1 blocks synthesis, and the orchestrator discards and
re-issues. A finding missing severity, surface, proof, fix, or
falsified_by is rejected. A `speculative`/
`assumed` finding with no NAMED dynamic test in `proof` is rejected
(L-1); a missing `authorized_scope` or `surfaces_walked` is rejected;
mis-ordered findings (not impact×exploitability, highest first) are
rejected. VerifierAgent confirms the enforcer ran on this run.

## Output

DECISION (overall posture + the findings that matter, ranked by
Procedure 3) → EVIDENCE → REASONING → RISK (assumption ledger,
surviving counter-scenarios, not-applicable rulings) → CONFIDENCE.
Epistemic labels survive verbatim into the synthesis.

## Execution discipline

`policies/run-discipline.md` binds this run in full — ledger +
digests, conductor-context budget, synchronous stages, path
anchoring, flag lifecycle, context-error recovery.

## Run flag (RunGuardHook wiring)

Arm at execution start:
`${CLAUDE_PLUGIN_ROOT}/scripts/run-flag arm`.
It resolves `$CB_DIR` and verifies the flag landed.
A non-zero exit means the run is not guarded.
Do not proceed as though it were.
Remove it before ANY turn that ends awaiting the user.
Remove it at final synthesis.
Full lifecycle semantics live in `policies/run-discipline.md` §5.
That is the authoritative copy. This section does not restate it.
