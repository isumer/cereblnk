---
name: nodejs-testing
genre: constraint
category: frameworks
paths:
  - "**/server/**/*.test.js"
  - "**/server/**/*.test.ts"
  - "**/test/**/*.mjs"
---

# Node.js Testing

Judgment lives in `skills/frameworks/nodejs/`.
Style constraints live in [`coding-style.md`](coding-style.md).

## Test boundaries

- A unit test imports the module and nothing it talks to
- An integration test starts the real server on an ephemeral port

```js
const server = app.listen(0);
const { port } = server.address();

after(() => server.close());
```

Avoid: a unit test reaching a database. A fixed port that fails when a
suite runs twice.

## Asynchrony in tests

- Every asynchronous assertion is awaited
- Rejections are asserted by type and code, not by message

```js
await assert.rejects(
    () => capture("unknown"),
    (error) => error.code === "PAYMENT_NOT_FOUND",
);
```

Avoid: a promise created and never awaited. An assertion matching the
text of an error message.

## Time and randomness

- Clock and identifier generators are injected
- A test that depends on ordering states the ordering

```js
const clock = { now: () => new Date("2026-01-01T00:00:00Z") };
const service = createPaymentService({ clock, ids: () => "id-1" });
```

Avoid: a test asserting a timestamp produced by the system clock. A
suite that passes only in one execution order.

## What the suite must fail on

- Each fixed defect gains a test that fails without the fix
- The failure path is asserted, not only the success path

```js
test("refund of a settled payment is rejected", async () => {
    await capture("ref-1");
    await settle("ref-1");
    await assert.rejects(() => refund("ref-1"));
});
```

Avoid: a regression test that passes against the old code. A suite that
only ever exercises the happy path.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new test file | Test boundaries |
| await or a rejected promise | Asynchrony in tests |
| a date, uuid, or random value | Time and randomness |
| a bug fix | What the suite must fail on |
