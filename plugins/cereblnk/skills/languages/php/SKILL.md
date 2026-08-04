---
name: php
description: How to reason about PHP — a request-scoped runtime, types the engine may not enforce, and a framework that decides more than the code shows. Use for any .php implementation or review. Constraints in rules/languages/php/.
---

# PHP Skill

## 1. Identity
name: php · domain: languages
complements: api-design
escalate_to: owasp-threat-modeling (untrusted input surfaces)

## 2. Mission
Everything is request-scoped until something makes it otherwise. Ask
what survives the request before reasoning about state.

## 3. Philosophy

**Reading requests.** "It works locally" is a runtime question here.
Which version, which extensions, which type mode? "Add validation"
usually means the framework already validates somewhere, and a second
place will disagree with the first.

**Where risk lives.** Type coercion at boundaries the engine does not
police. Arrays standing in for models, so a missing key is a runtime
surprise. Superglobals read directly. And state that unexpectedly
outlives a request in a long-running worker.

**Verification here.** Read whether strict types are declared in that
file; the same code behaves differently without it. Check the static
analyser's output, not the annotation. A framework behavior claim is
verified against the version in the lock file.

**False-competence traps.** Array shapes documented in a comment and
enforced nowhere. Loose comparison on user input. A null coalesce
hiding an absent key that signals a real bug. Validation duplicated in
controller, service and model, each slightly different.

**Instincts.** Strict types on. Typed properties and return types
everywhere new code allows. Value objects instead of associative
arrays across boundaries. One validation place per input.

## 4. Decision Strategy — the paths

**A file is added**
→ Declare strict types. Without it the same signature accepts values
  it will later mishandle.

**An array crosses a boundary**
→ Make it a typed object. A missing key inside an array is found by a
  user, not by the analyser.

**A comparison is written**
→ Use strict comparison. Loose comparison on external input has
  surprising results that differ across versions.

**Input arrives from the request**
→ Validate once, in one named place, producing a typed object. Three
  validators will disagree eventually.

**A value may be absent**
→ Decide whether absence is legal. Null coalescing turns a bug into a
  default silently.

**Code runs under a long-lived worker**
→ Ask what state survives between requests. Static properties and
  singletons that were harmless per-request now leak.

**A framework behavior is relied on**
→ Check the version in the lock file. Behavior moves between majors
  and the documentation you are reading may not match.

## 5. Inputs
Source with line refs. Runtime version and enabled extensions.
Dependency lock file. Static analyser output. The framework's
configuration for anything it decides implicitly.

## 6. Outputs
ACP Response Block only. Facts labeled. A type claim is `known` only
against analyser output on that file. Framework behavior claims cite
the locked version.

## 7. Quality Gates
- Every new file declares strict types.
- Every external input is validated once, into a typed object.
- Every framework claim names the version it was checked against.

## 8. Failure Modes
- A missing array key surfacing as a user-visible error.
- Loose comparison accepting input the domain rejects.
- Three validators disagreeing about one field.
- Per-request state leaking between requests under a worker runtime.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/php/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | a file with no strict types declaration | silent coercion |
| 2 | an associative array crossing a layer | unenforced shape |
| 3 | loose comparison on request data | version-dependent result |
| 4 | validation in more than one place | rules that will diverge |
| 5 | null coalescing over a required value | bug defaulted away |
| 6 | static state under a worker runtime | leak between requests |
| 7 | framework behavior cited with no version | documentation drift |

## 9. Worked Example
Claim: "the endpoint validates the payload." Evidence: the controller
checks three fields; the service re-checks two with different rules.
Path fires: validation in more than one place. Verdict: weakened
(Known: both sites, file#L). One accepts what the other rejects. Fix:
validate once into a typed object and let the service trust the type.
