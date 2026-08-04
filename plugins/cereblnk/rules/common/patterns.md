---
name: common-patterns
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Patterns

Technology-neutral structure. Framework rules refine these.

## Construction

- An object exists only in a usable state
- Validation happens in the constructor, not in a method the caller
  must remember

```text
Money(amount, currency)
    reject a null currency
    reject a negative amount
    return a fixed value
```

Avoid: an empty constructor followed by setters · a validate() the
caller must call · an object usable before it is complete.

## Ownership

- Shared mutable state names its owner before anything writes
- Readers get a copy or a query, never the structure

```text
owner       the component that may write
lifetime    stated: request, session, process
```

Avoid: two components writing one structure · a global mutable
registry · ownership implied by call order.

## Direction

- Dependencies point toward the stable side
- The domain knows nothing about storage or transport

```text
domain      no framework, no client, no transport
service     the domain, and an interface
adapter     the service, and the technology
```

Avoid: a domain type importing a framework · a service constructing
its own client · a cycle between modules.

## Boundaries

- Data becomes trusted at one named place, and stays trusted inside
- Access to storage sits behind one interface per aggregate

Avoid: defensive re-validation in inner layers · raw input travelling
past the boundary · two validators disagreeing · business logic
depending on a storage type.

## Assembly

- Behavior is composed; inheritance is used where the base type is a
  real contract every subtype honours

Avoid: inheritance for code reuse · a hierarchy three levels deep · a
base class holding subclass-specific logic.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an object is constructed | Construction |
| state is shared | Ownership |
| a dependency is introduced | Direction |
| data crosses a boundary | Boundaries |
| a type hierarchy grows | Assembly |
