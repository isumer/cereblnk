# Changelog

All notable changes to Cereblnk are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Frozen core documents (00–09) change only through explicit amendments
recorded in their own Amendment Logs; this file records what shipped.

## [1.2.0] — Something in the run finally executes

Every gate in a run was static. VerifierAgent read code, ChallengerAgent
attacked reasoning, ConsistencyAgent compared claims — none of them
touched a running program. A specialist could write a module, never
execute it, and close green: "it works" was unfalsifiable rather than
verified, and the one failure mode that survives every static check —
code that is correct and never wired in — passed straight through.

### Added

- `policies/surface-map.yaml` — resolves a changed path to a surface
  (ui, api, db) by path segment, then by extension. Deliberately coarse:
  a wrong label costs a redundant check, a missing one costs an
  unverified close.
- `hooks/scripts/exec-ledger.sh` (PostToolUse) — records two facts into
  the run ledger: which surfaces a specialist edited, and which surface
  check commands it ran. Observation only; a recording hook that can
  fail a tool call would trade a verification record for a broken
  session.
- `hooks/scripts/exec-floor.sh` (SubagentStop) — exits 2 when a
  specialist finishes without running a surface it changed, returning it
  to work with the command it should have run. Nudge-capped and
  fail-open, in `skill-floor.sh`'s shape.
- `config/check-command.<surface>` — single-line, user-supplied, per
  surface. A surface with no configured command is recorded as skipped
  and allowed through: the gap stays visible in the ledger rather than
  turning a project red for a command it was never given.
- `scripts/test-exec-floor` — 14 checks over recording, blocking, the
  satisfied path, the unconfigured skip, loop safety, and the nudge cap.
  Added to the `verify` loop.

### Changed

- `docs/05_EXECUTION_REALITY_MAP.md` gains a surface execution floor row
  (M). The map was silent on execution, which let the docker skill's
  "run the container and send the real signals" and /cb-qa's F-class
  execution ban coexist without the contradiction being visible.
- README contents line: 15 hooks, 24 verify suites.

## [1.1.0] — Documents become navigable

`docparse` answers "what does this file say" by handing back the whole
document. Past a few thousand tokens that is the wrong question: the
agent needs to reach one clause, and could only get there by reading
everything — on the first turn, and again on every turn after it.

### Added

- **`policies/document-sections.yaml`.** The section-keyword set used
  when a document declares no headings, as data rather than as literals
  in the parser. Any such set is arbitrary; hardcoding one privileges
  whichever languages its author worked in and marks nothing as absent.
  Extending it is an installation's decision about the documents it
  holds, and needs no code change. A missing or empty list degrades to
  numbered heads and the window fallback — never to a failed index.
- **`scripts/docindex`.** Extracts a document once, keyed by the sha256
  of its own bytes, and writes a map beside the text under
  `.claude/cereblnk/docs/<doc_id>/`: `text.md`, `outline.json` (section
  → line range), `manifest.json`. An unchanged file re-resolves to its
  existing index for free; a changed file cannot collide with its own
  stale one, so there is no invalidation pass and no TTL. Plain-text
  sources are taken verbatim; everything else is delegated to
  `docparse`, whose exit codes pass through unchanged — "needs OCR"
  stays distinguishable from "failed to parse".
- **A segmentation ladder that reports which rung it used.**
  `structural` (headings the extracted text carries) is labeled `known`;
  `pattern` (section keywords from `policies/document-sections.yaml`,
  plus numbered heads) is `derived`; `window` (fixed line splits) is
  `assumed`. The label travels in the manifest and through
  DocIntakeAgent unchanged. Under `assumed` a section id names an
  arbitrary cut, and windowed sections carry no title rather than an
  invented one — a caller must not mistake a guess for a heading the
  document declared.
- **DocFloorHook (PreToolUse:Read), always on.** Blocks an unbounded
  read of an indexed document past the floor and returns the computed
  handoff: doc_id, section count, outline path, and the largest sections
  with their line ranges. It does not name the way around itself.
  Bounded reads, small documents, unindexed paths and non-`Read` tools
  pass untouched; two nudges per document, then it yields.
- **Documents enter the protocol.** ACP Amendment A1 (02 v1.0 → v1.1)
  adds the optional Task Block field `documents: [{doc_id, sections}]`
  and the evidence form `doc:<doc_id>#L<start>-<end>`. A long source
  used to reach an agent only as a path, and a path is an instruction to
  read all of it. The citation names lines and never a section id:
  section boundaries belong to the document only under a `structural`
  segmentation, so citing one under `derived` or `assumed` would anchor
  a claim to this platform's own guess.
