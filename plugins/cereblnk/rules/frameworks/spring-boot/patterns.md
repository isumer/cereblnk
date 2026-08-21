---
name: spring-boot-patterns
genre: constraint
category: frameworks
paths:
  - "**/service/**/*.java"
  - "**/*Service.java"
  - "**/*ServiceImpl.java"
  - "**/controller/**/*.java"
  - "**/*Controller.java"
  - "**/*Resource.java"
  - "**/*ControllerAdvice.java"
  - "**/*ExceptionHandler.java"
  - "**/*Scheduler.java"
  - "**/*Listener.java"
---

# Spring Boot Patterns

Extends [`languages/java/patterns.md`](../../languages/java/patterns.md).

## Transactions

- The boundary is the service method that owns the unit of work
- A self-invocation does not start a transaction

```java
@Transactional
public Receipt settle(OrderId id) {
    var order = orders.findById(id).orElseThrow();
    var captured = gateway.capture(order.total());
    return ledger.record(captured);
}
```

Avoid: `@Transactional` on a repository method · a transaction opened
in a controller · a remote call inside a transaction holding locks · a
private method annotated and never proxied.

## Errors

- One handler translates domain failures into responses
- The response body shape is the same for every error

```java
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(OrderNotFoundException.class)
    public ResponseEntity<ApiError> onNotFound(OrderNotFoundException e) {
        var body = ApiError.of("order_not_found", e.getMessage());
        return ResponseEntity.status(NOT_FOUND).body(body);
    }
}
```

Avoid: a try-catch repeated in every controller · a framework default
error body reaching a caller · a stack trace in a response.

## Async and scheduling

- Scheduled and asynchronous work states its executor
- A scheduled job is idempotent and bounded

Avoid: the default executor used for long work · a scheduled method
with no overlap guard · an asynchronous call whose failure nobody
observes.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a unit of work spans writes | Transactions |
| an exception reaches the edge | Errors |
| work runs off the request thread | Async and scheduling |
