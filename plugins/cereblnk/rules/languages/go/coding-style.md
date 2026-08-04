---
name: go-coding-style
genre: constraint
category: languages
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/go/`.

## Layout

- Formatting and import ordering are tool-decided, not discussed
- Exported identifiers carry a doc comment starting with the name
- Package names are short, lowercase, and not plural

Avoid: a style argument in review · an exported symbol with no comment
· a package named for a layer rather than a capability.

## Interfaces

- Accept interfaces, return concrete types
- An interface holds one to three methods, defined where consumed

```go
type OrderStore interface {
    ByID(ctx context.Context, id OrderID) (Order, error)
}

func NewSettlement(store OrderStore) *Settlement {
    return &Settlement{store: store}
}
```

Avoid: an interface defined beside its only implementation · a
five-method interface for one caller · returning an interface where a
struct is the answer.

## Errors

- Every error is handled, wrapped with context, or ignored with a
  stated reason
- Wrapping preserves the cause; sentinels are compared, not matched

```go
captured, err := gateway.Capture(ctx, order.Total)
if err != nil {
    return Receipt{}, fmt.Errorf("capture order %s: %w", order.ID, err)
}
```

Avoid: an error assigned to the blank identifier with no comment · an
error returned unwrapped from a deep call · a message compared as a
string.

## Context

- Context is the first parameter and is never stored in a struct
- Every blocking call takes it and honours cancellation

Avoid: a context created inside a library function · a background
context passed where the caller's belongs.

## Concurrency

- Every goroutine has an owner and a stop signal before it starts
- The writer closes the channel; the reader never does
- Shared memory is guarded, and proven by the race detector

```go
func (w *Worker) Start(ctx context.Context) {
    go func() {
        for {
            select {
            case <-ctx.Done():
                return
            case job := <-w.jobs:
                w.handle(job)
            }
        }
    }()
}
```

Avoid: a goroutine with no cancellation path · a channel with no
stated closer · a concurrency claim with no race-detector run.

## Zero values

- A type is usable at its zero value, or it has a constructor
- Maps and slices are constructed before writing

Avoid: a struct needing three assignments before use · a write to a
nil map · a nil pointer inside an interface compared against nil.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a package, or an exported symbol | Layout |
| an interface is declared | Interfaces |
| an error is returned or ignored | Errors |
| a blocking or outbound call | Context |
| a goroutine or channel | Concurrency |
| a struct, map, or slice field | Zero values |
