---
name: architecture-api-design
genre: constraint
category: architecture
density: neutral
applies_when: a contract between systems is created or changed
---

# API Design

Extends [`common/patterns.md`](../common/patterns.md). Judgment lives
in `skills/practices/api-design/`.

## Compatibility

- A change is classified before it ships: additive, tolerant, breaking
- A meaning change under an unchanged shape is breaking

```text
additive    a new optional field, a new endpoint
tolerant    a field consumers already ignore
breaking    a removal, a tightened rule, a changed meaning
```

Avoid: compatibility claimed with no consumer list. Validation
tightened without checking who sends what. A value removed from an
enumeration consumers branch on.

## Contracts

- Every collection is paginated from its first release
- Errors carry a stable code, and the shape is the same everywhere
- A retryable operation takes a client-supplied idempotency key

Avoid: an endpoint returning everything. An error body from a
framework default. A duplicate charge from a retry the design ignored.

## Versioning

- A version encodes a stated promise, not a number
- The previous version's retirement date is published with the new one

Avoid: a version added instead of a compatibility policy. Two versions
maintained with no removal plan. A breaking change shipped inside a
patch.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a field or rule changes | Compatibility |
| an endpoint is defined | Contracts |
| a version is introduced | Versioning |
