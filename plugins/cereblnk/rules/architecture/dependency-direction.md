---
name: architecture-dependency-direction
genre: constraint
category: architecture
density: neutral
applies_when: a module, package, or import boundary is designed or crossed
---

# Dependency Direction

Extends [`common/patterns.md`](../common/patterns.md). Judgment lives
in `skills/practices/microservices/` and the architect agent.

## Which way it points

- Dependencies point toward the stable side, always inward
- The domain names what it needs; adapters satisfy it

```text
domain      no framework, no client, no transport, no annotation
service     the domain, and interfaces it declares
adapter     the service, and the technology it speaks
```

Avoid: a domain type importing a framework. A service constructing its
own client. An interface defined beside its only implementation.

## Cycles

- Module dependencies form a graph with no cycle
- A cycle is broken by moving a type, not by adding a shared module

Avoid: a package named for everything two modules share. A cycle
broken by an interface nobody else implements. A build order that
depends on luck.

## Stability

- A widely depended-on module changes rarely and deliberately
- A module that changes weekly is depended on by few

Avoid: a utility module every feature imports and every feature edits.
A shared type that three teams extend in three directions.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an import crosses a layer | Which way it points |
| a module references another | Cycles |
| a shared type or module changes | Stability |
