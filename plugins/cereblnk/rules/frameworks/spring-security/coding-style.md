---
name: spring-security-coding-style
genre: constraint
category: frameworks
paths:
  - "**/SecurityConfig*.java"
  - "**/security/**/*.java"
  - "**/config/**/Security*.java"
---

# Spring Security Coding Style

Judgment lives in `skills/frameworks/spring-security/`.
Constraints on the surface itself live in [`security.md`](security.md).

## Chain declaration

- One `SecurityFilterChain` bean per protected surface
- Each chain names the requests it owns before any rule

```java
@Bean
SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
    return http
        .securityMatcher("/api/**")
        .authorizeHttpRequests(this::apiRules)
        .build();
}
```

Avoid: two chains competing for one path. A chain whose matcher is
implied by ordering alone.

## Rule ordering

- Specific matchers precede general ones
- The chain ends with a rule that denies what it did not name

```java
private void apiRules(AuthorizeHttpRequestsConfigurer<?>
        .AuthorizationManagerRequestMatcherRegistry rules) {
    rules.requestMatchers("/api/admin/**").hasRole("ADMIN")
         .requestMatchers("/api/public/**").permitAll()
         .anyRequest().authenticated();
}
```

Avoid: a permit rule placed above the rule it was meant to narrow. A
chain that ends without naming its default.

## Named authorities

- Roles and scopes are constants, declared once
- A matcher string appears in one file

```java
final class Authorities {
    static final String ADMIN = "ADMIN";
    static final String PAYMENT_WRITE = "SCOPE_payment.write";
}
```

Avoid: the same role spelled two ways across configs. An authority
literal repeated in tests and production code.

## Method annotations

- Method security states the rule, never the caller
- One annotation per method

```java
@PreAuthorize("hasAuthority(T(com.acme.Authorities).PAYMENT_WRITE)")
Payment capture(String reference) {
    ...
}
```

Avoid: an expression that reads a request attribute. Two overlapping
annotations on one method.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a SecurityFilterChain bean | Chain declaration |
| a requestMatcher or authorize rule | Rule ordering |
| a role or scope string | Named authorities |
| @PreAuthorize or @Secured | Method annotations |
