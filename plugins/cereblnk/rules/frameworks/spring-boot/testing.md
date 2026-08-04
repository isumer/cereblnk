---
name: spring-boot-testing
genre: constraint
category: frameworks
paths:
  - "**/*Test.java"
  - "**/*Tests.java"
  - "**/src/test/**/*.java"
---

# Spring Boot Testing

Extends [`languages/java/testing.md`](../../languages/java/testing.md).

## Slice before context

- A test loads the narrowest slice that proves the behavior
- A full context is loaded only when the wiring itself is the subject

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired MockMvc mvc;
    @MockitoBean SettlementService settlement;
}
```

Avoid: a full application context for a mapping test · a context
configuration that differs per test class, defeating the cache · a
sliced test that autowires the whole service graph.

## Real dependencies where it matters

- Persistence is exercised against the production engine
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

Avoid: an in-memory database standing in for the production one · a
repository test that mocks the repository.

## Configuration under test

- Test properties are declared, not inherited by accident
- A profile used in tests exists in the repository

```java
@TestPropertySource(properties = "settlement.maximum-attempts=2")
```

Avoid: a test passing because of a developer's local configuration · a
property overridden in a base class nobody reads.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a test loads a context | Slice before context |
| persistence is tested | Real dependencies where it matters |
| test properties or profiles change | Configuration under test |
