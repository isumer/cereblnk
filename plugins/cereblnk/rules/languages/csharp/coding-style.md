---
name: csharp-coding-style
genre: constraint
category: languages
paths:
  - "**/*.cs"
  - "**/*.csproj"
---

# C# Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/csharp/`.

## Layout

- Nullable reference types enabled; warnings answered, not suppressed
- Pascal case for types and members, camel case for locals and
  parameters, interfaces named for behavior
- One primary type per file, named for the file

Avoid: a suppression with no justification. A file holding two public
types. Analyzer warnings treated as noise.

## Types

- Records for values, classes for identity, interfaces for boundaries
- Immutable members: constructor parameters or init-only setters

```csharp
public sealed record Money(decimal Amount, string Currency)
{
    public Money
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(Currency);
    }
}
```

Avoid: `dynamic` in application code. A class with only auto
properties used as a value. A mutable type used as a dictionary key.

## Async

- Async all the way; a task is awaited, never blocked on
- Cancellation tokens are accepted and forwarded

```csharp
public async Task<Receipt> SettleAsync(OrderId id, CancellationToken ct)
{
    var order = await _orders.FindAsync(id, ct);
    var captured = await _gateway.CaptureAsync(order.Total, ct);

    return Receipt.From(captured);
}
```

Avoid: reading a task's result property. An async method returning
void outside an event handler. A token accepted and dropped.

## Disposal

- What you create, you scope; a field holding a disposable is disposed
  by its holder

```csharp
await using var connection = await _factory.OpenAsync(ct);
```

Avoid: a disposable created without a scope. A holder that owns one and
implements no disposal. A stream closed only on the success path.

## Collections

- A boundary exposes a read-only view of what it owns

```csharp
private readonly List<LineItem> _items = [];

public IReadOnlyList<LineItem> Items => _items.AsReadOnly();
```

Avoid: an internal list returned directly. An array property a caller
can reassign into.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a file, type name, or suppression | Layout |
| a model or value is declared | Types |
| an asynchronous call | Async |
| a disposable is created or held | Disposal |
| a collection crosses a boundary | Collections |
