---
name: java-coding-style
genre: constraint
category: languages
language_level: 17
paths:
  - "**/*.java"
---

# Java Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/java/`. `[N+]` marks the release a form requires.

## Layout

- Enforcement by **google-java-format**, or **Checkstyle** with the
  Google or Sun configuration — one tool, one config, both committed
- One public top-level type per file, named for the file
- Indent 2 or 4 spaces: match the project's existing standard, never
  mix them in one repository
- Continuation lines indent one further level, one operation per line
- Member order: constants, fields, constructors, public, protected, private
- Pascal case types · camel case members · screaming snake constants ·
  packages lowercase, reverse domain

Examples in this file use four spaces.

Avoid: two public types in one file · a private helper between public
methods · an underscore-prefixed field · two indent widths in one
repository · layout settled in review rather than by the formatter.

## Immutability

- Fields `final` unless mutation is owned and named
- Value types validate in the constructor and compare by content
- Public methods return copies: `List.copyOf`, `Map.copyOf`, `Set.copyOf`
- A change returns a new instance rather than mutating this one

```java
// [16+]
public record Money(BigDecimal amount, Currency currency) {
    public Money {
        Objects.requireNonNull(amount);
        Objects.requireNonNull(currency);
    }
}

public final class Order {

    private final List<LineItem> items;

    public List<LineItem> items() {
        return List.copyOf(items);
    }

    public Order with(LineItem added) {
        var next = new ArrayList<>(items);
        next.add(added);
        return new Order(id, next);
    }
}
```

Below 16: a final class with an explicit constructor, `equals` and
`hashCode`. `BigDecimal` compares with `compareTo`, so scale does not
decide equality.

Avoid: setters on a value type · an internal collection returned
directly · one of equals or hashCode overridden alone · a value type
holding a service.

## Modern constructs

- Records for value types and DTOs `[16+]`
- Text blocks for SQL, JSON and templates `[15+]`
- Sealed hierarchies for closed result sets `[17+]`
- Pattern-matching `instanceof`, no separate cast `[16+]`
- Arrow switch expressions `[14+]`; exhaustive over sealed types `[21+]`

```java
public sealed interface SettlementResult
        permits Captured, Declined, Deferred {

    record Captured(TransactionId transactionId, Money amount)
            implements SettlementResult {}

    record Declined(DeclineCode code, String detail)
            implements SettlementResult {}

    record Deferred(Instant retryAfter) implements SettlementResult {}
}

String describe(SettlementResult result) {
    return switch (result) {
        case Captured c -> "captured " + c.amount();
        case Declined d -> "declined " + d.code();
        case Deferred d -> "retry after " + d.retryAfter();
    };
}

private static final String OVERDUE_QUERY = """
        select id, tenant, total
        from invoice
        where due_date < ?
          and settled_at is null
        """;

if (event instanceof PaymentCaptured captured) {
    ledger.record(captured.amount());
}
```

Below 17: an abstract base with a package-private constructor, plus a
visitor or a discriminator each subtype carries.

Avoid: a status enum beside nullable detail fields · a boolean pair
encoding three states · a default branch hiding an unhandled case · a
cast on the line after a type check · a query concatenated with plus
signs.

## Optional

- Return `Optional<T>` from finders that may find nothing
- Consume with `map`, `flatMap`, `orElseThrow`
- Never a field, never a parameter

```java
public CustomerResponse fetch(CustomerId id) {
    return repository.findById(id)
        .map(CustomerResponse::from)
        .orElseThrow(() -> new CustomerNotFoundException(id));
}
```

Avoid: `get()` without a presence check · `isPresent()` followed by
`get()` · null returned from a method that could return a collection.

## Streams

- One operation per line; three or four operations at most
- Method references where they read: `.map(Order::total)`
- No side effects inside the pipeline; apply them after
- Branching logic reads better as a loop

```java
public List<Invoice> overdue(LocalDate today) {
    return invoices.stream()
        .filter(invoice -> invoice.dueDate().isBefore(today))
        .filter(invoice -> !invoice.isSettled())
        .toList();
}
```

Avoid: two chained calls sharing a line · a nested stream inside a map
stage · a collector rebuilt inline for a common shape · a side effect
in a filter.

## Locals

- `var` when the right side names the type
- An explicit type when a factory or a chain hides it

```java
var order = new Order(id, customer);
var totals = new HashMap<Currency, BigDecimal>();

BigDecimal balance = ledger.balanceFor(customer);
List<Invoice> pending = repository.findPending(customer);
```

Avoid: `var` on a factory call · `var` on a chained result · an
explicit type restating the constructor beside it.

## Errors

- Domain failures are unchecked, extending `RuntimeException`
- The message names the domain and the failing identifier
- The cause travels with every rethrow
- A broad catch belongs only at a top-level handler

```java
public class SettlementFailedException extends RuntimeException {

    public SettlementFailedException(OrderId id, Throwable cause) {
        super("Settlement failed: id=" + id, cause);
    }
}
```

Avoid: a checked exception for a domain rule · a message with no
identifier · a cause dropped on rethrow · a catch with only a log
line.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new type, file or member | Layout |
| a field, or a value type | Immutability |
| a closed set of outcomes | Modern constructs |
| a multi-line string literal | Modern constructs |
| a method that may find nothing | Optional |
| a stream pipeline | Streams |
| a local declaration | Locals |
| an exception type, or a catch | Errors |
