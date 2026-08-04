---
name: python-patterns
genre: constraint
category: languages
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Value types

- A value type is frozen and compares by content

```python
@dataclass(frozen=True, slots=True)
class Money:
    minor_units: int
    currency: str

    def __post_init__(self) -> None:
        if self.minor_units < 0:
            raise ValueError("minor_units must not be negative")
```

Avoid: a mutable dataclass used as a key · validation in a method the
caller must remember · equality left to identity.

## Closed sets

- A finite set of outcomes is an enum or a union, matched exhaustively

```python
match result:
    case Captured(amount=amount):
        return f"captured {amount}"
    case Declined(code=code):
        return f"declined {code}"
    case _:
        raise ValueError(f"unhandled result: {result}")
```

Avoid: a status string with no constraint · optional fields standing
in for a variant · a silent fallthrough.

## Resources

- Acquisition and release travel together, through a context manager

```python
with open(path, encoding="utf-8") as handle:
    return handle.read()
```

Avoid: a manual close in a `finally` · a file opened without an
encoding · a connection released only on the successful path.

## Dependencies

- Collaborators are passed in, not constructed inside
- Module import has no side effects

Avoid: a client built at import time · a singleton created on first
use · configuration read during import.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a data class is written | Value types |
| a closed set of outcomes | Closed sets |
| a file, socket, or connection | Resources |
| a collaborator is obtained | Dependencies |
