---
name: rust-coding-style
genre: constraint
category: languages
paths:
  - "**/*.rs"
---

# Rust Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/rust/`.

## Layout

- Formatting by the standard formatter, lints treated as errors
- Snake case for functions, modules and crates; Pascal case for types
  and traits; screaming snake for constants
- Lifetimes short and lowercase; descriptive only where the shape is
  complex

Avoid: a style argument in review. A lint allowed at file scope. A
lifetime named for its position rather than its meaning.

## Ownership

- Borrow by default; take ownership when the value must outlive the call
- Return a new value rather than mutating through a reference
- `let` unless mutation is required and owned

```rust
pub fn overdue(invoices: &[Invoice], today: Date) -> Vec<&Invoice> {
    invoices.iter().filter(|i| i.due < today).collect()
}
```

Avoid: a clone added to satisfy the borrow checker. A `&mut` parameter
where a return value reads better. A field made public to avoid a
borrow.

## Errors

- A fallible function returns a result carrying a typed error
- `?` propagates; a panic marks a broken invariant, not a failure

```rust
pub fn settle(&self, id: OrderId) -> Result<Receipt, SettlementError> {
    let order = self.orders.find(id)?;
    let captured = self.gateway.capture(order.total())?;
    Ok(Receipt::from(captured))
}
```

Avoid: `unwrap` or `expect` in library code. An error type that erases
its cause. A panic used for an expected condition.

## Unsafe

- Every `unsafe` block states the invariant it upholds
- It lives in the smallest module, behind a safe interface

```rust
/// # Safety
/// `ptr` is non-null, aligned, and valid for `len` elements for the
/// lifetime of the returned slice.
unsafe fn as_slice<'a>(ptr: *const u8, len: usize) -> &'a [u8] {
    unsafe { std::slice::from_raw_parts(ptr, len) }
}
```

Avoid: `unsafe` justified by a comment rather than an invariant. A
raw pointer crossing a public boundary. An audit boundary nobody drew.

## Async

- Nothing blocking runs on the executor
- Every spawned task has an owner and a cancellation path

```rust
let handle = tokio::spawn(async move {
    tokio::select! {
        _ = token.cancelled() => Ok(()),
        result = worker.run() => result,
    }
});
```

Avoid: a synchronous file or network call inside a task. A task
spawned with no handle. A lock held across an await point.

## Arithmetic

- Overflow behavior is chosen: checked, saturating, or wrapping

```rust
let remaining = budget.checked_sub(spent).ok_or(BudgetError::Exceeded)?;
```

Avoid: arithmetic that panics in debug and wraps in release. A cast
that truncates silently.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an identifier or a lint allowance | Layout |
| a reference, clone, or mutation | Ownership |
| a function that can fail | Errors |
| an `unsafe` block | Unsafe |
| a task or an await | Async |
| an arithmetic operation on integers | Arithmetic |
