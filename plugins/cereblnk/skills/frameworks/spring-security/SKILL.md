---
name: spring-security
description: Filter-chain order, JWT validation, session and token discipline. Use for Spring Security work. SecurityAgent decides. Constraints in rules/frameworks/spring-security/.
---

# Spring Security Skill

## 1. Identity
name: spring-security · domain: frameworks
requires: java · spring-boot
complements: owasp-threat-modeling · devsecops
escalate_to: security-agent (every authz decision — this skill informs, the agent decides)

## 2. Mission
Trace the request through the actual filter chain to the sink. Order
decides access; read the order.

## 3. Philosophy

**Reading requests.** "Add auth to this endpoint" hides two questions.
Where in the chain? What matches this path first? Order decides access.

**Where risk lives.** JWT signature and algorithm. Reusable reset
tokens. Weak password hashing. Session fixation. Object-level authz on
the wrong object.

**Verification here.** Trace the untrusted input through the real
filter chain. A control that "should" apply is assumed. It holds only
when the chain shows it on THIS path. Refresh and error paths included.

**False-competence traps.** "Properly validated" without reading the
validator. The default trusted after a two-commit override. alg:none
unchecked. findById without the tenant.

**Instincts.** Fail closed. Explicit per-endpoint rules beat pattern
cleverness. When session and token models blur, pick one. Make the
other impossible.

## 4. Decision Strategy — the paths

**A JWT is validated**
→ Verify signature and algorithm. Reject alg:none and RS256-as-HS256.
  Validate exp, iss, aud on every path.
→ Signing keys out of the repo, rotated. Never trust authz from a
  client-editable claim.

**A reset or verification token is issued**
→ Single-use, short-lived, unguessable, never logged. A reusable
  reset token is delayed account takeover.

**Passwords are stored**
→ Slow adaptive KDF, salted. MD5, SHA-1, or unsalted is a finding on
  sight.

**A session is managed**
→ Regenerate id on login or privilege change. HttpOnly, Secure,
  SameSite. Invalidate server-side on logout.

**An object is fetched by id**
→ findByIdAndTenant, not findById. The per-object ownership check is
  the IDOR defense. Its absence is a known finding.

**A security rule is added to the chain**
→ Read the whole order first. A broader matcher above yours wins.
  Escalate to security-agent at level 3.

## 5. Inputs
Security config and filter chain. JWT validation code. Session config.
Password encoder. The object-fetch paths in scope.

## 6. Outputs
ACP Response Block only. Every finding carries severity, an evidence
reference, and its exploit precondition. Absence claims name the paths
checked. SecurityAgent decides; this skill informs.

## 7. Quality Gates
- Every JWT path verifies signature, algorithm, and claims.
- Every object fetch on a shared type carries the ownership check.
- Every chain change cites the full matcher order.

## 8. Failure Modes
- A broad matcher above a specific rule silently opening access.
- alg:none or confusion accepted by a permissive validator.
- Reset token reusable, enabling delayed takeover.
- findById exposing another tenant's object.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/spring-security/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | JWT parsed without algorithm pinning | alg confusion |
| 2 | reset/verify token reusable or long-lived | takeover |
| 3 | MD5/SHA-1/unsalted password storage | weak hashing |
| 4 | session id not regenerated on login | fixation |
| 5 | findById on a shared type without tenant | IDOR |
| 6 | new matcher without chain-order citation | order bypass |

## 9. Worked Example
Claim: "the admin route is protected, it has hasRole ADMIN."
Evidence: a broader `/api/**` permitAll matcher sits above it in the
chain. Path fires: the first match wins, the admin rule never runs.
Verdict: refuted (Known: chain order, file#L). Fix: order the specific
rule first; a test asserts 403 for a non-admin. SecurityAgent decides.
