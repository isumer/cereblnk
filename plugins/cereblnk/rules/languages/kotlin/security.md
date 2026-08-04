---
name: kotlin-security
genre: constraint
category: languages
paths:
  - "**/*.kt"
  - "**/*.kts"
  - "**/build.gradle.kts"
---

# Kotlin Security

Extends [`common/security.md`](../../common/security.md).

## Input

- Query values bind as parameters; commands take argument lists
- External payloads are validated at the boundary into typed objects

```kotlin
val order = json.decodeFromString<OrderRequest>(payload)
validator.check(order)
return order.toDomain()
```

```kotlin
jdbcTemplate.queryForObject(
    "select total from orders where tenant = ? and id = ?",
    arrayOf(tenant, orderId),
    Long::class.java,
)
```

Avoid: a string template building a query · a payload deserialized
into a polymorphic type from user input.

## Secrets

- Credentials arrive from configuration at runtime, checked at startup

```kotlin
val apiKey = requireNotNull(env["PAYMENT_API_KEY"]) {
    "PAYMENT_API_KEY is not configured"
}
```

Avoid: a key in source · a token in a committed fixture · a credential
in a log line.

## Coroutine failures

- Cancellation is re-thrown; only real failures are handled
- A failure crossing a scope carries its cause

```kotlin
try {
    gateway.capture(order)
} catch (cancellation: CancellationException) {
    throw cancellation
} catch (failure: GatewayException) {
    throw SettlementFailedException(order.id, failure)
}
```

Avoid: a catch of the broadest type inside a coroutine · a failure
suppressed by a supervisor with no report.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a query or payload is handled | Input |
| a credential appears | Secrets |
| a coroutine catches a failure | Coroutine failures |
