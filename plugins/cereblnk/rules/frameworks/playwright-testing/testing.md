---
name: playwright-testing-testing
genre: constraint
category: frameworks
paths:
  - "**/e2e/**/*.ts"
  - "**/*.e2e.ts"
  - "**/playwright.config.*"
  - "**/tests/e2e/**/*.ts"
---

# Playwright Testing

Extends [`common/testing.md`](../../common/testing.md). Judgment lives
in `skills/frameworks/playwright-testing/`.

## Waiting

- Assertions wait on a condition; nothing waits on a clock
- Actionability is asserted, not existence

```typescript
await expect(page.getByRole('button', { name: 'Settle' })).toBeEnabled()
await page.getByRole('button', { name: 'Settle' }).click()
```

Avoid: a fixed timeout before an interaction. A wait for a selector
that exists before it is usable. A retry added to hide a race.

## Selectors

- Elements are found by role and accessible name, then by test id
- A selector never encodes markup structure

```typescript
page.getByRole('row', { name: /ORD-1/ }).getByRole('button')
```

Avoid: a deep CSS path. A selector tied to a class the design owns. An
index-based match on a list.

## Isolation

- Each spec owns its data and can run alone
- Authentication is restored from stored state, not walked per test

```typescript
test.use({ storageState: 'playwright/.auth/user.json' })

test.beforeEach(async ({ request }) => {
  await request.post('/test/orders', { data: { reference: 'ORD-1' } })
})

test.afterEach(async ({ request }) => {
  await request.delete('/test/orders/ORD-1')
})
```

Avoid: a spec depending on another spec's data. The login form walked
in every test. A shared account mutated by parallel runs.

## Scope

- Only journeys crossing systems belong here
- Every new spec states why a cheaper layer could not prove it

```typescript
test('a customer settles an order end to end', async ({ page }) => {
  await page.goto('/orders/ORD-1')
  await page.getByRole('button', { name: 'Settle' }).click()

  await expect(page.getByRole('status')).toHaveText(/settled/i)
})
```

Avoid: a unit-level rule proven through the browser. One spec covering
four journeys. A screenshot comparison standing in for a logic
assertion.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an interaction or a wait | Waiting |
| an element is located | Selectors |
| a spec sets up data or auth | Isolation |
| a new spec is proposed | Scope |
