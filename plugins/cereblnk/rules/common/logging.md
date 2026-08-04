---
name: common-logging
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Logging

Technology-neutral. A log line is written for the person reading it
during an incident.

## Structure

- Fields, not a sentence to be parsed later
- One line carries the whole failure: what, on what, why, retryable

```text
event=payment.capture.failed
payment_id=8821
attempt=3
cause=insufficient_funds
retryable=false
```

Avoid: interpolated sentences · values concatenated into a message ·
field names differing between call sites · a cause logged apart from
its context.

## Contents

- Identifiers yes; credentials and personal data never
- Redaction is applied before the value reaches the logger

```text
logged      user_id, tenant, request_id, resource_id
redacted    tokens, passwords, keys, card numbers
absent      request bodies, headers, personal detail
```

Avoid: a token at debug level · a body dumped on error · an email
address used as the log identifier.

## Levels

- The level says what the reader should do

```text
error   someone must act now
warn    someone should look today
info    a state change worth reconstructing later
debug   off in production
```

Avoid: error for an expected condition · info for per-iteration
detail · every level treated as one channel.

## Volume

- Log once per operation: entry, outcome, and identifiers
- Per-item detail is sampled at a stated rate, or not logged

Avoid: logging inside a tight loop · a line per record in a batch ·
logging that outpaces the work described.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a log statement is added | Structure |
| a log carries request data | Contents |
| a level is chosen | Levels |
| a log sits in a loop or hot path | Volume |
