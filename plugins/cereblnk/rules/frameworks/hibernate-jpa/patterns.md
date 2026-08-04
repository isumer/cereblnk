---
name: hibernate-jpa-patterns
genre: constraint
category: frameworks
paths:
  - "**/entity/**/*.java"
  - "**/domain/**/*.java"
  - "**/repository/**/*.java"
  - "**/*Repository.java"
  - "**/*Entity.java"
---

# Hibernate and JPA Patterns

Extends [`languages/java/patterns.md`](../../languages/java/patterns.md).
Judgment lives in `skills/frameworks/hibernate-jpa/`.

## Fetching

- Associations are lazy by default; a query states what it needs
- The number of queries a call issues is known before it ships

```java
@Query("""
        select o from Order o
        join fetch o.items
        where o.tenant = :tenant and o.settledAt is null
        """)
List<Order> findUnsettledWithItems(@Param("tenant") String tenant);
```

Avoid: an eager association declared for convenience · a collection
traversed after the session closed · a loop issuing one query per row.

## Identity

- One assignment strategy, stated on the entity
- Equality uses a business key, or is left to identity consistently

```java
@Entity
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NaturalId
    private String reference;
}
```

Avoid: equality on a generated identifier before assignment · an
entity placed in a set before persisting · a mutable field in
equality.

## Session boundaries

- The unit of work opens and closes in the service
- An entity never travels beyond it; a projection does

```java
@Transactional(readOnly = true)
public OrderSummary summarise(OrderId id) {
    return orders.findSummaryById(id.value())
        .orElseThrow(() -> new OrderNotFoundException(id));
}
```

Avoid: a lazy field touched in a controller · an entity serialized to a
response · a session opened in a view layer.

## Writes

- A write states its flush point and its lock intent
- Bulk changes go through one statement, not a loop of saves

```java
@Modifying(clearAutomatically = true)
@Query("update Invoice i set i.status = 'OVERDUE' where i.dueDate < :cutoff")
int markOverdue(@Param("cutoff") LocalDate cutoff);
```

Avoid: a save inside a loop over thousands of rows · a modifying query
that leaves the context stale · optimistic locking added after the
first conflict.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an association or a query | Fetching |
| an entity identifier or equality | Identity |
| an entity crosses a layer | Session boundaries |
| rows are written or updated | Writes |
