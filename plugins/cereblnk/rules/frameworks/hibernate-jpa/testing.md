---
name: hibernate-jpa-testing
genre: constraint
category: frameworks
paths:
  - "**/*Test.java"
  - "**/src/test/**/*.java"
---

# Hibernate and JPA Testing

Extends [`frameworks/spring-boot/testing.md`](../spring-boot/testing.md).

## The real engine

- Mapping and queries run against the production engine and version
- A substitute engine proves syntax, never behavior

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = NONE)
@Testcontainers
class OrderRepositoryTest {

    @Container
    static final PostgreSQLContainer<?> DATABASE =
            new PostgreSQLContainer<>("postgres:16");
}
```

Avoid: an in-memory engine standing in for production · a mapping
proven only by a passing startup.

## Flush and clear

- A write test flushes and clears before asserting what was stored
- Otherwise the assertion reads the context, not the database

```java
repository.save(order);
entityManager.flush();
entityManager.clear();

var stored = repository.findById(order.getId()).orElseThrow();
```

Avoid: an assertion satisfied by the first-level cache · a test that
passes without the write reaching the database.

## Query count

- A test asserts the number of statements a call issues

Avoid: a lazy-loading problem discovered under production load.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a mapping or query is tested | The real engine |
| a write is asserted | Flush and clear |
| a repository method is added | Query count |
