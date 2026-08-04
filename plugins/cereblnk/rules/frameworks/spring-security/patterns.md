---
name: spring-security-patterns
genre: constraint
category: frameworks
paths:
  - "**/*SecurityConfig*.java"
  - "**/security/**/*.java"
  - "**/config/**/*.java"
---

# Spring Security Patterns

Extends [`frameworks/spring-boot/security.md`](../spring-boot/security.md).
Judgment lives in `skills/frameworks/spring-security/`.

## Filter chain

- One chain per surface, ordered explicitly
- A custom filter states its position by class, not by number

```java
@Bean
SecurityFilterChain api(HttpSecurity http) throws Exception {
    return http
        .securityMatcher("/api/**")
        .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
        .oauth2ResourceServer(oauth -> oauth.jwt(Customizer.withDefaults()))
        .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
        .build();
}
```

Avoid: two chains matching the same path · a filter inserted at an
arbitrary index · a chain that permits everything as a fallback.

## Authorization decisions

- The rule lives where the resource is, not scattered across layers
- Ownership checks compare the authenticated principal to the resource

```java
@PreAuthorize("hasRole('ADMIN') or #tenant == authentication.name")
public OrderSummary summarise(String tenant, OrderId id) { ... }
```

Avoid: an identifier from the request trusted as the caller's own · a
role checked in a controller and not at the service · an expression
duplicated at three call sites.

## Method and data access

- A method-level rule guards what a chain rule cannot see
- A query filters by the principal's scope, in the query

```java
@Query("select o from Order o where o.tenant = :#{authentication.name}")
List<Order> findMine();
```

Avoid: filtering results in memory after loading everything · a
repository method reachable with no rule · an administrative path
sharing a service method with a tenant path.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a chain or filter is declared | Filter chain |
| an access rule is written | Authorization decisions |
| a service or query is exposed | Method and data access |
