---
name: security-controls
genre: constraint
category: security
density: neutral
applies_when: a security gate, scan, or finding is handled
---

# Controls

Extends [`common/security.md`](../common/security.md). Judgment lives
in `skills/practices/devsecops/`.

## Proof, not configuration

- A control is proven by planting the violation it claims to catch
- A gate that has never blocked anything is untested

```text
planted     a known-bad dependency, a test credential, a bad config
observed    the build fails, and the message names the finding
recorded    the date of the last proof
```

Avoid: a scanner configured and never triggered. A tool count reported
as maturity. A control whose output nobody reads.

## Ownership

- Every control names an owner and a triage deadline
- Every exception carries an expiry date

Avoid: findings ageing in a dashboard nobody owns. A permanent
temporary exception. A gate lowered to unblock a release.

## Response

- A confirmed issue stops the work, is fixed, and the exposure is rotated
- The same shape is then searched for across the codebase

Avoid: a finding fixed in one place and left in three. An exposure
closed without rotation. A postmortem that names no systemic cause.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a control or gate is added | Proof, not configuration |
| a finding is produced | Ownership |
| an issue is confirmed | Response |
