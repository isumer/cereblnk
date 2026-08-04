---
name: nodejs-coding-style
genre: constraint
category: frameworks
paths:
  - "**/server/**/*.js"
  - "**/server/**/*.ts"
  - "**/*.mjs"
---

# Node.js Coding Style

Judgment lives in `skills/frameworks/nodejs/`.
Patterns live in [`patterns.md`](patterns.md).

## Module surface

- One module exports one subject
- Named exports; the default export is reserved for a single class

```js
export function capturePayment(reference) { ... }
export function refundPayment(reference) { ... }
```

Avoid: a module exporting unrelated helpers. A default export holding
an object of functions.

## Asynchrony

- `async`/`await` throughout; a promise chain does not mix in
- Concurrent work is declared, not accidental

```js
const [order, customer] = await Promise.all([
    loadOrder(id),
    loadCustomer(id),
]);
```

Avoid: an awaited call inside a loop that had no ordering requirement.
A `.then` chain beside an await in one function.

## Errors

- Thrown values are `Error` instances carrying a stable code
- The message describes the failure, the code identifies it

```js
class PaymentError extends Error {
    constructor(code, message) {
        super(message);
        this.code = code;
    }
}
```

Avoid: throwing a string or a plain object. Callers branching on
message text.

## Configuration

- Environment is read once, at startup, into a frozen object
- A missing required value fails the boot, not the first request

```js
export const config = Object.freeze({
    port: required("PORT"),
    databaseUrl: required("DATABASE_URL"),
});
```

Avoid: `process.env` read inside a handler. A default that silently
points at a development service.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new module or export | Module surface |
| await, Promise, or a loop over async calls | Asynchrony |
| a throw or catch | Errors |
| process.env | Configuration |
