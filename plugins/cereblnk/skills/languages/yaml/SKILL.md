---
name: yaml
description: How to reason about YAML — a configuration language whose parser guesses types, whose whitespace is syntax, and which usually describes something irreversible. Use for manifests, values files, pipeline definitions, and application configuration. Constraints in rules/languages/yaml/.
---

# YAML Skill

## 1. Identity
name: yaml · domain: languages
complements: kubernetes · helm · github-actions · spring-boot
escalate_to: kubernetes (cluster semantics) · helm (templating) · devsecops (secrets in config)

## 2. Mission
The file is data, but the system it configures is production. Read
what the parser produces, not what the text looks like.

## 3. Philosophy

**Reading requests.** "Fix the config" is rarely about syntax. It is
about what the parsed document becomes. A working file and a broken
one often differ by two spaces. "Add a value" hides the question of
which environment inherits it, and which override wins.

**Where risk lives.** Implicit typing, where an unquoted token becomes
a boolean or a number nobody intended. Indentation, which is syntax
rather than style. Merge order across environment files. And secrets,
because configuration is where they get committed.

**Verification here.** Read the parsed result, not the source. A claim
about a value is checked by rendering the document and reading the
output. For a merge, render the final composition, never reason about
precedence from memory.

**False-competence traps.** A country code parsed as a boolean. A
version quoted in one file and bare in another. An anchor reused after
its content changed. A validated schema that no pipeline runs.

**Instincts.** Quote anything ambiguous. Render before believing. Keep
one document per concern. Treat every environment file as a diff
against a base, and read the diff.

## 4. Decision Strategy — the paths

**A scalar is written unquoted**
→ Ask what the parser makes of it. Country codes, versions, times and
  identifiers turn into other types silently.

**Indentation changes**
→ Re-render. A shifted block changes ownership, not appearance, and
  the file still parses.

**Values merge across files**
→ Render the composition. Precedence between base, environment and
  command-line values is not readable from any single file.

**An anchor or alias appears**
→ Trace what it points at now. An anchor is resolved at parse time,
  and its content may have moved on.

## 5. Inputs
The documents and their merge order. The rendered composition. The
schema, where one exists. The consumer's expectations for types.

## 6. Outputs
ACP Response Block only. Facts labeled. A value claim is `known` only
against rendered output; reading the source yields `derived`.

## 7. Quality Gates
- Every ambiguous scalar is quoted or its parsed type is stated.
- Every multi-file configuration claim cites a rendered composition.
- No secret appears in a committed document.

## 8. Failure Modes
- A boolean where a string was meant, changing behavior silently.
- A block that moved one level and now belongs to another key.
- An environment override that never applied because of precedence.
- A credential committed in a values file.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/yaml/`:
`coding-style` · `patterns` · `security`.

Before producing or reviewing configuration, read the files whose
`paths:` glob matches what the task touches, plus `rules/common/` once
per run. Cite a violated constraint by file and section. Selection
rules: agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | unquoted country code, version, or time | implicit retyping |
| 2 | indentation changed in a review | silent reparenting |
| 3 | claim about a merged value, no render | precedence assumed |
| 4 | anchor reused far from its definition | stale resolution |
| 5 | a credential in a committed file | exposure |
| 6 | schema present, no validation step | unenforced contract |

## 9. Worked Example
Claim: "the region is set to `no`." Evidence: the value is unquoted.
Path fires: an unquoted token retyped by the parser. Verdict: refuted
(Known: rendered output shows `false`). Fix: quote it, re-render, and
add a schema check so the class of failure is caught next time.