- **`ground-check` resolves and tests document citations.** `doc:`
  references resolve through the index rather than the repository, and a
  dangling one fails as `G-2`. A fact may carry `quote:` beside its
  reference; when present the span must occur on the cited lines, and a
  quote that does not is `G-3` — a reference that resolves but does not
  say this. Quotes are scoped to their own fact, so two facts in one
  block cannot launder each other's evidence. Whitespace is normalised
  before matching: an extraction line break inside a sentence is an
  artifact, not a discrepancy.
- **`acp-lint` validates Task Blocks** (`T-1`): a malformed `doc_id`, an
  empty `sections` list, a section id that is not an outline id, a
  citation without a line range, an inverted range, and a citation that
  names a section instead of lines. `V-3` now accepts `doc:` where it
  required `CTX-` — without that, a fact read straight out of the named
  source would have been inadmissible.
- **`scripts/test-docindex`** (23rd verify suite). Asserts the layer
  *and* its label per document class, that section ranges tile the file
  without gap or overlap, that identity follows content, both directions
  of the floor including its nudge ceiling, and both directions of
  citation resolution.

### Changed

- **`parse_office.py` preserves Word heading levels.** `w:pStyle`
  (`Heading1`..`Heading9`, `Title`) now emits ATX headings in `md`
  output; `txt` output is unchanged. Structure was being read out of the
  file and discarded, which left the index guessing at boundaries the
  document already stated. Localized style ids are not matched and
  degrade to body text — a missed heading, never a wrong one.
  `d2-headings.golden.md` was re-blessed for this: the fixture carried
  `Heading1`/`Heading2` all along and the golden had been recording
  their loss.
- **DocIntakeAgent returns a map when a document exceeds its budget**
  instead of `blocked`. Size is not a failure to read, and reporting it
  as one described a solved problem as an unsolved one.

### Fixed

- **`ground-check` was never loading `cbenv.sh`.** It sourced
  `scripts/lib/cbenv.sh`, a path that does not exist — the repo-root
  `scripts/` has no `lib/`. The `|| PYBIN=python3` fallback was
  therefore the only branch that ever ran, and `$CB_DIR` was always
  empty. Nothing depended on it before, so nothing failed; the first
  thing that needed it was `doc:` resolution.

## [1.0.0] — First release

An adaptive multi-agent engineering platform for Claude Code: a
conducting conversation that reads intent, routes work to specialist
subagents, and refuses to hand back an answer that nothing checked.

### What ships

- **16 entry points.** `/cb-dispatch` reads a plain-language request and
  routes it; the rest are typed directly — deciding (`think`, `frame`,
  `requirements`, `design`), building (`do`, `implement`, `refactor`),
  checking (`pr-review`, `bug`, `qa`, `security-audit`, `docs`), and two
  session guards (`careful`, `boundary`).
- **26 specialist agents** across core, engineering, lifecycle and
  context roles, each with a stated decision domain and an advise-only
  boundary. An agent does not decide outside its expertise.
- **77 domain skills** — how an expert thinks in a stack — plus **176
  constraint files** carrying the enforceable form. Constraints attach
  by file glob and by the detected stack: a framework's rules load only
  when the project declares that framework.
- **12 hooks**, spent only where a mistake is expensive: delegation
  during an active run, secrets in a write, destructive shell commands,
  edits outside a declared boundary, oversized subagent returns, window
  occupancy, transcript archiving before compaction, and scratch files
  at the repository root.
- **17 policies** covering risk, budgets, gates, agent selection,
  consensus, grounding, and the run contract.
- **22 verify suites** — one deterministic pass over manifests, hooks,
  parsers, linters, the agent–skill graph, and the discovery cascade.

### How it works

Context is not shared; knowledge is. Subagents write their full
Response Blocks to disk and return a ten-line digest, so the conducting
conversation holds decisions rather than file contents. Budgets are
computed from the measured window, never assumed. Every claim carries an
epistemic label — known, derived, estimated, assumed, speculative — and
those labels survive summarisation all the way to the user.

Verification is structural rather than stylistic. A Verifier re-derives
the result from evidence without reading the original reasoning; a
Challenger must construct a concrete counter-scenario or state that none
exists; a Consistency pass compares fact sets across agents. How many of
the three run is decided by risk, not by preference.

### Honest boundaries

- `scripts/verify` green covers the **deterministic** layer: guards,
  parsers, linters, the skill graph. It does not verify workflow
  behaviour, which is prompt-driven and can only be established by
  running the workflows.
- Budget enforcement, ACP conformance, and gate blocking are
  Discipline-class: enforced by instructions and checking agents, not by
  the platform. `05_EXECUTION_REALITY_MAP.md` states which mechanisms
  are real and which are convention.
- Lifecycle workflows — release, deploy, incident, retrospective, ADR,
  changelog, health, memory management, session continuity — are
  planned, not shipped.
- Agent-to-agent messaging is deliberately absent. Agents exchange
  structured blocks through the conductor; there is no side channel, and
  that is a design commitment rather than a gap.
