---
name: hibernate-jpa-performance
genre: constraint
category: frameworks
paths:
  - "**/entity/**/*.java"
  - "**/domain/**/*.java"
  - "**/repository/**/*.java"
  - "**/*Repository.java"
  - "**/*Entity.java"
---

# Hibernate and JPA Performance

Extends [`common/performance.md`](../../common/performance.md) and
[`data/query-optimization`](../../../skills/data/query-optimization/SKILL.md).

## Query count

- Every repository call has a known query count, asserted in a test
- A collection loaded per parent row is the finding, not the symptom

```java
@Test
void loadsOrdersInOneQuery() {
    var statistics = sessionFactory.getStatistics();
    statistics.clear();

    orders.findUnsettledWithItems("acme");

    assertThat(statistics.getPrepareStatementCount()).isEqualTo(1);
}
```

Avoid: a query count discovered in production · lazy loading inside a
mapping loop · a fetch join added without checking the row multiplier.

## Result size

- Every list query is paginated, from the first release
- A projection returns the columns used, not the whole entity

```java
Page<OrderSummary> findByTenant(String tenant, Pageable pageable);

@Query("select new OrderSummary(o.id, o.total) from Order o where o.id = :id")
Optional<OrderSummary> findSummaryById(@Param("id") Long id);
```

Avoid: a repository method returning every row · an entity loaded to
read one field · a paged query with no stable sort.

## Caching

- A cache states what invalidates it before it is enabled
- Second-level caching applies to data that changes rarely

```java
@Cacheable(region = "currency")
@Entity
public class Currency { ... }
```

Avoid: caching enabled to hide a query problem · a cached entity
mutated elsewhere · a cache with no measured before and after.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a repository method is added | Query count |
| a list is returned | Result size |
| caching is enabled | Caching |
