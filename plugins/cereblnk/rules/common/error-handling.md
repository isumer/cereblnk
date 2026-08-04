---
name: common-error-handling
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Error Handling

Technology-neutral. Language rules refine the mechanism.

## The three choices

- Every caught failure is propagated, translated, or handled
- The decision is written at the catch site, in one line

Avoid: a catch with only a log statement · an empty catch · a default
returned that the caller cannot distinguish from success.

## Crossing a boundary

- A failure changes vocabulary at each layer, and keeps its cause

```text
storage    ConnectionTimeout
domain     OrderLookupUnavailable
api        503, body: { code: "order_lookup_unavailable" }
```

Avoid: a storage exception reaching an API response · a domain layer
catching a transport type · a cause discarded on translation.

## Retries

- Bounded, delayed, and only on idempotent operations
- On exhaustion, fail with the last cause attached

```text
attempts    a stated ceiling
delay       exponential, with jitter
scope       idempotent operations only
```

Avoid: unbounded retry · retry without delay · retry of a
non-idempotent write · a final failure swallowed.

## What the caller learns

- A stable code, a readable summary, and whether retrying may help
- Stack traces, queries, host names and paths stay inside

Avoid: an internal message forwarded verbatim · a code that changes
between releases.

## What is not handled

- Handle failures found in evidence, not failures imagined

Avoid: a branch for a state the type system excludes · a null check on
a value that cannot be null · a catch for an exception the call cannot
raise.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a failure is caught | The three choices |
| a failure crosses a layer | Crossing a boundary |
| a failure is retried | Retries |
| a failure reaches a caller | What the caller learns |
| a defensive branch appears | What is not handled |
