# Authoring Style Policy

Class: **D** with an **M** checker: `scripts/authoring-lint` measures
every migrated artifact; violations fail `scripts/verify`.
This governs how WE write plugin artifacts. It does not govern user
code — that is `rules/`.

## The three genres

Every knowledge artifact is exactly one genre. The genre sets the
language, the code ratio, and the lint thresholds (all derived from
measurement, 2026-07-21).

| Genre | File | Language | Code | Sentence cap |
|---|---|---|---|---|
| **Judgment** | SKILL.md | path language: state → decision → reference | ≤5% | avg ≤12 words |
| **Recipe** | PATTERNS.md | heading → complete implementation | ≥60% | — |
| **Constraint** | rules/**.md | one-line principle → correct example | 35–60% | avg ≤15 words |

## Genre rules

**Judgment (SKILL.md).** Short simple sentences put the model on a
path; they do not describe. Decision Strategy is a path tree:
condition → action → reference (PATTERNS §n, rules file, escalation).
No inline recipes. The frozen nine-section skeleton (01 §9) and the
five Philosophy elements (09 Part IV) are preserved — compressed,
never removed. Epistemic labels, Law-1 boundaries, and escalate_to
chains survive verbatim.

**Recipe (PATTERNS.md).** Loaded for build/implement tasks only —
never by review agents (budget policy). Positive code only. Each
recipe: heading, one-line "when", the full implementation. Version
assumptions declared in frontmatter (`react: ">=18"`). A recipe never
restates a rule; it references it.

**Constraint (rules/).** Positive examples only. Anti-patterns are
NAMED in one-line bullets, never exemplified in code — bad code in
context is bad code in context. Detection lives in the trigger table.
Exception: Common Errors tables may quote error-message STRINGS.

## Shared patterns (from reference-corpus analysis)

- **Pre-flight questions** — build-oriented skills may open with
  numbered mandatory questions answered before any code.
- **Checklists by domain type** — mechanical domains get a Detection
  Table (grep-level observables); taste/quality domains get a Review
  Checklist of observable OUTCOMES. Never fake a grep table for taste.
- **Anti-patterns are instance-level** — "no cards inside cards", not
  "maintain visual hierarchy". Concrete bans beat principles.
- **Numbered imperative workflows** — commands state what they do as
  1..N imperative steps, and carry one worked Example Session.
- **Related block** — every command declares its fixed bindings:
  agent · skills · rules · gate level.

## The refactor procedure (mandatory per artifact)

1. Read ours. 2. Locate the reference-corpus counterpart(s) in
the source documents named by the task; read them. 3. Filter: list what
they cover that we miss, what we cover that they miss, what they do
better structurally. 4. Rewrite in the target genre, adopting
structure and coverage — **never sentences, code samples, or names**
(00 §6 originality holds; grep-audited). 5. Run `authoring-lint`;
nothing to register — `authoring-lint` derives the genre from where
the file sits. 6. Record the filter
notes in the map (one line).

Invariants per migration: every TRIGGER/VIOLATION, epistemic label,
Law-1 boundary, escalate_to, and ACP contract survives. Only prose
compresses.
