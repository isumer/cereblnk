---
name: hibernate-jpa-security
genre: constraint
category: frameworks
paths:
  - "**/repository/**/*.java"
  - "**/entity/**/*.java"
  - "**/*Query*.java"
---

# Hibernate/JPA Security

Judgment lives in `skills/frameworks/hibernate-jpa/`.
The wider surface lives in [`../../security/controls.md`](../../security/controls.md).

## Query construction

- Every caller value enters a query as a bound parameter
- Dynamic fragments are chosen from a fixed set the code owns

```java
@Query("select p from Payment p where p.reference = :reference")
Optional<Payment> findByReference(@Param("reference") String reference);
```

Avoid: a query assembled by string concatenation. A sort or column name
taken from a request without a whitelist.

## Tenancy and ownership

- Ownership is a condition in the query, not a check after loading
- A repository method that can cross a tenant states the tenant

```java
@Query("""
    select p from Payment p
    where p.id = :id and p.tenantId = :tenantId
    """)
Optional<Payment> findOwned(@Param("id") Long id,
                            @Param("tenantId") String tenantId);
```

Avoid: loading by identifier and comparing the owner afterwards. A
finder that returns another tenant's row before it is rejected.

## Exposure

- Entities do not leave the service layer
- Projections carry the fields a caller is allowed to see

```java
interface PaymentSummary {
    String getReference();
    BigDecimal getAmount();
    Instant getCapturedAt();
}

@Query("select p from Payment p where p.orderId = :orderId")
List<PaymentSummary> findSummaries(@Param("orderId") Long orderId);
```

Avoid: an entity serialised straight to a response. A projection added
without deciding who reads it.

## Mass assignment

- Updates copy named fields, one at a time
- Identifiers and audit columns are never written from input

```java
Payment payment = repository.findOwned(id, tenantId).orElseThrow();

payment.setAmount(request.amount());
payment.setNote(request.note());
payment.setUpdatedBy(currentUser());
```

Avoid: a mapper copying every matching property. A request object bound
directly onto a managed entity.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a JPQL or native query | Query construction |
| a finder on a shared table | Tenancy and ownership |
| an entity in a controller signature | Exposure |
| an update from a request object | Mass assignment |
