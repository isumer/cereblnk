# Cereblnk Plugin

Cereblnk turns Claude Code into an engineering organization: it reads
intent at three levels, decomposes work into independently verifiable
tasks, spawns specialist agents with isolated context budgets, and never
lets an answer reach the user without risk-scaled verification.

## What ships

| Component | Contents |
|---|---|
| `skills/` (top level) | 16 entry points — `cb-dispatch` routes automatically; the rest are typed |
| `skills/<group>/` | 77 domain skills: languages 19 · frameworks 16 · practices 21 · infrastructure 8 · data 7 · delivery 6 |
| `rules/` | 176 constraint files — the enforceable form of the skills, attached by glob and by detected stack |
| `agents/core/` | Planner, Verifier, Challenger, Consistency, Synthesizer |
| `agents/engineering/` | 13 specialists: Architect, Backend, Frontend, Security, QA, Performance, Database, APIDesign, Refactoring, Debugger, Infra, TestEngineer, XML |
| `agents/lifecycle/` · `agents/context/` | 3 + 5: TechnicalWriter and the context micro-agents |
| `hooks/` | 12 hooks — delegation, secrets, destructive commands, edit boundary, digest cap, context monitor, scratch guard, skill floor and ledger, run guard, post-edit test, history archive |
| `policies/` | 17 policies: risk, budgets, gates, agent selection, consensus, grounding, the run contract |
| `protocols/` | Agent Communication Protocol templates and schemas |

Lifecycle workflows — release, deploy, incident, retrospective, ADR,
changelog, health, memory management — are planned, not shipped.

## Enabling it every session

Installing the plugin is not the same as enabling it. Once installed,
commands, agents, and skills load automatically **only while the plugin
is enabled** in `settings.json` via `enabledPlugins`. Set it once and it
stays enabled across sessions — no reinstall, no per-session step.

**Personal (all your projects)** — add to `~/.claude/settings.json`:

```json
{
  "enabledPlugins": { "cereblnk@cereblnk-marketplace": true }
}
```

**Team / per-repo (shared, committed)** — add to the repo's
`.claude/settings.json` so every session opened in that repo has it on:

```json
{
  "extraKnownMarketplaces": {
    "cereblnk-marketplace": {
      "source": { "source": "github", "repo": "isumer/cereblnk" }
    }
  },
  "enabledPlugins": { "cereblnk@cereblnk-marketplace": true }
}
```

Project settings take precedence over user settings. Enabling from a
GitHub source in a shared `.claude/settings.json` does not silently
install it for teammates — each person is still prompted to trust and
install the plugin before it runs.

**"Installed but not working"?** Directory/local-marketplace installs
are a known gotcha: the plugin lands in `installed_plugins.json` but is
sometimes *not* added to `enabledPlugins`, so commands and hooks stay
silent. Fix: add the `enabledPlugins` line above by hand, then restart
the session.

Note: enabling loads the commands and skills; it does not guarantee the
`cb-dispatch` skill auto-triggers on a given message. For a
guaranteed entry point, start work with an explicit `/cb-` command.

## Skill Naming (binding)

Two name classes, one rule (CB-088):

- **Bare names** (`react`, `java`, `postgresql`) — domain skills. The
  frontmatter `name` equals the skill's directory name, always.
- **`cb-` prefix** (`cb-dispatch`, `cb-think`) — entry points: skills
  that start or route work rather than encode a domain. The prefix
  marks "invocable surface", not "skill vs command".

`scripts/check-skill-frontmatter` enforces both classes in `verify`
(F-1..F-5): frontmatter present, name matches dir or carries `cb-`,
description under 1024 chars, no duplicates. A SKILL.md without
frontmatter does not load — the checker exists so that failure cannot
be reintroduced silently.

## Design Guarantees

- **No unverified output.** Every workflow ends at risk-scaled quality
  gates (Verifier, Challenger, Consistency).
- **Context is not shared; knowledge is shared.** Agents receive
  compressed, evidence-preserving bundles — never the whole repository
  or conversation.
- **Epistemic labels survive to the user.** Every claim is marked
  Known, Derived, Estimated, Assumed, or Speculative — through
  compression and synthesis.
- **Decision-first output.** Fixed ordering: Decision → Evidence →
  Reasoning → Risk → Confidence.
- **Constraints follow the project, not the file type.** A framework's
  rules load when the glob matches *and* the detected stack declares
  that framework — `scripts/select-rules <path>` computes both halves.
- **The conductor never implements.** File edits during a run belong to
  the surface specialist; a hook enforces it rather than an instruction
  asking nicely.

## Running on a smaller model

