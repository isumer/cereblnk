---
name: angular-patterns
genre: constraint
category: frameworks
paths:
  - "**/*.component.ts"
  - "**/*.service.ts"
  - "**/*.store.ts"
  - "**/*.routes.ts"
  - "**/*.component.html"
---

# Angular Patterns

Extends [`languages/typescript/patterns.md`](../../languages/typescript/patterns.md).

## Reactive state

- Derived values are computed from their sources, never copied
- A subscription in a component is unsubscribed with the component

```typescript
export class OrderListComponent {
  private readonly orders = inject(OrderService).orders
  readonly overdue = computed(() =>
    this.orders().filter((order) => order.isOverdue),
  )
}
```

Avoid: a derived value written into a second field. A subscription
with no teardown. A stream subscribed twice for two readers.

## Streams

- A stream is composed, and subscribed once at the edge
- Errors are handled inside the stream, not by a wrapping try

```typescript
readonly orders$ = this.route.paramMap.pipe(
  switchMap((params) => this.service.byTenant(params.get('tenant')!)),
  catchError(() => of([])),
)
```

Avoid: a subscribe inside a subscribe. A stream that swallows its
error silently. State mutated inside an operator.

## Templates

- A template reads values; it does not compute them
- Structural conditions render the empty and error states explicitly

```html
@if (orders().length === 0) {
  <app-empty-orders />
} @else {
  <app-order-list [orders]="orders()" />
}
```

Avoid: a method call in a binding evaluated every cycle. A template
with three nested conditions. A pipe doing work a service should.

## Trigger table

| Seen in the diff | Section |
|---|---|
| state or a derived value is added | Reactive state |
| an observable is composed | Streams |
| a template binding is written | Templates |
