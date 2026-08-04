---
name: hibernate-jpa-coding-style
genre: constraint
category: frameworks
paths:
  - "**/entity/**/*.java"
  - "**/domain/**/*.java"
  - "**/repository/**/*.java"
---

# Hibernate/JPA Coding Style

Judgment lives in `skills/frameworks/hibernate-jpa/`.
Patterns live in [`patterns.md`](patterns.md).

## Entity shape

- Field access, one mapping style per codebase
- Every association declares its fetch type explicitly

```java
@Entity
@Table(name = "payment")
class Payment {

    @Id
    @GeneratedValue(strategy = IDENTITY)
    private Long id;

    @ManyToOne(fetch = LAZY)
    private Order order;
}
```

Avoid: a mapping that inherits the default fetch type silently. Mixed
field and property access in one hierarchy.

## Identity

- `equals` and `hashCode` use a business key, or neither is written
- A generated identifier is never part of `hashCode`

```java
@Override
public boolean equals(Object other) {
    return other instanceof Payment p
        && reference.equals(p.reference);
}

@Override
public int hashCode() {
    return reference.hashCode();
}
```

Avoid: identity built on a value the database assigns later. An entity
in a hash set before it is persisted.

## Repository surface

- One method name states one query intent
- Projections are declared types, not object arrays

```java
interface PaymentRepository extends Repository<Payment, Long> {

    Optional<Payment> findByReference(String reference);

    List<PaymentSummary> findSummaryByOrderId(Long orderId);
}
```

Avoid: a method name that hides a second condition. A query returning
rows the caller must index by position.

## Lifecycle

- `toString` covers owned columns only
- Callbacks stay free of repository and service calls

```java
@Override
public String toString() {
    return "Payment[" + reference + ", " + amount + "]";
}
```

Avoid: a `toString` that walks an association. A lifecycle callback
that loads another entity.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new entity or association | Entity shape |
| equals, hashCode, or a set of entities | Identity |
| a repository method | Repository surface |
| toString or an @PrePersist callback | Lifecycle |
