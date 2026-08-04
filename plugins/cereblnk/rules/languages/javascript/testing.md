---
name: javascript-testing
genre: constraint
category: languages
paths:
  - "**/*.test.js"
  - "**/*.test.jsx"
  - "**/*.spec.js"
  - "**/*.spec.jsx"
---

# JavaScript Testing

Extends [`common/testing.md`](../../common/testing.md). Layer choice
lives in `skills/practices/test-strategy/`.

## Names and shape

- The name states the behavior, in the domain's words
- Arrange, act, assert — in that order, one behavior each

```javascript
it('returns an empty list when no order matches the query', async () => {
  const repository = repositoryWith([])

  const result = await search(repository, 'missing')

  expect(result).toEqual([])
})
```

Avoid: a name repeating the function under test · assertions
interleaved with actions · several unrelated expectations in one test.

## Async

- Every asynchronous assertion is awaited
- Rejections are asserted explicitly, not by absence of a pass

```javascript
await expect(capture(order)).rejects.toThrow(InsufficientFunds)
```

Avoid: an un-awaited promise in a test body · a test passing because
its assertion never ran · a timeout used to wait for an effect.

## Doubles

- A double replaces a collaborator, never the unit under test
- Network and clock are injected, not patched globally

```javascript
const gateway = { capture: vi.fn().mockResolvedValue(captured(1200)) }
const clock = () => new Date('2026-01-20T09:00:00Z')

await settle(order, { gateway, clock })

expect(ledger.record).toHaveBeenCalledWith({ minorUnits: 1200 })
```

Avoid: mocking the module being tested · asserting every call · a
global patch left in place between tests.

## Fixtures

- A builder produces valid data; each test overrides only what it tests

```javascript
function orderWith(overrides = {}) {
  return { id: 'ord_1', totalMinorUnits: 0, items: [], ...overrides }
}
```

Avoid: a literal object repeated across tests · a fixture mutated by
one test and read by another · a helper that hides the value under
assertion.


## Trigger table

| Seen in the diff | Section |
|---|---|
| a test is added | Names and shape |
| a test awaits or rejects | Async |
| a double is introduced | Doubles |
| a fixture is written | Fixtures |
