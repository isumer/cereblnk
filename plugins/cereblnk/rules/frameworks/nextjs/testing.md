---
name: nextjs-testing
genre: constraint
category: frameworks
paths:
  - "**/app/**/*.test.tsx"
  - "**/app/**/*.test.ts"
  - "**/e2e/**/*.spec.ts"
---

# Next.js Testing

Judgment lives in `skills/frameworks/nextjs/`.
Style constraints live in [`coding-style.md`](coding-style.md).

## What each layer tests

- Server components are tested through their rendered output
- Route handlers are tested as request in, response out

```ts
const response = await POST(
    new Request("http://test/api/payments", {
        method: "POST",
        body: JSON.stringify({ reference: "ref-1" }),
    }),
);

expect(response.status).toBe(201);
```

Avoid: a route handler tested by calling the service it wraps. A server
component tested through its internals.

## Boundaries under test

- Network calls are intercepted at the boundary, not stubbed per module
- A client component test renders it as a client component

```ts
server.use(
    http.get("/api/orders/:id", () =>
        HttpResponse.json({ id: "1", total: 20 })),
);
```

Avoid: a fetch replaced inside the module under test. A client
component rendered without its interactive behaviour.

## Cache and freshness

- A test states the caching intent it expects
- Revalidation is asserted by observed data, not by a call count

```ts
const first = await getOrder("1", { cache: "no-store" });
await updateOrder("1", { total: 30 });
const second = await getOrder("1", { cache: "no-store" });

expect(second.total).not.toBe(first.total);
```

Avoid: a test that passes because a cached value happened to be stale.
An assertion on how many times a fetch ran.

## End-to-end scope

- End-to-end runs cover the routes a user reaches, not every branch
- Each run starts from a known seed

```ts
test("captures a payment", async ({ page }) => {
    await page.goto("/orders/1");
    await page.getByRole("button", { name: "Pay" }).click();
    await expect(page.getByText("Settled")).toBeVisible();
});
```

Avoid: an end-to-end suite duplicating unit coverage. A run whose
result depends on data left by the previous run.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a route handler or server component | What each layer tests |
| a fetch or external call | Boundaries under test |
| a cache or revalidate option | Cache and freshness |
| a user-facing flow | End-to-end scope |
