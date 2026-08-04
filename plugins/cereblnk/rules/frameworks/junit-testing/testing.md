---
name: junit-testing-testing
genre: constraint
category: frameworks
paths:
  - "**/src/test/java/**/*.java"
  - "**/*Test.java"
  - "**/*Tests.java"
---

# JUnit Testing

Extends [`languages/java/testing.md`](../../languages/java/testing.md).
Judgment lives in `skills/frameworks/junit-testing/`.

## Lifecycle

- Per-test state is created per test; shared state is immutable
- A lifecycle method sets up what every test in the class needs

```java
class SettlementTest {

    private Ledger ledger;

    @BeforeEach
    void setUp() {
        ledger = new InMemoryLedger();
    }
}
```

Avoid: a static mutable field shared across tests. Setup configuring
collaborators no test uses. Order dependence from a class fixture.

## Assertions

- One assertion library across the repository
- A grouped assertion reports every failure, not just the first

```java
assertAll(
    () -> assertThat(receipt.status()).isEqualTo(CAPTURED),
    () -> assertThat(receipt.amount()).isEqualTo(Money.ofMinor(1200)));
```

Avoid: two assertion styles in one file. A boolean assertion whose
failure says nothing. An assertion on a message formatting will change.

## Parameterised and nested

- A parameter varies the input; a nested class groups one scenario

```java
@Nested
class WhenTheWindowHasClosed {

    @ParameterizedTest
    @ValueSource(ints = {1, 30})
    void rejectsAnyAmount(int minorUnits) { ... }
}
```

Avoid: a parameter selecting a different assertion. A nested class per
method rather than per scenario. A display name repeating the method.

## Disabled tests

- A disabled test states why, and what re-enables it

Avoid: a disabled test with no reason. A test disabled to make a build
green. A quarantine list that only grows.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a fixture or lifecycle method | Lifecycle |
| an assertion is written | Assertions |
| several inputs or a scenario group | Parameterised and nested |
| a test is disabled | Disabled tests |
