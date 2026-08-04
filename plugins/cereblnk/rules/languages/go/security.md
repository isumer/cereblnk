---
name: go-security
genre: constraint
category: languages
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go Security

Extends [`common/security.md`](../../common/security.md).

## Input

- Query values bind as parameters; commands take argument slices
- Paths are cleaned and confined before opening

```go
row := db.QueryRowContext(ctx,
    "select id, total from orders where tenant = $1 and id = $2",
    tenant, orderID)

cmd := exec.CommandContext(ctx, "git", "log", "--oneline", revision)
```

Avoid: a formatted query string · a shell invocation built from input
· a path joined without cleaning.

## Transport

- Outbound calls carry a timeout and a context
- Server handlers set read, write and idle timeouts

```go
client := &http.Client{Timeout: 5 * time.Second}

srv := &http.Server{
    Addr:         addr,
    ReadTimeout:  5 * time.Second,
    WriteTimeout: 10 * time.Second,
    IdleTimeout:  60 * time.Second,
}
```

Avoid: the default client used for an external call · a handler with
no timeout · TLS verification disabled to make a test pass.

## Secrets

- Credentials arrive from the environment or a secret store at runtime
- Required secrets are checked at startup

```go
apiKey := os.Getenv("PAYMENT_API_KEY")
if apiKey == "" {
    return nil, errors.New("PAYMENT_API_KEY is not configured")
}
```

Avoid: a key in source · a token in a committed fixture · a credential
in an error message.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a query, command, or path is built | Input |
| a client or server is configured | Transport |
| a credential appears | Secrets |
