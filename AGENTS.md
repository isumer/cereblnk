# AGENTS.md

Instructions for any coding agent working in this repository. Host-specific
configuration lives elsewhere; this file is the part every host can read.

Cereblnk is a Claude Code plugin that encodes senior engineering craft as a
multi-agent architecture. As of 1.4.0 it has a host boundary but only one
bound host — see "Porting status" below before assuming anything else.

## Read the repository, not your memory

Counts, phases and task lists drift. Every question about the current state
has a file that answers it:

| Question | File |
|---|---|
| What ships | `README.md` |
| What each release contains | `CHANGELOG.md` |
| What is built and what is open | `.claude/BACKLOG.md` |
| Architecture, protocol, gates | `docs/00`–`docs/09` |
| Which mechanisms are real, per host | `docs/05_EXECUTION_REALITY_MAP.md` |
| Branch and commit conventions | `CONTRIBUTING.md` |

## The gate

```
./scripts/verify
```

One command, and it is the gate. Capture its exit code directly: piping it
into `tail` returns `tail`'s status and will let a red suite through.

Nothing is pushed on a red suite. `verify` covers the deterministic layer
only — workflow behaviour is not covered, and it says so on its last line
rather than letting a green run imply more than it checked.

## How work is done here

- **One task per branch**, named `cb/CB-NNN-slug`, with a conventional
  commit title. One version bump per change, not per commit.
- **A rule without a checker is a wish.** Every constraint that matters
  names the script that detects its violation. A directive with no checker
  is recorded as incomplete rather than counted as done.
- **Measure before claiming.** If a number appears in a document, something
  should be able to check it. Where measurement is absent, say so plainly
  instead of softening the claim.
- **Surface findings that complicate the task.** A premise that turns out
  to be wrong is worth more than a smooth delivery built on it. Say it
  early, with the evidence.
- **Change only what the task requires.** Mention unrelated problems;
  do not silently fix them.
- Artifacts — code, documentation, agent files, schemas, commit messages —
  are written in English regardless of the conversation language.

## Authoring genres

Three genres are linted by `scripts/authoring-lint`, and each has bands a
file has to stay inside:

- **Judgment** (`SKILL.md`) — path language, very little code.
- **Recipe** (`PATTERNS.md`) — mostly code, build tasks only.
- **Constraint** (`rules/`) — correct code shown; anti-patterns named but
  never demonstrated.

Skill files are additionally capped at 8192 bytes by `check-skill-size`,
which is the smallest adjacent host's packaging limit rather than a
preference of ours.

## Porting status

Claude Code is the only bound host. The binding runs concept → capability →
host: `plugins/cereblnk/policies/capabilities.yaml` names what must be
delivered, `policies/hosts/<host>.yaml` says which event delivers it there,
and `scripts/gen-bindings` emits the host's config from the two.
`scripts/check-generated` refuses any drift between a committed binding and
its generator.

Capability claims for other hosts come from `scripts/host-probe`, which
records what a host actually does. Anything a run has not established reads
`unmeasured` and must not be filled in from documentation — vendor pages on
this subject have contradicted themselves across quarters, which is why the
probe exists.

## Prior art

Reference implementations are described by class — a skill-first toolkit, a
broad multi-harness toolkit — and never by name. Methodology may be
adapted; names, directory structures and sentences may not appear here.
