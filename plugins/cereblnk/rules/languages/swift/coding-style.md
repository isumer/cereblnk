---
name: swift-coding-style
genre: constraint
category: languages
paths:
  - "**/*.swift"
  - "**/Package.swift"
---

# Swift Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/swift/`.

## Layout

- Formatting and lint enforced by tools configured in the repo
- Names read at the point of use; needless words omitted
- Constants are static members, not globals

Avoid: a style argument in review. A method named for its type rather
than its role. A global constant where a namespace fits.

## Value semantics

- `let` unless mutation is required; `struct` unless identity is
- Reference types are chosen for identity or shared lifetime, and say so

```swift
struct Money: Equatable {
    let minorUnits: Int
    let currency: Currency

    func adding(_ other: Money) -> Money {
        precondition(currency == other.currency)
        return Money(minorUnits: minorUnits + other.minorUnits,
                     currency: currency)
    }
}
```

Avoid: a class used for a value. A `var` property on a shared object. A
mutating method where returning a new value reads better.

## Optionals

- Absence is modelled in the type, then unwrapped deliberately
- Force unwrapping states why it cannot fail

```swift
guard let customer = repository.find(id) else {
    throw CustomerError.notFound(id)
}
```

Avoid: a force unwrap used to satisfy the compiler. An implicitly
unwrapped optional outside interface binding. A default that hides an
absent value the caller needed.

## Errors

- A failing operation throws a typed error the caller can match on
- The cause travels with a rethrow

```swift
enum SettlementError: Error {
    case windowClosed(OrderId)
    case gatewayUnavailable(underlying: Error)
}

func settle(_ id: OrderId) throws -> Receipt {
    do {
        return try gateway.capture(id)
    } catch {
        throw SettlementError.gatewayUnavailable(underlying: error)
    }
}
```

Avoid: a generic error carrying only a message. A `try?` that discards
the reason. A failure represented as an optional return.

## Concurrency

- State shared across tasks is isolated by an actor or made immutable
- Every task has an owner and a cancellation path

```swift
actor RateWindow {
    private var count = 0

    func record() { count += 1 }
}
```

Avoid: shared mutable state reached from two tasks. A task with no
handle. A lock held across a suspension point.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a declaration or a name | Layout |
| a type or a property | Value semantics |
| an optional is unwrapped | Optionals |
| an operation can fail | Errors |
| a task or shared state | Concurrency |
