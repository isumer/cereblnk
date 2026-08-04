---
name: python-coding-style
genre: constraint
category: languages
paths:
  - "**/*.py"
  - "**/*.pyi"
---

# Python Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/python/`.

## Layout

- PEP 8 conventions, enforced by a formatter, an import sorter and a
  linter — all configured in the repo
- Type annotations on every function signature
- Interpreter and dependencies pinned

```python
from decimal import Decimal

MAXIMUM_ATTEMPTS: int = 3


def settle(order: Order, attempts: int = MAXIMUM_ATTEMPTS) -> Receipt:
    ...
```

Avoid: formatting settled in review · a per-file lint disable · an
unannotated public function.

## Defaults and state

- A default argument is never a mutable value
- Module-level state is a constant, or it has a named owner

```python
def collect(items: list[str], seen: set[str] | None = None) -> set[str]:
    seen = set() if seen is None else seen
    seen.update(items)
    return seen
```

Avoid: a list, dict, or set as a default · a module-level cache nobody
owns · a global rebound inside a function.

## Absence and truthiness

- Absence is compared against `None`, explicitly
- Zero, an empty string and an empty collection are data

```python
if value is None:
    return default
```

Avoid: a truthiness check gating on a number or a string · `!=` used
against `None` · a sentinel that could be a legitimate value.

## Types at the edges

- Public signatures annotated; obvious locals inferred
- External data is validated at the boundary and becomes a typed object

```python
def parse_order(payload: bytes) -> Order:
    request = OrderRequest.model_validate_json(payload)
    return request.to_domain()
```

Avoid: an annotation on parsed data with no runtime validation ·
`Any` in application code · a checker suppression with no reason.

## Exceptions

- Catch the exceptions expected, by name
- Domain failures raise a domain exception carrying the identifier

```python
try:
    return parser.parse(payload)
except ValueError as error:
    raise InvalidPayloadError(f"order payload: {order_id}") from error
```

Avoid: a bare `except` · a broad catch that logs and continues · a
cause dropped on re-raise · an exception used for control flow.

## Comprehensions and loops

- A comprehension expresses one transformation, nested at most twice
- Branching logic reads as a loop

```python
overdue = [invoice for invoice in invoices if invoice.is_overdue(today)]

summary = Summary()
for invoice in invoices:
    if invoice.settled:
        summary.add_settled(invoice.total)
    elif invoice.is_overdue(today):
        summary.add_overdue(invoice.total)
```

Avoid: a comprehension three levels deep · a side effect inside a
comprehension · a loop building a list a comprehension states plainly.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a module, import, or signature | Layout |
| a default argument, or module state | Defaults and state |
| a presence check | Absence and truthiness |
| external data enters | Types at the edges |
| an exception is raised or caught | Exceptions |
| a comprehension or a loop | Comprehensions and loops |
