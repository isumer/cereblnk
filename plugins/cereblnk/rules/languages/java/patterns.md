---
name: java-patterns
genre: constraint
category: languages
paths:
  - "**/*.java"
---

# Java Patterns

Extends [`common/patterns.md`](../../common/patterns.md). Judgment
lives in `skills/languages/java/`.

## Concurrency

- Name the owner of shared state before adding a lock
- Lock on a private final object, never on a public or reassignable one
- One call decides: a conditional update is atomic, not read-then-write
- A thread-safety claim names its happens-before edge

```java
public Rate lookup(TenantId tenant) {
    return cache.computeIfAbsent(tenant, this::load);
}

public void raiseCeiling(TenantId tenant, Money proposed) {
    ceilings.merge(tenant, proposed, Money::max);
}
```

Avoid: `containsKey` before `put` · `get` before `putIfAbsent` · a lock
added to stop a symptom · thread safety inferred from a type name.

## Resources

- Acquisition and release travel together
- Several resources declare in one statement, one per line
- Cleanup that can itself throw gets its own guard

```java
public void archive(Path source, Path target) throws IOException {
    try (var in = Files.newInputStream(source);
         var out = new GZIPOutputStream(Files.newOutputStream(target))) {
        in.transferTo(out);
    }
}
```

Avoid: a manual close in a cleanup block · release outside a guard ·
a close skipped on the throwing path.

## Equality

- Every field of a key type participates in equality
- `equals` and `hashCode` change together, always
- A key type is immutable

```java
public record OrderKey(String tenant, long orderId) {}
```

Avoid: a mutable key class · a field added to one method only ·
identity equality on a value type.

## Streams

- A stage maps or filters; effects run after the pipeline

```java
public void post(List<Order> orders) {
    var totals = orders.stream()
        .map(Order::total)
        .toList();

    totals.forEach(ledger::record);
}
```

Avoid: an assignment inside a mapping stage · a collection mutated
during traversal · an effect hidden in a comparator.

## Mapping

- Every target field is mapped from a source, or marked `ignore`
- A mapper converts: it does not fetch, validate, or decide
- The hand-written form is a static factory listing every field

```java
@Mapper(componentModel = "spring")
public interface OrderMapper {

    @Mapping(target = "customerName", source = "customer.name")
    @Mapping(target = "totalMinorUnits", source = "total.minorUnits")
    @Mapping(target = "settledAt", ignore = true)
    OrderResponse toResponse(Order order);
}
```

Avoid: a field left unmapped without an explicit ignore · a repository
call inside a mapping method · business rules in an `@AfterMapping`
hook · entity-to-entity mapping that bypasses a constructor invariant.

## Trigger table

| Seen in the diff | Section |
|---|---|
| shared state, or a lock | Concurrency |
| a concurrent collection | Concurrency |
| a resource acquired | Resources |
| a field added to a map key type | Equality |
| a stream stage with an assignment | Streams |
| a type converted to another | Mapping |
