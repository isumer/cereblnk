---
name: java-security
genre: constraint
category: languages
paths:
  - "**/*.java"
  - "**/pom.xml"
  - "**/build.gradle"
  - "**/build.gradle.kts"
---

# Java Security

Extends [`common/security.md`](../../common/security.md). Authorization
design lives in `skills/frameworks/spring-security/`.

## Input

- Values bind to a prepared statement; they never concatenate
- External bytes become a checked type before travelling inward
- Paths are normalized and confined before opening
- Command arguments are passed as a list, never as a shell string

```java
var sql = "select * from orders where tenant = ? and id = ?";
try (var ps = connection.prepareStatement(sql)) {
    ps.setString(1, tenant);
    ps.setLong(2, orderId);
    return read(ps.executeQuery());
}

public Order fromJson(String body) {
    var request = mapper.readValue(body, OrderRequest.class);
    validator.check(request);
    return request.toDomain();
}
```

Avoid: a formatted query string · an interpolated identifier · native
deserialization of untrusted bytes · polymorphic type resolution from
a payload field · a path joined without normalization.

## Secrets

- Credentials arrive from configuration at runtime
- No key, token, or password in source, fixtures, or build layers

```java
public DataSource dataSource(DbProperties props) {
    return DataSourceBuilder.create()
        .password(props.password())
        .build();
}
```

Avoid: a literal password · a token in a committed test fixture · a
credential deleted in a later build layer.

## Failures

- Propagate, translate, or handle; never swallow
- The cause travels with every rethrow
- The caller learns what failed, never how the system is built

```java
try {
    return parser.parse(payload);
} catch (ParseException e) {
    throw new InvalidPayloadException("order payload", e);
}
```

Avoid: a stack trace in a response body · a database message forwarded
to a caller · an internal path in an error string · a catch with only
a log line.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a query or command built from a value | Input |
| an object read from bytes | Input |
| a file path from outside | Input |
| a credential or key | Secrets |
| an exception caught | Failures |
| an error returned to a caller | Failures |
