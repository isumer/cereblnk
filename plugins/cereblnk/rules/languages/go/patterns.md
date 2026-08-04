---
name: go-patterns
genre: constraint
category: languages
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Construction

- A constructor validates and returns a usable value
- Options are functional once a constructor grows past a few arguments

```go
func NewSettlement(store OrderStore, opts ...Option) (*Settlement, error) {
    if store == nil {
        return nil, errors.New("settlement: store is required")
    }
    s := &Settlement{store: store, attempts: defaultAttempts}
    for _, opt := range opts {
        opt(s)
    }
    return s, nil
}
```

Avoid: a struct literal built field by field across a package boundary
· a constructor that cannot fail but should · a boolean parameter
selecting behavior.

## Errors as values

- Domain failures are typed, so callers branch on them
- Comparison uses the errors package, never a message

```go
var ErrOrderNotFound = errors.New("order not found")

if errors.Is(err, ErrOrderNotFound) {
    return Receipt{}, nil
}
```

Avoid: a string comparison on an error · one error type carrying a
code callers must read · panic used for an expected failure.

## Boundaries

- Storage sits behind an interface defined by its consumer
- Transport types never travel into the domain

Avoid: a database row struct used as the domain type · a handler
constructing its own client · a cycle broken by a package of
everything.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a type is constructed | Construction |
| a failure crosses a package | Errors as values |
| storage or transport is touched | Boundaries |
