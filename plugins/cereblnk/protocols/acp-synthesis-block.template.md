# ACP Synthesis Block — Runtime → User

The only block a user ever sees. Ordering is fixed and the
SynthesizerAgent must run the five-question self-test
before emitting it.
Assumed and speculative content appears in RISK, never silently in DECISION.

---

## Fully worked example

**DECISION**

Do not merge PR #212 as-is: the JWT change introduces a token-expiry
bypass on the refresh path. Fix: restore the `validateExpiry()` call on
the refresh branch, then re-run this review.

**EVIDENCE**

- Known — `AuthFilter` no longer calls `validateExpiry()` on the refresh
  path (CTX-114#L42-58). Independently confirmed by the Verifier.
- Derived — expired tokens on the refresh path are accepted (from the
  fact above).
- Estimated — the exploit window is roughly the configured skew
  tolerance, ~30s (CTX-115#L12).

**REASONING**

The refresh branch returns before any expiry validation is reachable, so
any token — regardless of expiry — passes the filter on that path. The
skew configuration bounds, but does not eliminate, the exploit window.

**RISK**

- Assumption ledger: no upstream gateway re-validates expiry (Assumed,
  unverified). If the gateway does validate, severity drops from high
  to low.
- Falsifier: gateway JWT configuration showing expiry re-validation.
- Watch item: check the gateway config first if this finding is disputed.

**CONFIDENCE**

0.78 — high on the directly observed facts; discounted for the single
unverified gateway assumption. Open unknown: gateway-side validation.
