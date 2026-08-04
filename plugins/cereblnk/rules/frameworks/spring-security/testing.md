---
name: spring-security-testing
genre: constraint
category: frameworks
paths:
  - "**/*Test.java"
  - "**/src/test/**/*.java"
---

# Spring Security Testing

Extends [`frameworks/spring-boot/testing.md`](../spring-boot/testing.md).

## Both sides of every rule

- A test proves the allowed case and the denied case
- Denial asserts the status, not merely that nothing happened

```java
@Test
@WithMockUser(roles = "USER")
void deniesAdminEndpointToNonAdmin() throws Exception {
    mvc.perform(get("/api/admin/orders"))
        .andExpect(status().isForbidden());
}
```

Avoid: an endpoint tested only while authenticated · a denial asserted
by an empty result · security disabled in the test slice.

## Unauthenticated access

- Every protected path has a test proving it rejects anonymous callers

```java
@Test
void rejectsAnonymousAccess() throws Exception {
    mvc.perform(get("/api/orders"))
        .andExpect(status().isUnauthorized());
}
```

Avoid: a new endpoint merged with no anonymous-access test · a path
protected only by convention.

## Tenant isolation

- A test proves one principal cannot reach another's resource

```java
@Test
@WithMockUser(username = "acme")
void cannotReadAnotherTenantsOrder() throws Exception {
    mvc.perform(get("/api/orders/{id}", otherTenantOrderId))
        .andExpect(status().isNotFound());
}
```

Avoid: isolation assumed from a query filter that no test exercises.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an access rule is added | Both sides of every rule |
| an endpoint is added | Unauthenticated access |
| a query filters by principal | Tenant isolation |
