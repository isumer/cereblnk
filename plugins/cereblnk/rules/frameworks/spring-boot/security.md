---
name: spring-boot-security
genre: constraint
category: frameworks
paths:
  - "**/application*.yml"
  - "**/application*.yaml"
  - "**/application*.properties"
  - "**/controller/**/*.java"
  - "**/*Controller.java"
  - "**/*Resource.java"
  - "**/config/**/*.java"
  - "**/*Config.java"
  - "**/*Configuration.java"
  - "**/*ControllerAdvice.java"
---

# Spring Boot Security

Extends [`languages/java/security.md`](../../languages/java/security.md).
Authorization design lives in `skills/frameworks/spring-security/`.

## Endpoints

- Access is denied by default; every endpoint states its rule
- A new endpoint is unreachable until its rule exists

```java
http.authorizeHttpRequests(auth -> auth
        .requestMatchers("/actuator/health").permitAll()
        .requestMatchers("/api/admin/**").hasRole("ADMIN")
        .anyRequest().authenticated());
```

Avoid: a permit-all fallback · an endpoint secured only by an unguessable
path · a rule ordered after a broader match that already accepted it.

## Request data

- Request bodies bind to a validated type, never to an entity
- Path and query values are validated before they reach a query

```java
@PostMapping("/orders")
public OrderResponse create(@Valid @RequestBody OrderRequest request) {
    return service.create(request.toDomain());
}
```

Avoid: an entity used as a request body · a field a caller can set that
the domain should own · validation performed after persistence.

## Exposure

- Management endpoints are limited to what operations needs
- Error responses carry a code, never internal detail

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info
server:
  error:
    include-stacktrace: never
    include-message: never
```

Avoid: environment or heap dump endpoints exposed publicly · a stack
trace returned on failure · a header revealing framework versions.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an endpoint is added or mapped | Endpoints |
| a request payload is bound | Request data |
| management or error output changes | Exposure |
