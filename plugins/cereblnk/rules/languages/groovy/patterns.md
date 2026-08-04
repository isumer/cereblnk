---
name: groovy-patterns
genre: constraint
category: languages
paths:
  - "**/Jenkinsfile"
  - "**/*.jenkinsfile"
  - "**/vars/*.groovy"
  - "**/src/**/*.groovy"
---

# Groovy Pipeline Patterns

Extends [`delivery/jenkins-pipelines`](../../../skills/delivery/jenkins-pipelines/SKILL.md).
Applies to pipeline code, which is transformed before it runs.

## Glue, not logic

- Pipeline code orchestrates; build logic runs in a step on the agent
- A calculation the agent could do belongs in a script it executes

```groovy
stage('Build') {
    steps {
        sh './gradlew --no-daemon build'
    }
}
```

Avoid: parsing or transforming data in pipeline code. A loop over
hundreds of items in the transformed program. Application logic living
in a shared library because it was convenient.

## Serializable state

- Every value held across a step is serializable and simple
- Prefer strings, numbers and lists of them over live objects

```groovy
def commit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
```

```groovy
// compute inside the bypassing method, return a plain list
def failures = failedModules(readFile('build/report.txt'))

stage('Report') {
    steps {
        echo "failed: ${failures.join(', ')}"
    }
}
```

Avoid: a matcher, stream, or file handle held across a step. A map of
live objects passed between stages. State kept in a field of a class
the pipeline instantiates.

## Bypassing the transform

- A bypassing method computes and returns a summary
- It calls no pipeline step and no transformed method
- An override of a binary method is marked as bypassing

```groovy
@NonCPS
private static List<String> failedModules(String report) {
    report.readLines().findAll { it.startsWith('FAILED') }
}
```

Avoid: a pipeline step inside a bypassing method. A bypassing method
returning a non-serializable value. An unmarked override that binary
code will call.

## Construction

- Pipeline steps are not called during object construction

```groovy
def config = new BuildConfig(readYaml(file: 'build.yaml'))
```

The step runs in the transformed caller; the constructor receives its
result.

Avoid: a step invoked in a constructor. A class whose initialisation
depends on a step's result.

## Trigger table

| Seen in the diff | Section |
|---|---|
| logic is added to pipeline code | Glue, not logic |
| a value crosses a step | Serializable state |
| a bypass annotation appears | Bypassing the transform |
| a class is instantiated in a pipeline | Construction |
