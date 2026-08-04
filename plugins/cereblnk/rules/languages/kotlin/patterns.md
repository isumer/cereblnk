---
name: kotlin-patterns
genre: constraint
category: languages
paths:
  - "**/*.kt"
  - "**/*.kts"
---

# Kotlin Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Construction

- A value validates in its initialiser and is usable immediately

```kotlin
data class Money(val minorUnits: Long, val currency: Currency) {
    init {
        require(minorUnits >= 0) { "minorUnits must not be negative" }
    }
}
```

Avoid: a builder for a three-field type · validation in a method the
caller must remember · a factory returning a half-built object.

## Extensions

- An extension adds a use-site convenience, never domain behavior
- Domain rules live on the type that owns them

```kotlin
fun LocalDate.isWithin(window: SettlementWindow): Boolean =
    !isBefore(window.opens) && !isAfter(window.closes)
```

Avoid: an extension carrying a business rule · an extension on a type
from another module · a chain of extensions replacing a service.

## Scope functions

- One scope function per expression, chosen for what it returns

```kotlin
val response = repository.findById(id)
    ?.let(CustomerResponse::from)
    ?: throw CustomerNotFoundException(id)
```

Avoid: nested scope functions on the same receiver · a scope function
whose receiver is ambiguous at a glance.

## Boundaries

- Storage sits behind an interface returning domain types
- Framework annotations stay out of domain classes

```kotlin
interface OrderStore {
    fun byId(id: OrderId): Order?
    fun save(order: Order)
}

class JpaOrderStore(private val orders: OrderJpaRepository) : OrderStore {
    override fun byId(id: OrderId): Order? =
        orders.findById(id.value).orElse(null)?.toDomain()
}
```

Avoid: an entity used as the domain model · a repository type leaking
into a view · a domain class annotated for persistence.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a value type is written | Construction |
| an extension function is added | Extensions |
| a scope function appears | Scope functions |
| storage or transport is touched | Boundaries |
