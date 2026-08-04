---
name: kotlin-coding-style
genre: constraint
category: languages
paths:
  - "**/*.kt"
  - "**/*.kts"
---

# Kotlin Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/kotlin/`.

## Layout

- Style enforced by a linter configured in the repo, official code style on
- Camel case for functions and properties, Pascal case for types
- Interfaces named for behavior, never prefixed with a letter

Avoid: a style argument in review · a per-file suppression · an
interface named by convention rather than capability.

## Immutability

- `val` by default; `var` only where mutation is the point
- Value types are data classes; public APIs expose read-only collections
- State updates copy rather than mutate

```kotlin
data class Order(val id: OrderId, val items: List<LineItem>)

fun Order.with(item: LineItem): Order =
    copy(items = items + item)
```

Avoid: a `var` property on a shared object · a mutable list returned
from a public function · a data class with a mutable field.

## Null safety

- Nullability is modelled, not asserted
- Values crossing from Java are checked at the boundary

```kotlin
fun find(id: CustomerId): Customer? = index[id]

fun fetch(id: CustomerId): CustomerResponse =
    find(id)?.let(CustomerResponse::from)
        ?: throw CustomerNotFoundException(id)
```

Avoid: the not-null assertion used to clear an error · a platform type
trusted without a check · a lateinit standing in for optionality.

## Closed sets

- A finite set of outcomes is a sealed hierarchy, matched exhaustively

```kotlin
sealed interface SettlementResult {
    data class Captured(val amount: Money) : SettlementResult
    data class Declined(val code: DeclineCode) : SettlementResult
    data object Deferred : SettlementResult
}

fun describe(result: SettlementResult): String = when (result) {
    is SettlementResult.Captured -> "captured ${result.amount}"
    is SettlementResult.Declined -> "declined ${result.code}"
    SettlementResult.Deferred -> "deferred"
}
```

Avoid: an enum beside nullable detail fields · an `else` branch hiding
an unhandled case.

## Coroutines

- Every launch names its scope and its lifecycle owner
- The dispatcher is chosen deliberately
- Cancellation is re-thrown, never swallowed

Avoid: a launch on a scope with no owner · blocking work on the main
dispatcher · a broad catch that swallows cancellation.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a declaration or an interface name | Layout |
| a property or a collection | Immutability |
| a nullable value, or Java interop | Null safety |
| a closed set of outcomes | Closed sets |
| a coroutine is launched | Coroutines |
