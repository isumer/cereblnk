---
name: spring-boot-coding-style
genre: constraint
category: frameworks
paths:
  - "**/src/main/java/**/*.java"
  - "**/application*.yml"
  - "**/application*.yaml"
  - "**/application*.properties"
---

# Spring Boot Coding Style

Extends [`languages/java/coding-style.md`](../../languages/java/coding-style.md).
Judgment lives in `skills/frameworks/spring-boot/`.

## Wiring

- Dependencies arrive through the constructor, and fields are final
- A bean is declared once; component scanning is not widened to reach it

```java
@Service
public class SettlementService {

    private final PaymentGateway gateway;
    private final OrderRepository orders;

    public SettlementService(PaymentGateway gateway, OrderRepository orders) {
        this.gateway = gateway;
        this.orders = orders;
    }
}
```

Avoid: field injection · a setter used for a required collaborator · a
scan widened to pick up a stray package · a bean defined in two places.

## Configuration

- Settings bind to a typed properties class, validated at startup
- Every environment-specific value has a default or fails fast

```java
@ConfigurationProperties(prefix = "settlement")
@Validated
public record SettlementProperties(
        @NotNull Duration timeout,
        @Positive int maximumAttempts) {}
```

Avoid: a value read by string key at the call site · a property with no
default and no validation · configuration branching on a profile name
inside business code.

## Layers

- A controller maps and delegates; it holds no rule
- An entity never leaves the persistence layer

Avoid: business logic in a controller · an entity returned from an
endpoint · a repository called from a controller.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a bean or dependency is declared | Wiring |
| a setting is read | Configuration |
| a controller or entity is touched | Layers |