The design bet is that most of what makes an answer good lives outside
the model, so a weaker session model fails less.

- **`policies/model-tiering-policy.md`** — a seating plan, not a model
  list. The plugin ships no model names. Planner, Verifier, Challenger
  and Synthesizer want the strongest tier; Consistency compares labels
  mechanically and wants the lightest; specialists inherit the session.
  `model:` in an agent's frontmatter is platform-enforced once set.
- **§4, weak-conductor topology** — a weaker model coordinates worse,
  not just builds worse. Fewer and larger slices; parallel specialists
  capped at the floor `scripts/select-agents` emits.
- **Plans on disk** — checkboxes and acceptance criteria in `plan.md`.
  Any model resumes after compaction via `plan-status`; each task can go
  to a fresh executor whose whole world is that one task.
- **Mechanical checks** — gates compare fact IDs and labels, hooks block
  on exit codes. Neither is impressed by fluent writing.

Two boundaries: the plugin does not connect Claude Code to a model of
your choosing, and the size of the effect is unmeasured. The mechanisms
are inspectable; the magnitude is not established here.

## Runtime Artifacts — always in the project, never in $HOME

Everything Cereblnk writes at runtime lives under the **project's own**
`.claude/cereblnk/` directory:

```
<project root>/.claude/cereblnk/
├── memory/      # briefs, promoted knowledge, evidence index
├── context/     # per-run ACP block ledger (file-mediated ACP)
├── telemetry/   # run summaries
├── flags/       # hook opt-in flags (/cb-careful, /cb-boundary)
├── config/      # e.g. test-command for PostEditTestHook
└── plans/       # durable implementation plans
```

Anchoring rules:

- Shell scripts and hooks resolve the location via `CB_DIR` in
  `scripts/lib/cbenv.sh`: `CLAUDE_PROJECT_DIR` → walk up to the
  nearest `.git`/`.claude` (never selecting `$HOME` — `~/.claude` is
  Claude Code's config, not a project marker) → otherwise CREATE
  `.claude/` right where you are, so a brand-new project without
  `.git` works immediately. When the cwd is a temp directory and no
  project exists anywhere, the absolute last resort is
  `$HOME/.claude/` — functioning beats dropping work; project
  locations always win when they exist.
- Agents and workflows resolve `.claude/cereblnk/` against the
  **project root**, not against wherever a `cd` left the shell mid-run.
- Nothing under these paths ships with the plugin, and the only thing
  that ever belongs in `~/.claude/` is your own optional personal
  `settings.json` above.
- Per-project state is per-project: two repos never share memory,
  plans, or telemetry.

## Context Headroom (long multi-agent runs)

The API reserves the maximum output size out of the model window:
input capacity = window − max output. On a 128K model with the default
32K output reservation, input capacity is 96K — a long level-3 run
that accumulates past that dies mid-flight with a context-length
error.

Two levers:

- Cereblnk's side (built in): file-mediated ACP — subagents write full
  Response Blocks to `.claude/cereblnk/context/<run>/` and return
  10-line digests, so the orchestrating conversation stays small
  (budget-policy rule 4).
- Your side, **unverified**: lowering the output reservation should
  raise the input ceiling. Example — 16K output ⇒ 112K input capacity.
  The variable is read by Claude Code itself at startup, not by this
  plugin, and open reports say it is not always honoured — including
  specifically for agent subprocesses, which is exactly the
  multi-agent case. Test it before relying on it: set it, restart, run
  a level-3 workflow, and read the `input_tokens` value in any failure.

  ```bash
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS=16000
  ```

  Tell Cereblnk the window in the same place, so the budget is
  computed rather than assumed — `scripts/context-budget` reads
  `CLAUDE_CODE_AUTO_COMPACT_WINDOW` for the capacity and
  `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` for the checkpoint:

  ```bash
  export CLAUDE_CODE_AUTO_COMPACT_WINDOW=96000
  ```

  Either place works. The shell is read at startup, so a change there
  needs a relaunch; a settings-file entry is reapplied to a running
  session when the file is saved. If both are set, the settings file
  wins — and `context-budget` resolves them in that same order, so it
  reports the value the session is actually using.

  or per repo in `.claude/settings.json`:

  ```json
  {
    "env": {
      "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "16000",
      "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "96000"
    }
  }
  ```

  Also worth doing before routing a big workflow in an already long
  conversation: `/compact` (the dispatch skill will remind you).

## Architecture

The full architecture — manifesto, runtime specification, ACP, context
OS, quality gates, and the cognitive operations manual — is published in
the project repository: https://github.com/isumer/cereblnk
