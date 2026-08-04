---
name: spring-security-security
genre: constraint
category: frameworks
paths:
  - "**/*SecurityConfig*.java"
  - "**/security/**/*.java"
  - "**/config/**/*.java"
---

# Spring Security Configuration

Extends [`common/security.md`](../../common/security.md).

## Sessions and tokens

- Stateless APIs create no session
- A token's issuer, audience and expiry are all validated

```java
JwtDecoder decoder = NimbusJwtDecoder
        .withIssuerLocation(issuerUri)
        .build();
decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(issuerUri));
```

Avoid: a signature verified while the issuer is not · an expiry check
disabled for a test that stayed · a session created by an API path.

## Cross-site protections

- Protection is disabled only for stateless token surfaces, and the
  reason is stated
- Allowed origins are listed, never reflected from the request

```java
CorsConfiguration cors = new CorsConfiguration();
cors.setAllowedOrigins(List.of("https://app.example.com"));
cors.setAllowedMethods(List.of("GET", "POST"));
cors.setAllowCredentials(true);
```

Avoid: a wildcard origin with credentials allowed · protection
disabled globally to fix one endpoint.

## Passwords and credentials

- Passwords are stored with an adaptive hash, never encrypted
- The work factor is a configured value, reviewed over time

```java
@Bean
PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12);
}
```

Avoid: a fast hash used for a password · a salt shared across users ·
a credential compared with a non-constant-time check.

## Trigger table

| Seen in the diff | Section |
|---|---|
| session or token handling changes | Sessions and tokens |
| a cross-origin or CSRF setting changes | Cross-site protections |
| a credential is stored or compared | Passwords and credentials |
