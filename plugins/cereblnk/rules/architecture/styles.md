---
name: architecture-styles
genre: constraint
category: architecture
density: neutral
applies_when: an architectural style is chosen, applied, or deviated from
---

# Architectural Styles

One style is chosen per system and stated where a reader will find it.
This file constrains the choice and its consistency, not the style.

## Declaring the style

- The chosen style is recorded, with the pain it answers
- Layer names, module boundaries and folder shape follow from it

```text
recorded    the style, and why this system needs it
recorded    what it costs, and what it rules out
placed      in the repository's architecture document
```

Avoid: a style inferred from folder names. Two styles applied in one
codebase. A style adopted because it is current.

## Staying consistent

- A new module follows the declared style or the style changes
- A deviation is recorded as a decision, with its reason

Avoid: one feature layered and another hexagonal. A port added to a
system with no adapters. An exception nobody wrote down.

## Splitting a system

- A split names the pain it solves: deployment, scaling, or autonomy
- Independence is proven by deploying one part alone

Avoid: a distributed system with none of the three gains. Services
sharing a database schema. A synchronous chain three hops deep.

## Event-carried state

- An event is a fact about the past, named accordingly
- Consumers are idempotent, since redelivery is normal

Avoid: an event named as an instruction. A consumer assuming exactly
one delivery. Ordering assumed across partition keys.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an architecture document changes | Declaring the style |
| a module is created | Staying consistent |
| a service is split out | Splitting a system |
| an event is published or consumed | Event-carried state |
