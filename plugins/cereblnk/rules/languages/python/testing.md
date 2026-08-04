---
name: python-testing
genre: constraint
category: languages
paths:
  - "**/test_*.py"
  - "**/*_test.py"
  - "**/tests/**/*.py"
---

# Python Testing

Extends [`common/testing.md`](../../common/testing.md). Layer choice
lives in `skills/practices/test-strategy/`.

## Names and shape

- The name states the behavior, in the domain's words
- Arrange, act, assert — one behavior per test

```python
def test_rejects_settlement_after_the_window_closes() -> None:
    order = order_closed_on(date(2026, 1, 1))

    result = settlement.attempt(order, on=date(2026, 1, 20))

    assert result is Rejected.WINDOW_CLOSED
```

Avoid: a name repeating the function under test · several unrelated
assertions in one test · a bare `assert` on a truthy value.

## Fixtures

- A fixture builds valid data; each test overrides only what it tests
- Scope is the narrowest that works

Avoid: a session-scoped fixture holding mutable state · a fixture
chain three deep · data shared between tests through a module global.

## Doubles

- A double replaces a collaborator, never the unit under test
- Time and randomness are injected, not patched globally

```python
def test_expires_at_the_boundary() -> None:
    clock = lambda: datetime(2026, 1, 20, 9, tzinfo=timezone.utc)

    assert token_issued_an_hour_earlier().is_expired(clock)
```

Avoid: patching the module under test · asserting every call · a
global patch left between tests.

## Parameters and exceptions

- A parameter varies the input, never the assertion
- An expected exception is asserted by type and by message where it
  carries meaning

```python
@pytest.mark.parametrize("amount", [-1, 0])
def test_rejects_non_positive_amounts(amount: int) -> None:
    with pytest.raises(ValueError):
        Money(minor_units=amount, currency="EUR")
```

Avoid: a parameter selecting a different assertion · a case list with
no boundary value · a broad exception assertion.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a test is added | Names and shape |
| a fixture is written | Fixtures |
| a double is introduced | Doubles |
| several inputs, or an expected failure | Parameters and exceptions |
