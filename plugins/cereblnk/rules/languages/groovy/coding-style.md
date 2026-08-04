---
name: groovy-coding-style
genre: constraint
category: languages
paths:
  - "**/*.groovy"
  - "**/*.gradle"
  - "**/Jenkinsfile"
  - "**/vars/*.groovy"
---

# Groovy Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/groovy/`.

## Which runtime

- Every file states which runtime it belongs to: pipeline, build
  script, or plain source
- A rule below applies to the runtime named beside it

Avoid: a helper shared between a Jenkinsfile and plain source with no
note on the transform. A build script importing application code.

## Plain source

- Static compilation enabled on classes that carry logic
- Types declared on public signatures

```groovy
@CompileStatic
class SettlementWindow {
    private final LocalDate opens
    private final LocalDate closes

    boolean includes(LocalDate date) {
        !date.isBefore(opens) && !date.isAfter(closes)
    }
}
```

Avoid: a dynamic class holding domain rules. A method whose return
type only a caller discovers. Metaprogramming with no test naming what
it defines.

## Truth and interpolation

- Presence is compared explicitly, never left to Groovy truth
- Interpolated strings are eager; a lazy closure inside one is not used

```groovy
if (settledAt != null) {
    return SettlementState.SETTLED
}
```

Avoid: a truthiness check where zero, an empty string, or an empty
collection is data. A lazy closure inside an interpolated string. A
GString used where a String is required.

## Build scripts

- Code states the phase it runs in: configuration or execution
- Work belongs in a task action, not in the script body

```groovy
tasks.register('report') {
    doLast {
        println "settled: ${service.settledCount()}"
    }
}
```

Avoid: work in the script body, which runs for every build. A task
configured by side effect. A version resolved during configuration for
a task that may not run.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a file is added | Which runtime |
| a class or method in plain source | Plain source |
| a comparison or an interpolated string | Truth and interpolation |
| a build script is edited | Build scripts |
