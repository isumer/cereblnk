---
name: groovy
description: How to reason about Groovy — three runtimes wearing one syntax, where a Jenkinsfile is transformed before it runs and a build script has phases. Use for Jenkinsfile, Gradle or Groovy source work. Constraints in rules/languages/groovy/.
---

# Groovy Skill

## 1. Identity
name: groovy · domain: languages
complements: java · jenkins-pipelines
escalate_to: jenkins-pipelines (pipeline topology) · java (JVM semantics)

## 2. Mission
Ask which Groovy this is first. A Jenkinsfile, a build script and
plain source share a syntax and little else.

## 3. Philosophy

**Reading requests.** "This works locally but not in the pipeline" is
usually not a language question. Pipeline code is transformed before
it runs. Constructs that work everywhere else behave counterintuitively
there. "Add a helper to the Jenkinsfile" hides where it should live.
Pipeline logic is glue. Build logic belongs in an external step.

**Where risk lives.** In a Jenkinsfile: serializability. The program's
state is written to disk at every asynchronous step. A non-serializable
value breaks resumption. In a build script: configuring versus
executing. Code in the wrong phase runs at the wrong time, or never.
In plain source: dynamic dispatch. A misspelled method is a runtime
failure, not a compile error.

**Verification here.** For a pipeline claim, name the transform. Read
whether the method is annotated to bypass it. Then read whether it
calls pipeline steps. The two are mutually exclusive. For a build
script, read which phase the code runs in. For plain source, check
whether static compilation is enabled.

**False-competence traps.** A bypass annotation added to clear an
error, on a method that calls a pipeline step. That combination is
illegal and behaves anomalously. Pipeline steps inside a constructor,
which the transform cannot handle. A lazy closure in an interpolated
string. Build logic accumulating in pipeline code.

**Instincts.** Keep pipeline code thin and push logic to a step the
agent runs. Keep values crossing a step serializable and simple.
Enable static compilation in plain source. Name the build phase before
placing code.

## 4. Decision Strategy — the paths

**Code is added to a Jenkinsfile**
→ Ask whether it is glue or logic. Logic belongs in a script the agent
  runs, because pipeline state is serialized at every step.

**A value is held across a pipeline step**
→ Confirm it is serializable. The program is written to disk at each
  asynchronous operation and resumed from there.

**A method bypasses the transform**
→ It may not call pipeline steps or transformed methods. Use it to
  compute a summary, then return the summary.

**A method overrides a binary one**
→ Mark it as bypassing the transform. Binary code will be the caller,
  and it cannot enter transformed code.

**A pipeline step appears in a constructor**
→ Move it out. Object construction is not something the transform
  handles.

**A build script is edited**
→ Name the phase. Configuration runs for every build; execution runs
  only for the tasks selected.

**Plain source is written**
→ Enable static compilation. Without it a misspelled method reaches
  production as a runtime failure.

## 5. Inputs
The file and its runtime: pipeline, build script, or plain source.
Annotations bypassing the transform, with what those methods call.
Values held across steps. Build phase for build-script claims. Static
compilation setting for plain source.

## 6. Outputs
ACP Response Block only. Facts labeled. A pipeline behavior claim is
`known` only with the transform and annotations named. A build-script
claim names the phase.

## 7. Quality Gates
- Every Jenkinsfile addition is justified as glue, not logic.
- Every bypassing method is free of pipeline steps.
- Every plain-source file states whether static compilation applies.

## 8. Failure Modes
- A pipeline that cannot resume, because a held value is not serializable.
- A bypassing method calling a step, behaving anomalously.
- Build-script code running during configuration for every build.
- A misspelled method reaching production in dynamic code.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/groovy/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | logic accumulating in a Jenkinsfile | state serialized per step |
| 2 | a non-serializable value held across a step | resumption breaks |
| 3 | a bypassing method calling a pipeline step | illegal combination |
| 4 | a binary override without the annotation | caller cannot enter |
| 5 | a pipeline step inside a constructor | transform cannot handle it |
| 6 | build-script code with no named phase | runs at the wrong time |
| 7 | plain source with dynamic compilation | typos become runtime failures |
| 8 | a lazy closure in an interpolated string | evaluated per use |

## 9. Worked Example
Claim: "the helper is fine, it is annotated to bypass the transform."
Evidence: the annotated method calls a pipeline step inside a loop.
Path fires: a bypassing method calling a pipeline step. Verdict:
refuted (Known: method body, file#L). The log reports catching the step
instead of the method. Fix: remove the annotation, or move the loop to
the transformed caller and keep the annotated method to computation.
