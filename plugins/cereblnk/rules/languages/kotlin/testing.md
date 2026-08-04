---
name: kotlin-testing
genre: constraint
category: languages
paths:
  - "**/*Test.kt"
  - "**/*Spec.kt"
  - "**/src/test/**/*.kt"
---

# Kotlin Testing

Extends [`common/testing.md`](../../common/testing.md). Layer choice
lives in `skills/practices/test-strategy/`.

## Names and shape

- The name states the behavior, in the domain's words
- Arrange, act, assert — one behavior per test

```kotlin
@Test
fun `rejects settlement after the window closes`() {
    val order = orderClosedOn(LocalDate.of(2026, 1, 1))

    val result = settlement.attempt(order, LocalDate.of(2026, 1, 20))

    assertThat(result).isEqualTo(Rejected.WINDOW_CLOSED)
}
```

Avoid: a name repeating the function under test · several unrelated
assertions in one test.

## Coroutines

- Suspending code is tested with a test dispatcher, never a real delay
- Cancellation behavior is asserted, not assumed

```kotlin
@Test
fun `stops when the caller cancels`() = runTest {
    val job = launch { worker.run() }

    job.cancelAndJoin()

    assertThat(worker.isRunning).isFalse()
}
```

Avoid: a real delay used to sequence a test · a launch left running
past the test · a timing assertion standing in for an invariant.

## Doubles

- A double replaces a collaborator, never the unit under test
- Time and randomness are injected

Avoid: mocking the class under test · asserting every interaction · a
static mock left in place between tests.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a test is added | Names and shape |
| suspending code is tested | Coroutines |
| a double is introduced | Doubles |
