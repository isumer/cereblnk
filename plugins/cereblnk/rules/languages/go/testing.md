---
name: go-testing
genre: constraint
category: languages
paths:
  - "**/*_test.go"
---

# Go Testing

Extends [`common/testing.md`](../../common/testing.md). Layer choice
lives in `skills/practices/test-strategy/`.

## Table tests

- One test function per behavior; cases vary the input, not the assertion
- Each case is named, and subtests carry that name

```go
func TestRejectsSettlementAfterWindow(t *testing.T) {
    cases := []struct {
        name string
        on   time.Time
        want Result
    }{
        {"inside the window", day(1, 10), Captured},
        {"on the boundary", day(1, 15), Captured},
        {"past the window", day(1, 20), Rejected},
    }

    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            if got := attempt(order, tc.on); got != tc.want {
                t.Fatalf("got %v, want %v", got, tc.want)
            }
        })
    }
}
```

Avoid: a case list with no boundary value · a case selecting a
different assertion · an unnamed subtest.

## Isolation

- Time, randomness and the network are injected, never ambient
- Cleanup is registered, not deferred by hand

Avoid: a real clock read inside a test · a fixed sleep waiting for an
effect · state shared between test functions.

## Concurrency

- Concurrent behavior is asserted as an invariant and run under the
  race detector

Avoid: a sleep used to order goroutines · an assertion on execution
order · a concurrency test run once and trusted.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a test is added | Table tests |
| a test touches time, randomness, or files | Isolation |
| concurrency is tested | Concurrency |
