# Contributing to Cereblnk

## Source of truth

The documents under `docs/` (00–09) govern everything in this
repository. `00`–`04` and `09` are **frozen**; `05` (Execution Reality
Map) and the backlog are **living**. Every artifact must be consistent
with the frozen documents.

## Amendment protocol (frozen documents)

Frozen documents change only through an explicit amendment recorded in
the document's Amendment Log, stating:

1. the section,
2. the old text,
3. the new text,
4. the reason,
5. the impact on existing artifacts.

Silent drift is prohibited. Reality Map (05) changes are announced in
the PR that makes them.

## Branch and commit conventions

- `main` is protected; work happens on feature branches named
  `cb/CB-XXX-slug` (matching the backlog task id).
- Conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:` —
  one task per PR, PR title = the conventional commit line.
- Releases are tagged; the plugin `version` in
  `plugins/cereblnk/.claude-plugin/plugin.json` is bumped in the same
  change as the tag.
- **Install the push gate once per clone:**
  `git config core.hooksPath .githooks`. It runs `scripts/verify`
  before a push and refuses a red one. `--no-verify` bypasses it
  deliberately, and the pull request says why.
- **One version per change, never per commit.** A behavior-changing change
  bumps the patch (or minor) once and adds one CHANGELOG entry. A
  growing PR that lands several batches as commits still carries a
  single version and a single entry — later commits extend that entry
  rather than adding a new heading. Bumping per commit produces a
  changelog of phantom releases; this line exists because that mistake
  is easy to repeat.

## Artifact rules (07 §4)

- English only in all artifacts.
- Agents follow the 6-item structure in 07 §4.1; skills follow the
  9-section structure in 01 §9 with a Philosophy per 09 Part IV.
- Every ACP example must validate against
  `docs/02_AGENT_COMMUNICATION_PROTOCOL.md`.
- Every Discipline-class rule must name the agent or gate that detects
  its violation.
- Principles 9–10 bind contributions: minimum artifact, surgical diffs.

## Local testing

```
/plugin marketplace add ./cereblnk
/plugin install cereblnk@cereblnk-marketplace
```

Then run the scenarios under `tests/` before opening a PR.

## Versioning

Every change to plugin behavior bumps the patch version in
`plugins/cereblnk/.claude-plugin/plugin.json` and adds (or extends)
the matching `CHANGELOG.md` entry in the same PR. Docs-only PRs are
exempt. Minor bumps add capability; major bumps change something a
user depends on. Tags are cut on `main` after
merge, at the maintainer's discretion.
