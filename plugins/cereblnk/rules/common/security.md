---
name: common-security
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Security

Technology-neutral. Language rules cover unsafe constructs; threat
modelling lives in `skills/practices/owasp-threat-modeling/`.

## Input

- Every external value is hostile until validated at the boundary
- Validate once, at one named place; trust the checked type inside
- Fail fast, with a message that helps the caller and reveals nothing

```text
validated    request bodies, query values, headers
validated    file paths, file names, uploaded content
validated    messages from queues and webhooks
validated    values read back after a user write
```

Avoid: input concatenated into a query or command · a path joined
without normalisation · a value trusted because another service sent
it · re-validation scattered through inner layers.

## Secrets

- Credentials arrive at runtime, from configuration or a secret store
- Required secrets are checked present at startup
- Any secret that may have been exposed is rotated, not assessed

Avoid: a literal key in code · a token in a committed fixture · a
credential deleted in a later build layer · a secret in a log line.

## Permissions

- The narrowest scope that works: one operation, one resource, one duration
- Default deny; every widening is explicit and reasoned

Avoid: an administrative role used for convenience · a wildcard grant
· a permission widened to unblock a failure.

## Failure

- An unavailable check denies; it never allows
- Errors tell the caller what failed, never how the system is built

```text
check fails      deny the operation
check errors     deny, and report the failure
check times out  deny, and report the timeout
```

Avoid: a failed authorization call treated as success · a timeout
defaulting to allow · a stack trace in a response body.

## Evidence

- Sensitive operations record who, what, when, and the outcome
- The record excludes the secret and the personal data itself

Avoid: a permission change with no record · an audit line containing
the credential · records the acting party can delete.

## Before it ships

```text
[ ] no credential in source, fixtures, or build layers
[ ] every external input validated at one boundary
[ ] queries parameterised, commands passed as argument lists
[ ] rendered output escaped for its destination
[ ] authentication and authorization verified on every path
[ ] rate limits present where a caller can repeat
[ ] error responses free of internal detail
```

Found something: stop, fix it before continuing, rotate what was
exposed, then look for the same shape elsewhere.

## Trigger table

| Seen in the diff | Section |
|---|---|
| external input is used | Input |
| a credential appears | Secrets |
| a permission is granted | Permissions |
| a check can fail | Failure |
| a sensitive action occurs | Evidence |
| work is ready to commit | Before it ships |
