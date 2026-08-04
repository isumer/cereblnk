---
name: vue-testing
genre: constraint
category: frameworks
paths:
  - "**/*.spec.ts"
  - "**/__tests__/**/*.ts"
  - "**/*.test.ts"
---

# Vue Testing

Judgment lives in `skills/frameworks/vue/`.
Patterns live in [`patterns.md`](patterns.md).

## What a component test asserts

- Tests drive the component the way a user does
- Queries address roles and text, not internal structure

```ts
const wrapper = mount(PaymentRow, { props: { payment } });

await wrapper.get("button[name=capture]").trigger("click");

expect(wrapper.emitted("capture")).toHaveLength(1);
```

Avoid: an assertion on a component's internal state. A query bound to a
class name that styling owns.

## Reactivity in tests

- Every state change is awaited before assertion
- Timers and intervals are controlled by the test

```ts
vi.useFakeTimers();
mount(PollingView);
vi.advanceTimersByTime(5000);

expect(fetchSpy).toHaveBeenCalledTimes(2);
```

Avoid: an assertion made before the next tick. A test that waits on
real elapsed time.

## Composables

- Composables are tested directly, inside an effect scope
- Cleanup is asserted, not assumed

```ts
const scope = effectScope();
scope.run(() => usePolling(run, 1000));
scope.stop();

expect(clearInterval).toHaveBeenCalled();
```

Avoid: a composable tested only through a component. A cleanup path
that no test reaches.

## Boundaries

- Network is intercepted at the transport, once per suite
- Stores are created fresh for each test

```ts
beforeEach(() => {
    setActivePinia(createPinia());
});
```

Avoid: a store shared between tests. A fetch replaced module by module.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a component test | What a component test asserts |
| await nextTick, a timer, or an interval | Reactivity in tests |
| a use* function under test | Composables |
| a store or network call in a test | Boundaries |
