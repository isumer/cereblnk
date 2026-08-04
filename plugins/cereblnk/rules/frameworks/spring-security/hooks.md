---
name: spring-security-hooks
genre: constraint
category: frameworks
paths:
  - "**/security/**/*Filter.java"
  - "**/security/**/*Handler.java"
  - "**/security/**/*Provider.java"
---

# Spring Security Extension Points

Judgment lives in `skills/frameworks/spring-security/`.
Chain style lives in [`coding-style.md`](coding-style.md).

## Filter placement

- A custom filter declares its position against a named filter
- One filter does one thing

```java
http.addFilterBefore(new CorrelationIdFilter(),
                     UsernamePasswordAuthenticationFilter.class);
```

Avoid: a filter added without stating where. A filter that both
authenticates and audits.

## Authentication providers

- A provider states the token type it supports
- Failure throws an authentication exception, never returns null

```java
@Override
public boolean supports(Class<?> authentication) {
    return ApiKeyToken.class.isAssignableFrom(authentication);
}

@Override
public Authentication authenticate(Authentication token) {
    return keys.resolve(token.getCredentials().toString())
        .map(ApiKeyToken::authenticated)
        .orElseThrow(() -> new BadCredentialsException("api key"));
}
```

Avoid: a provider that accepts every token type. A silent null return
that reads as a successful skip.

## Success and failure handlers

- Handlers decide the response, never the authorisation
- A failure handler reveals nothing about which factor failed

```java
@Override
public void onAuthenticationFailure(HttpServletRequest request,
        HttpServletResponse response, AuthenticationException e) {
    response.setStatus(HttpStatus.UNAUTHORIZED.value());
}
```

Avoid: a handler granting an authority. A message distinguishing an
unknown user from a wrong password.

## Context propagation

- Work handed to another thread carries the context explicitly
- The context is cleared where it was set

```java
DelegatingSecurityContextExecutor executor =
    new DelegatingSecurityContextExecutor(delegate);

try {
    SecurityContextHolder.setContext(context);
    chain.doFilter(request, response);
} finally {
    SecurityContextHolder.clearContext();
}
```

Avoid: an async task assuming the context followed it. A context set in
a filter and never cleared.

## Trigger table

| Seen in the diff | Section |
|---|---|
| addFilterBefore or addFilterAfter | Filter placement |
| an AuthenticationProvider | Authentication providers |
| a success or failure handler | Success and failure handlers |
| @Async, an executor, or a thread pool | Context propagation |
