---
name: java-testing
genre: constraint
category: languages
paths:
  - "**/*Test.java"
  - "**/*Tests.java"
  - "**/src/test/**/*.java"
---

# Java Testing

Extends [`common/testing.md`](../../common/testing.md). Layer choice
lives in `skills/practices/test-strategy/`.

## Names and assertions

- The name states the rule the test protects
- One behavior per test, however many fields it touches

```java
@Test
void rejectsSettlementAfterTheWindowCloses() {
    var order = orderClosedOn(LocalDate.of(2026, 1, 1));

    var result = settlement.attempt(order, LocalDate.of(2026, 1, 20));

    assertThat(result).isEqualTo(Rejected.WINDOW_CLOSED);
}
```

Avoid: a name repeating the method under test · a numbered suffix · an
assertion on a value the code never changes.

## Doubles

- A double replaces a collaborator, never the unit under test
- Verify the outcome, not every interaction

```java
@Test
void recordsTheCapturedAmount() {
    var gateway = mock(PaymentGateway.class);
    when(gateway.capture(any())).thenReturn(Captured.of(1200));

    new Settlement(gateway, ledger).run(order);

    verify(ledger).record(Money.ofMinor(1200));
}
```

Avoid: mocking the class under test · asserting every interaction · a
stub returning the value the assertion then checks.

## Determinism

- Time and randomness are injected, never read from the environment
- A test passes alone, repeated, and in any order

```java
private final Clock clock = Clock.fixed(
        Instant.parse("2026-01-20T09:00:00Z"), ZoneOffset.UTC);
```

Avoid: a system clock call inside a test · an unseeded random source ·
a fixed sleep standing in for a condition.

## Concurrency

- A concurrent test asserts an invariant, never a timing

```java
@Test
void countsEveryIncrementUnderContention() throws Exception {
    var window = new RateWindow();
    var pool = Executors.newFixedThreadPool(8);

    for (int i = 0; i < 1_000; i++) pool.submit(window::record);
    pool.shutdown();
    assertThat(pool.awaitTermination(5, TimeUnit.SECONDS)).isTrue();

    assertThat(window.count()).isEqualTo(1_000);
}
```

Avoid: a sleep used to order threads · an assertion on execution order.

## Parameters and mappings

- A parameter varies the input, never the assertion
- Every mapped field is asserted; the build only proves it compiles

```java
@ParameterizedTest
@ValueSource(ints = {-1, 0})
void rejectsNonPositiveAmounts(int amount) {
    assertThatThrownBy(() -> Money.ofMinor(amount))
        .isInstanceOf(IllegalArgumentException.class);
}
```

Avoid: a parameter selecting a different assertion · a case list with
no boundary value · a mapping test asserting only non-null · expected
values copied from the mapper's own output.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a test method is added | Names and assertions |
| a double is introduced | Doubles |
| a test touches time or randomness | Determinism |
| concurrency is tested | Concurrency |
| several inputs exercise one behavior | Parameters and mappings |
| a mapping is generated or written | Parameters and mappings |
