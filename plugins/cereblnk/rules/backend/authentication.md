---
name: backend-authentication
genre: constraint
category: backend
density: neutral
paths:
  - "**/auth/**/*"
  - "**/*Auth*.*"
  - "**/security/**/*"
---

# Authentication

Extends [`common/security.md`](../common/security.md).

## Establishing identity

- Every request's identity comes from a verified credential
- Verification checks issuer, audience, expiry and signature — all four

Avoid: a signature checked while the issuer is not. An expiry check
disabled for a test that stayed. Identity taken from a header a proxy
could set.

## Credentials

- Passwords are stored with an adaptive hash and a configured cost
- Tokens are short-lived; refresh is revocable and single-use

Avoid: a fast hash for a password. A token with no expiry. A refresh
token reusable after it was exchanged.

## Sessions

- A stateless surface creates no session
- A session is invalidated on logout, on password change, and on
  suspected compromise

Avoid: a session that survives a password change. A logout that clears
only the client. A fixed session identifier issued before login.

## Failure

- A failed authentication reveals nothing about which part failed
- Repeated failures are rate-limited per account and per source

Avoid: a message distinguishing unknown user from wrong password. An
unlimited retry surface. A lockout an attacker can trigger for anyone.

## Trigger table

| Seen in the diff | Section |
|---|---|
| identity is established | Establishing identity |
| a credential is stored or issued | Credentials |
| a session is created or ended | Sessions |
| authentication can fail | Failure |
