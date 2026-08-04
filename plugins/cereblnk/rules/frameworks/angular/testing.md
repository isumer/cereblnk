---
name: angular-testing
genre: constraint
category: frameworks
paths:
  - "**/*.spec.ts"
  - "**/*.test.ts"
---

# Angular Testing

Extends [`languages/typescript/testing.md`](../../languages/typescript/testing.md).

## Configure the minimum

- A test declares only what the subject needs
- A component test uses the real template, with stubbed collaborators

```typescript
await TestBed.configureTestingModule({
  imports: [OrderListComponent],
  providers: [{ provide: OrderService, useValue: stubOrderService }],
}).compileComponents()
```

Avoid: the whole application module imported for one component. A real
HTTP client in a unit test. A shared TestBed configuration nobody
reads.

## Query as a user

- Elements are found by role and accessible name where the DOM allows

```typescript
const button = fixture.debugElement.query(
  By.css('[role="button"][aria-label="Settle order"]'),
)
button.nativeElement.click()
```

Avoid: a query by CSS class alone. An assertion on a component field
where the rendered output is the contract.

## Async

- Waiting uses the framework's async helpers, never a timer

```typescript
it('loads orders', fakeAsync(() => {
  component.load()
  tick()
  fixture.detectChanges()

  expect(component.orders()).toHaveLength(2)
}))
```

Avoid: a fixed delay before an assertion. A pending timer left at test
end. A subscription never completed.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a spec is added | Configure the minimum |
| the rendered output is asserted | Query as a user |
| asynchronous behavior is tested | Async |
