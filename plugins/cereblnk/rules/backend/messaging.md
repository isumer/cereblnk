---
name: backend-messaging
genre: constraint
category: backend
density: neutral
paths:
  - "**/*Consumer.*"
  - "**/*Producer.*"
  - "**/messaging/**/*"
  - "**/events/**/*"
---

# Messaging

Extends [`architecture/integration.md`](../architecture/integration.md).

## Delivery

- Every consumer is idempotent; redelivery is normal operation
- Ordering holds within a partition key, and nowhere else

```text
assume    at least once
assume    out of order across keys
prove     idempotence by delivering the same message twice
```

Avoid: exactly-once assumed from a configuration flag. Ordering
assumed across keys. A consumer whose second run doubles an effect.

## Failure

- Retries are bounded; a failing message moves to a dead-letter path
- A dead-letter has an owner and a review cadence

Avoid: infinite retry blocking a partition. A dead-letter queue nobody
reads. A poison message dropped silently.

## Schema

- Message schemas evolve additively; both versions travel in flight
- A consumer ignores fields it does not know

Avoid: a field altered rather than added. A producer deployed ahead of
its consumers. A schema change discovered by a parse failure.

## Observability

- Consumer lag is a first-class signal, alerted on
- A quiet topic and a broken consumer look identical from outside

Avoid: a consumption failure found by a customer. A topic with no lag
alert. A retry count nobody records.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a message is produced or consumed | Delivery |
| a consumer can fail | Failure |
| a message shape changes | Schema |
| a topic or consumer is added | Observability |
