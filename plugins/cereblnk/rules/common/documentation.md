---
name: common-documentation
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Documentation

Technology-neutral. Documentation that drifted is worse than none: it
is trusted.

## Reader

- One document, one reader, one question

```text
getting started   a newcomer who wants it running
integration       a caller who needs the contract
maintenance       an owner who needs the rationale
operations        a responder who needs the failure modes
```

Avoid: one page serving three readers · a reference buried in a
tutorial · an audience left unstated.

## Examples

- Every example is run as written, from a clean environment
- The version it was run against is recorded

Avoid: an example adapted from memory · a snippet with an elided step
· output pasted from an older version · a prerequisite obvious to the
author and absent from the page.

## Drift

- A behavioral change and its document travel together
- Examples exercising the changed path are re-run

Avoid: a document updated in a later pass · a change that silently
invalidates a published example.

## Decisions and terms

- A decision with consequences records its context, options, choice,
  and what would reverse it
- Vocabulary is defined once, where the reader first meets it

Avoid: a decision living only in a review thread · an acronym used
before definition · two terms for one concept.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a document is created | Reader |
| an example is written | Examples |
| behavior changed in code | Drift |
| a decision was made, or a term introduced | Decisions and terms |
