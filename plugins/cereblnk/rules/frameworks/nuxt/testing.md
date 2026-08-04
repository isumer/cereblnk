---
name: nuxt-testing
genre: constraint
category: frameworks
paths:
  - "**/*.nuxt.test.ts"
  - "**/tests/**/*.spec.ts"
  - "**/server/api/**/*.test.ts"
---

# Nuxt Testing

Judgment lives in `skills/frameworks/nuxt/`.
Style constraints live in [`coding-style.md`](coding-style.md).

## Layers under test

- Server handlers are tested as event in, value out
- Pages are tested through rendered output, with data faked at the route

```ts
const event = createEvent({ body: { reference: "ref-1" } });

await expect(handler(event))
    .resolves.toMatchObject({ status: "settled" });
```

Avoid: a handler tested by calling the service it wraps. A page test
that reaches a real API.

## Composables

- Composables are tested inside a Nuxt test context
- Shared state keys are asserted, because collisions are silent

```ts
const { status } = usePaymentStatus("ref-1");

expect(status.value).toBe("unknown");
expect(useState("payment:ref-1").value).toBe("unknown");
```

Avoid: a composable tested outside the app context. Two composables
sharing a key that no test compares.

## Data fetching

- Fetch keys are asserted alongside the data they hold
- Cache behaviour is exercised, not assumed

```ts
const { data } = await useAsyncData("order:1", fetcher);

expect(fetcher).toHaveBeenCalledTimes(1);
expect(data.value?.id).toBe("1");
```

Avoid: a test that passes because a payload was cached from an earlier
case. A key generated randomly in a test.

## Isolation

- Each test starts with a fresh app state
- Server routes are intercepted at the transport layer

```ts
beforeEach(async () => {
    await setup({ server: true, browser: false });
});
```

Avoid: state carried between test files. A route replaced by patching
the module that defines it.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a handler or page test | Layers under test |
| a use* function | Composables |
| useAsyncData or useFetch | Data fetching |
| test setup or teardown | Isolation |
