---
name: common-coding-style
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Coding Style

Technology-neutral. Language rules refine the syntax; the decisions
below survive the language.

## Simplicity

- Simplest solution that actually works; clarity over cleverness
- Extract shared logic when repetition is real, not anticipated
- No abstraction, option, or layer before something needs it

Avoid: a configuration point with one caller · a generic interface
with one implementation · optimisation before measurement.

## Size and shape

- Functions under about fifty lines, one level of abstraction
- Files 200–400 lines typical, 800 the point of concern
- Nesting under four levels; end the work early instead

```text
settleOrder(order)
    if order.isCancelled  -> return Rejected(cancelled)
    if order.isSettled    -> return AlreadyDone
    if !funds.available   -> return Rejected(insufficient)

    capture(order)
```

Organise by feature, not by kind: everything a change touches sits
together.

Avoid: an else branch holding the main work · a file grouping types
because they share a shape · a helper that exists only to hide length.

## Immutability

- Values fixed at construction unless someone owns the mutation
- A change returns a new instance rather than editing this one
- Collections leave a public method as copies

```text
update(original, field, value) -> a new instance carrying the change
owner        the component that may write, named
lifetime     stated: request, session, process
```

Avoid: a shared mutable structure with no owner · a setter added for
one caller · an internal collection handed out directly.

## Constants and comments

- A number that carries meaning is a named constant
- Code states what happens; a comment states why it must

```text
MAXIMUM_RETRY_ATTEMPTS = 3
SETTLEMENT_WINDOW_DAYS = 14

// the gateway rejects amounts above the daily cap,
// so the split below is required, not an optimisation
```

Avoid: a bare threshold in a comparison · the same number at two call
sites · a comment restating the next line · commented-out code kept
for reference.

## Scope of change

- Every changed line traces to the request
- Orphans your change created are removed with it

Avoid: a reformatted file inside a small change · a rename bundled
with a fix · an adjacent improvement nobody asked for.

## Before it is done

```text
[ ] names say what the thing is, not what type it has
[ ] functions small, nesting shallow, files focused
[ ] no literal thresholds, no hardcoded configuration
[ ] failures handled, none swallowed
[ ] external input validated at the boundary
[ ] no mutation without a named owner
[ ] the diff contains only what the request required
```

## Trigger table

| Seen in the diff | Section |
|---|---|
| an abstraction or option added | Simplicity |
| a long function, deep nesting, a growing file | Size and shape |
| a value or field | Immutability |
| a bare number, or a comment | Constants and comments |
| formatting or renames outside the task | Scope of change |
| work being called complete | Before it is done |
