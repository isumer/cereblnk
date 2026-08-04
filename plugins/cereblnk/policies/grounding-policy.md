# Grounding Policy — Hallucination Countermeasures

Class: **D** with an **M** checker: `scripts/ground-check` validates
every file/line reference in a Response Block against the repository;
the orchestrator runs it beside acp-lint (checklist V-3's mechanical
deepening). Fluent confabulation is the most expensive failure this
platform has (Law 5); these rules make its common forms impossible or
loudly labeled.

## The five rules

**G-1 — Cite only what you opened.** A file, line, symbol, or config
value may be cited as evidence only if it was read in THIS run. Memory
of "how such files usually look" is Assumed, and says so.

**G-2 — Referenced things must exist.** Every `path#Lstart-Lend` in a
block must point to a real file and a real line range. ground-check
verifies mechanically; a dangling reference discards the block (02 §7).

**G-3 — Versions and APIs carry a source.** A claim about a library
version, API signature, or framework behavior names its source (lockfile
line, imported code, official doc fetched this run) — or is labeled
Assumed. PATTERNS.md files declare version bounds in frontmatter.

**G-4 — Numbers come from measurement.** Any quantity (latency, count,
size, coverage) is Known only with the measuring command and output in
evidence; otherwise Estimated with a stated basis, never bare.

**G-5 — "I don't know" is a valid outcome.** An unknown reported in
ACP `unknowns` outranks a plausible guess. No agent is ever penalized
for a blocked/unknown outcome; every agent is accountable for a
confident wrong one.

## Where each rule is enforced

| Rule | Mechanism |
|---|---|
| G-1 | Verifier re-derivation (04 §3.1) — unopened citations fail re-derivation |
| G-2 | `scripts/ground-check` (M) — dangling refs exit 1 |
| G-3 | acp-lint V-3 evidence requirement + PATTERNS frontmatter |
| G-4 | authoring-style + gate review: bare numbers → Estimated downgrade |
| G-5 | ACP `unknowns` field is never compressed away (02 §4.2) |
