# Changelog

All notable changes to Cereblnk are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Frozen core documents (00–09) change only through explicit amendments
recorded in their own Amendment Logs; this file records what shipped.

## [1.2.3] — Two legs that each pass and still disagree

The three floors before this one are single-surface questions: did you
run it, is it reached, does it come up. A migration fails past all of
them. Each leg is internally correct, each runs clean, and they disagree
with each other — the client sends on the new channel and never
subscribes to the one the server publishes. Both specialists report
complete and the system does not work.

The cause is that the contract existed only as prose spread across two
sets of specs. Prose cannot be checked against code. A file can.

### Added

- `plugins/cereblnk/scripts/contract-check` — reconciles a contract
  under `memory/contracts/` against each surface's own files. Both
  directions: every channel the contract names must appear on the
  surface, and every path it replaced must be gone. Presence of the new
  without absence of the old is a half-done migration that reads as
  finished.
- `hooks/scripts/contract-floor.sh` (SubagentStop) — exits 2 when a
  specialist closes a surface that does not match its contract, naming
  the side and the channel.
- `plugins/cereblnk/scripts/lib/surfaces.py` — the surface-map reader,
  now shared. cbmap's reason: a checker that reads the map differently
  from the recorder will disagree with it eventually, and the
  disagreement will look like a bug in the project being checked.
- `scripts/test-contract-check` — 14 checks. Added to the `verify` loop.

### Changed

- `APIDesignAgent` is given the authoring mandate: when an interface
  spans more than one surface, the contract is written as an artifact
  rather than as a paragraph inside two sets of specs.
- `ExecLedgerHook` uses the shared surface reader instead of its own
  copy of the parser.
- `docs/05_EXECUTION_REALITY_MAP.md` gains cross-surface contract (M/D)
  and cross-surface parallelism (M) rows.
- README contents line: 18 hooks, 27 verify suites.

### Parallelism is preserved deliberately

Each party is judged only on its own files. The UI is asked whether the
UI carries every channel, never whether the backend is finished, so two
developers or two agents work at the same time and neither waits for the
other. This is a closing gate rather than a starting gate for the same
reason: the failure was never that a leg started early, it was that a
leg finished unmatched. A row that is genuinely later work is marked
`deferred` in the contract, with a reason.

## [1.2.2] — The surfaces come up together

CB-113 made a specialist run its own surface and CB-114 made it wire
what it wrote. Both are single-surface checks. Two legs can each pass
and still disagree with each other, which is the failure that costs a
migration: a client whose destination prefixes do not match the server's
is correct on both sides and broken between them. Observing that
requires the surfaces running at the same time.

### Added

- `plugins/cereblnk/scripts/env` — preflight, up, health, down, status.
  Reads `config/runtime.md` and runs the project's own commands;
  Cereblnk never writes a compose file for anyone.
- `hooks/scripts/env-teardown.sh` (SessionEnd) — reclaims an environment
  the session started and nothing took down. A compose project left up
  holds ports and volumes, and the next run's preflight then reads the
  leftover as somebody else's stack and skips: one forgotten teardown
  silently disables the stage for every run after it.
- `scripts/test-env-lifecycle` — 18 checks. Docker is never required:
  up and down are shell no-ops and health is a stdlib HTTP server on an
  ephemeral port. A suite needing a container runtime would make
  `verify` unrunnable on the machines most likely to run it.

### Changed

- `/cb-qa` gains the runtime stage, and its execution sentence is split.
  Bringing a system up and polling health is real; driving a browser is
  not. The two were stated as one F-class ban, which is why the docker
  skill's instruction to run the container and the workflow's ban on
  execution could both stand without the contradiction being visible.
- `DestructiveCommandHook` covers `compose down` with volume removal,
  `docker volume rm/prune`, `docker system prune` and forced container
  removal. SQL DROP was blocked while the command that deletes the
  database's volume was not.
- `docs/05_EXECUTION_REALITY_MAP.md` gains environment lifecycle,
  health-gated attribution and teardown rows (M), and restates the
  browser row as the separate F-class mechanism it is.
- README contents line: 17 hooks, 26 verify suites.

### Safety property

Teardown never touches an environment this project did not start.
Preflight refuses to start when something already answers the health
URL, and `down` runs the command recorded in `flags/env-active` rather
than whatever config says at teardown time. A config edited mid-run
cannot redirect a volume-destroying command at somebody else's stack.

## [1.2.1] — Code nothing calls is not a finished change

CB-113 made a specialist run what it changed. Running does not catch the
failure that survives everything else: code that is correct in isolation
and never wired in. An exported function that is never called throws no
exception and logs no error — it fails by silence. Review passes, the
skill floor passes, the surface runs clean, and the specialist reports
complete.

### Added

- `plugins/cereblnk/scripts/reachability` — reports a symbol declared in
  a changed file whose identifier appears nowhere in the project outside
  its own declaration line. Covers TypeScript, JavaScript, Python, Go,
  Java and Kotlin declarations. Decorated and annotated declarations are
  exempt: a framework may be the caller. References from any file count,
  including route tables, configuration and tests — generous on purpose.
- `hooks/scripts/reach-floor.sh` (SubagentStop) — exits 2 on a report,
  naming each unreferenced symbol. Nudge-capped and fail-open, in
  `skill-floor.sh`'s shape.
- `config/reachability-ignore` — one symbol per line, for a deliberate
  public surface with no in-repo consumer.
- `scripts/test-reachability` — 16 checks across the analyser and the
  hook. Added to the `verify` loop.

### Changed

- `ExecLedgerHook` also records edited paths to `edited-files.log`.
  Surfaces and paths are separate ledgers with separate readers rather
  than one file whose fields mean different things to each.
- `docs/05_EXECUTION_REALITY_MAP.md` gains a reachability floor row (M),
  stating the recall limit rather than implying coverage: transitive
  orphans, where dead code references dead code, are not detected.
- README contents line: 16 hooks, 25 verify suites.

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
