---
name: spring-boot-hooks
genre: constraint
category: frameworks
paths:
  - "**/application*.yml"
  - "**/application*.yaml"
  - "**/application*.properties"
  - "**/controller/**/*.java"
  - "**/*Controller.java"
  - "**/*Resource.java"
  - "**/config/**/*.java"
  - "**/*Config.java"
  - "**/*Configuration.java"
  - "**/*Application.java"
---

# Spring Boot Hooks

Extends [`languages/java/hooks.md`](../../languages/java/hooks.md).
Scope and blocking policy come from the common layer.

## On configuration edit

```text
validate    the property file parses
bind        typed properties classes still bind
check       every referenced property exists
```

Avoid: a property renamed in one file, read in another. A binding
failure found at startup in an environment.

## On endpoint change

```text
verify   the endpoint has an access rule
verify   the request type is validated
list     the mapped routes, and diff against the previous list
```

Avoid: a route merged with no access rule · a mapping collision found
in production.

## On startup-affecting change

```text
run     the context loads, once, on the affected module
expect  exit code and the first failure only
never   the full startup log into an agent's context
```

Avoid: a bean cycle found by a person, not by a hook.

## Trigger table

| Situation | Section |
|---|---|
| a property file changed | On configuration edit |
| a controller mapping changed | On endpoint change |
| a bean or configuration class changed | On startup-affecting change |
