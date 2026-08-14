# Cereblnk Backlog

> Status: Living document. Location: `.claude/BACKLOG.md` — the only copy.
>
> **A one-line index of what shipped.** What each task did, and why,
> lives in `CHANGELOG.md`; the diffs live in git. Task blocks used to be
> reproduced here in full after closing, which grew the file to 74KB of
> history that nothing read.
>
> **Workflow per task**
> 1. Implemented on branch `cb/CB-XXX-slug`
> 2. Reviewed and merged into `main`, conventional commit title
> 3. Checkbox ticked with the merge
> 4. `./scripts/verify` green before any push
>
> **Rules.** A task with an untestable acceptance criterion is invalid
> (07 §3.1). No task may depend on an F-class mechanism
> (05_EXECUTION_REALITY_MAP.md). Prior art is described by class, never
> by name (00 §6, 01 §7).

---

## Open — 1.4.0: the host boundary

**Release branch.** This release lands on `feature/1.4.0`. Tasks are
implemented on `cb/CB-XXX-slug` branches cut from and merged into
`feature/1.4.0`; the release branch merges to `main` once, with a single
version bump. This deviates from the per-task-to-`main` workflow above
and applies to this release only.

**What 1.4.0 claims.** The platform gains a host boundary. The only
bound host is still Claude Code. Bindings for adjacent hosts are out of
scope: they depend on CB-122 output that does not exist yet, and a task
may not depend on an F-class mechanism.

**Mandatory order.** CB-127 → CB-128 → CB-124. Freezing the current
binding is what makes "nothing changed" provable; doing it after the
refactor proves nothing. CB-122, CB-123, CB-126 and CB-129 are
independent and may run in parallel.

### CB-168 — The host is not the service that answered it

Claude Code speaks its protocol to whatever base URL it is given, so the
same CLI is backed by a direct provider or a gateway depending on four
environment variables. Evidence that records only `claude` cannot tell
the two apart, and a run through a gateway establishes nothing about
direct provider authentication.

- **Provider selection.** Explicit configuration outranks inference, so a
  job that exported two credentials by accident is not described as the
  one it did not mean. The gateway path requires an empty
  `ANTHROPIC_API_KEY`; the presence test that predated it read that
  correct configuration as a missing credential.
- **`auth` is a stage.** `skill = BLOCKED, the provider refused` was
  readable and structurally ambiguous — the evidence could not answer
  whether authentication succeeded, so every later failure reopened a
  settled question. Five statuses unchanged; `REFUSED` is not one of
  them, and a rejection is `BLOCKED` with the reason.
- **Ours before theirs.** A provider mapping this repository built wrong
  produces a rejection indistinguishable from a bad key, so the
  configuration is judged before the request. That case is `FAIL`; an
  account problem never is.
- **One question, asked once.** The free tier meters requests per day,
  not tokens. Six stages each probing separately turned one question
  into six.
- **Publication is not production.** Evidence was appended, so a re-run
  left a column of near-identical tables where only the last was true.
  It is edited in place now, and a dispatch run — which has no pull
  request, and whose summary and artifact sit behind a storage host the
  review path cannot read — publishes to a tracking issue. That needs
  `issues: write` where a commit comment would need `contents: write`,
  which is permission to push code granted so a workflow can post a
  table.
- **One stage vocabulary, five copies.** The list is written down in the
  schema, this checker, both runners and the renderer. They are now
  required to agree mechanically, and each host's stages must appear in
  canonical order — an `auth` row printed after the capabilities it
  gates would describe a sequence that did not happen.

Phase 2 stays in CB-155: this measures that a session can start, not
that a skill, a delegation, a hook, a veto or a finish guard works. Those
remain `UNMEASURED`, which is the honest reading and the one the
acceptance criteria require.

**Does not close CB-131.** A provider accepting one prompt is not the
claimed runtime behaviour being measured.

### CB-169 — The verdict survived the subshell; the reason did not

The probe echoes its verdict, so every caller reads it as
`$(cb_auth_probe ...)` — a command substitution, which is a subshell.
The flag it discovered and the host's own words it captured were set
there and died there. The verdict crossed the boundary because it was
the thing being echoed, so the callers looked correct while every
reason they built read `invoked with '?'` and `no output`.

That sentence has been in published evidence since CB-164, including in
the results that were supposed to explain why three hosts failed. The
status was right each time; only the explanation was empty, which is
why nothing caught it and why a reader kept being told the probe did
not know how it had called anything.

The state file already crossed the boundary — it is how the answer is
cached so a metered free tier is asked once rather than six times.
Reading it back in the caller is the whole fix.

The suite now asserts that a reason names the invocation and quotes the
host, on both the refusal and the non-auth path. Removing the recall
turns that case red; the eleven cases that predated it stay green,
which is the shape of the gap that let this through.

### CB-170 — A stage should measure what its name claims

Two runs, two different models, one sentence: `Execution error`. The
controlled substitution settled that the failure is not the model, and
settled nothing else, because six words were all the probe could see.

- **The plugin stage did not measure the plugin.** The install was
  attempted, its outcome written down as an evidence line, and the
  status then set from `check-generated` — a local, host-free comparison
  `scripts/verify` already runs. A reader of a runtime table saw PASS
  and read "the plugin works on this host" while the log beside it
  recorded a refusal. The same concept already meant the stricter thing
  on another host, so the vocabulary disagreed with itself.
- **A refusal is named, not classified.** `claude plugin install <path>`
  was refused with a message about marketplaces, which is either a
  package this repository ships wrong or an invocation it builds wrong.
  Nothing available here separates them, so the status is FAIL and the
  reason quotes the host and says the question is open.
- **The cause outranks the wrapper above it.** The probe read the first
  non-empty line, and hosts announce a failure before naming it.
  Structured output is asked for where offered — the same single
  request, told to answer in a form that says more. A verbose flag would
  say more still and would print request headers into a log whose first
  lines are quoted into a public comment; that trade is not taken.
- **A timeout is not a refusal.** Exit 124 is the only thing separating
  them, and it is read before the log, because a run killed at the wall
  has no message to quote.
- **`$?` after an `if` is not the command's exit code.** An `if` whose
  condition fails and has no else exits 0, so the handler for a failure
  was reading success. Same masking this repository already refuses from
  a pipe, in a shape nobody had named.

Three of the first assertions written for this did not discriminate:
disabling structured parsing, removing the injection guard and turning a
plugin refusal back into PASS all left the suite green. Two matched the
same words through a different path and the third had no test at all.
Fixed, then all six mutations checked red.

**Does not close CB-131.** Minimal inference is still unproven; this
makes the next failure legible rather than making it pass.

### CB-171 — One reading of a host's output, not one per caller

The auth probe learned to prefer a structured field and to skip a
wrapper line that announces a failure without naming it. The plugin
stage kept its own earlier copy of the same judgement: first non-empty
line, then a cut. So the first real installation refusal reached the
reader as `Installing plugin ...Failed to` — the announcement, with the
cause sliced off, in the one field a reader had to work from.

Two implementations of one judgement drift, and the one that drifts is
the one nobody is looking at. There is now a single `cb_detail` and two
callers.

The stage also records what the subcommand documents it wants. A refusal
cannot distinguish a package this repository ships wrong from an
invocation this probe builds wrong, and a marketplace name and a
filesystem path are not the same request — the host had already written
down which it expects, in output the run already captured. Recording the
usage line settles that in the run that raises the question rather than
the run after it.

### CB-172 — The renderer was the layer doing the truncating

The table cell is bounded at 150 characters because a table is for
scanning, and that is right. But the first real installation refusal
reached readers as `Failed to…`, with the sentence naming the cause
past the cut — and two rounds of work went into the extractor that was
already producing the whole sentence.

Evidence lines were never rendered at all. A stage could record exactly
what the host documented it wanted, in output the run already captured,
and no reader would see it. `install_usage` was added to settle a
question and published into a field nothing displays.

Both facts existed and neither was readable, which is the failure this
renderer was built to fix in the first place. Full reasons and evidence
now appear below the table, still bounded, still unable to become a row
or a column.

### CB-173 — Quote the contract instead of pattern-matching it

Two bounds and one guess, all found by the same run.

The extractor cut at 200 characters, and the host writes its refusal on
one line: a spinner rewrites in place, so the progress text and the
failure arrive concatenated with the cause last. The cut landed
mid-filesystem-path, ahead of the sentence that explained anything. The
renderer bounds this again at its own limit, so the tighter number was
buying nothing and costing the finding.

`install_usage` grepped for a usage line shaped the way this probe
imagined it, matched nothing, and published an empty field — the same
mistake as guessing an invocation and reporting the failure as the
host's. The help output was already on disk. It is quoted now, bounded,
rather than searched for a shape somebody assumed.

The first version of the test for this did not discriminate: the fixture
put the failure on its own line, where 200 characters was enough. A
fixture that does not reproduce the shape of the real output tests the
fixture.

### CB-174 — Install by the name the host documents

`claude plugin install <path>` handed a filesystem path where the host's
own usage says `<plugin>` — a name, resolved through a marketplace, with
`plugin@marketplace` for a specific one. So the host searched its
registries for a plugin called `/home/runner/work/...`, truthfully did
not find one, and said so.

That was recorded as `plugin = FAIL`: this package rejected. Nothing
about the package had been tested. CB-170 made the stage measure what
its name claims and this was the same error one layer down — a probe
defect published as a defect in the tree, which is the attribution the
whole auth vocabulary exists to prevent.

Registration now comes first, because a name can only resolve through a
marketplace the host knows about, and the marketplace subcommand is
discovered rather than assumed. Identity is read from
`.claude-plugin/marketplace.json` rather than written here: a name
hard-coded in the probe would let the stage pass while the registry
declared something else, which is the stage measuring agreement with
itself.

The reason no longer says the cause is unestablished. It is established
now — the invocation matches the documented shape, so a refusal is about
the package or the registry. The earlier wording was honest when the
invocation was a guess, and would have been cover once it stopped being
one.

### CB-175 — What the host printed before the wall

The timeout branch recorded `no response within 120s` and stopped, on a
comment's own stated assumption: a run killed at the wall has no message
to quote. That was never measured, and it is exactly the observation
that separates the two remaining explanations for a silent host.

A CLI waiting on something interactive prints the prompt it is waiting
on. A request hanging at the provider prints nothing. Both arrive as
exit 124 and both were reported with the same sentence, which asserted
silence rather than observing it.

The log is read now before the claim is made, so `it printed nothing`
is a finding and `it had printed: ...` is a quote. Same single request,
no extra call against a metered free tier.

### CB-176 — The provider was never called

CB-175 quoted what the host printed before the wall, and it printed a
structured result: `is_error: true`, `duration_api_ms: 0`, `num_turns:
2`, zero tokens in and out, zero cost.

Zero API duration with zero tokens means no request was ever made. Seven
runs were spent on the provider and the model — swapping Nex for North,
reading vendor compatibility notes, reasoning about endpoints — and the
provider was never reached. Claude Code failed before calling it, wrote
its result, and then did not exit, which is what produced exit 124. The
timeout was never the finding; it was the CLI failing to close after
already saying what went wrong.

Two things kept that hidden. The kill truncates the JSON, so it will not
parse, and the fallback reads raw text — where the usage block had been
flushed first, spending the whole budget on zeroes and cutting before
the message. Named fields are now salvaged from whatever arrived.

And the counters are recorded separately, because they answer by
arithmetic what prose was being asked to answer: whether anything was
sent at all.

The counters were first emitted with `say` from inside the probe, which
runs in a command substitution and swallowed them — the same subshell
error as CB-169, made again while fixing its consequences. They travel
in the state file now, like the detail.

### CB-155 — Session drivers for the stages credentials unlock

CB-154 landed the runner, the Codex stage script and the workflow.
Everything a runner can establish without a model session is measured.
Everything past it is not: skill, agent, hook, veto and finish report
BLOCKED without credentials and UNMEASURED with them, because a session
driver — start a session, provoke a thing, read what happened — is not
written.

The veto driver is the one to write carefully, and the stage script says
so where whoever writes it will read it. A hook can print a refusal into
a stream nobody reads while the tool call goes through underneath, so the
assertion is that the target file was not written. Never that a message
appeared.

- **Deliverable.** Session drivers for the stages credentials unlock. The
  offline half is done (CB-156): every host now measures what a runner
  can reach without a session, and the stub scripts are gone.
- **Read `install_result` first.** CB-163 measures whether each host
  accepts the package. A driver written against a host that refuses the
  install has nothing to attach to, and the first credentialed run
  established that credentials do reach the stage scripts — `skill` came
  back UNMEASURED rather than BLOCKED — so the driver is the only thing
  missing, and the install result says whether it can work.
- **Acceptance.** With credentials configured, each stage returns PASS or
  FAIL on its own evidence rather than UNMEASURED. The veto stage asserts
  absence of the target file.
- **How to start it.** Configure CODEX_API_KEY, ANTHROPIC_API_KEY or
  GEMINI_API_KEY as repository secrets. The next push to a release branch
  runs the matrix with them; no dispatch and no token scope is needed
  (CB-158). Stages without a credential stay BLOCKED, so configuring one
  host does not require configuring all four.
- **Depends on.** CB-154, and credentials somebody decides to configure.

### CB-143 — Three hosts want the same hooks filename, and it is Claude's

This began as a Gemini question and is not one. Codex auto-discovers
`hooks/hooks.json`, Gemini reads it from the extension root with no
manifest field to point elsewhere, and Claude Code already owns it.
Cursor escapes only because its manifest redirect is accepted.

CB-148 sharpened the cost. On Codex, keeping the `hooks` field fails the
vendor's validator; dropping it loads Claude's binding, whose matchers
are Claude tool names — hooks that load and never fire. Neither end is
acceptable, and no manifest field resolves it on two of the three hosts.

Three ways out, weighed in `docs/hosts/gemini.md`:

1. **Install-time configuration.** Cheapest to try, works where a host
   layers hooks by scope. Does not help Codex, whose plugin hooks are
   discovered from the package.
2. **A host-specific distribution.** Build `dist/<host>/cereblnk/` from
   the core, where each host's conventional filename holds that host's
   generated binding. This is the only option that answers all three,
   and the reason it stopped being a preference: two hosts now force it.
   **`check-generated` must cover the built tree.** A `dist/` that drifts
   from its generator is the fork this whole binding layer exists to
   prevent, and it would be a quieter one than the problem it solves.
3. **Ship skills and sub-agents only**, and record that enforcement
   reaches one host.

- **Deliverable.** A decision, and if it is (2), a build step inside the
  drift gate rather than beside it.
- **Acceptance.** `check-host-matrix` reflects the outcome, and no host
  carries a binding that cannot be delivered.
- **Depends on.** CB-148 (measured), CB-145.

### CB-131 — The probe has to be run on the hosts it measures

CB-122 lands the harness and the discipline; it cannot land the evidence.
Cursor, Codex and Gemini profiles need those hosts installed and driven by
a person, including the two facts no recording of ordinary use shows: that
a refusal actually stopped an action, and whether an erroring hook fails
open or closed.

- **Deliverable.** `context/host-profile.cursor.yaml`,
  `.codex.yaml` and `.gemini.yaml`, produced by `host-probe collect
  <host> --write` after real sessions.
- **Acceptance.** Each profile records at least one event with its payload
  field names, and carries either an observation or a labelled attestation
  for `refusal_enforced` and `failure_mode`. A profile with no recorded
  events does not count as done — that is what `unmeasured` is for.
- **Operator task.** This is not implementable from a checkout; it needs
  the hosts. 1.4.0 does not reach main without it, which is correct: the
  matrix CB-125 publishes would otherwise be a table of guesses.
- **Procedure.** `scripts/host-probe install <host>` prints the config to
  paste and the stages to walk. Attest each stage as you reach it —
  install, context, skill, agent, subagent, hook, veto, finish — so a run
  that fails says which layer it failed at instead of returning one
  verdict for the whole host. Run it per host rather than working from
  this entry.
- **Cross-check already done (CB-135).** Candidate event names were
  widened against configurations other projects commit and run. One
  finding to carry into the run: a working Cursor configuration wires
  per-tool events and carries no generic pre-tool event, so a pre-write
  veto there may bind to several events rather than one. Treat it as a
  hypothesis the probe tests, not a result.
- **Depends on.** CB-122, CB-132.

---

## Closed

One line each. The full record of what shipped and why lives in
`CHANGELOG.md` from CB-013 onward, and in the commit history
throughout; the diffs live in git. Reproducing acceptance criteria and
deliverable lists here made this file 74KB of history that nothing
read.

- [x] **CB-001** — Marketplace and plugin manifests, repo scaffolding
- [x] **CB-002** — ACP templates and protocol README
- [x] **CB-003** — Risk model, budget policy, and gate policy
- [x] **CB-004** — Orchestrator entry: three-level intent reading and fast path
- [x] **CB-005** — PlannerAgent definition
- [x] **CB-006** — Verifier, Challenger, and Synthesizer gate agents
- [x] **CB-007** — Six engineering specialist agents
- [x] **CB-008** — /cb-pr-review workflow command
- [x] **CB-009** — /cb-bug workflow command
- [x] **CB-010** — Hard-enforcement hooks and opt-in commands
- [x] **CB-011** — Manual end-to-end scenarios for both Phase 1 workflows
- [x] **CB-012** — Core documents 00–09 and CONTRIBUTING.md published
- [x] **CB-013** — Phase 1 completion audit & repair
- [x] **CB-014** — Specialist agents, batch 1
- [x] **CB-015** — Specialist agents, batch 2
- [x] **CB-016** — /cb-frame (IntentFramingWorkflow)
- [x] **CB-017** — /cb-design (FeatureDesignWorkflow)
- [x] **CB-018** — /cb-implement (ImplementationWorkflow)
- [x] **CB-019** — /cb-qa (QAWorkflow)
- [x] **CB-020** — /cb-refactor (RefactoringWorkflow)
- [x] **CB-021** — /cb-security-audit (SecurityAuditWorkflow)
- [x] **CB-022** — /cb-docs (DocumentationWorkflow)
- [x] **CB-023** — skills/languages batch 1
- [x] **CB-024** — skills/languages batch 2
- [x] **CB-025** — skills/frameworks batch 1 (Spring)
- [x] **CB-026** — skills/frameworks batch 2 (UI)
- [x] **CB-027** — skills/frameworks batch 3 (testing)
- [x] **CB-028** — skills/data batch 1
- [x] **CB-029** — skills/data batch 2
- [x] **CB-030** — skills/infrastructure batch 1
- [x] **CB-031** — skills/infrastructure batch 2
- [x] **CB-032** — skills/delivery batch 1
- [x] **CB-033** — skills/delivery batch 2
- [x] **CB-034** — skills/practices batch 1
- [x] **CB-035** — skills/practices batch 2
- [x] **CB-036** — Reference coverage & originality audit
- [x] **CB-037** — Phase 2 test scenarios + docs update
- [x] **CB-038** — Working Memory hierarchy — status: done
- [x] **CB-039** — MemoryBuilderAgent + ContextArchivistAgent — status: done
- [x] **CB-040** — Evidence Index — status: done
- [x] **CB-041** — Consensus mechanics — status: done
- [x] **CB-042** — Context budget telemetry — status: done
- [x] **CB-043** — Orchestrator hardening — status: done
- [x] **CB-044** — Agent selection policy — status: done
- [x] **CB-045** — Repository map script — status: done
- [x] **CB-046** — Reader's guide + review disposition — status: done
- [x] **CB-047** — Dispatch skill (proactive workflow routing) — status: done
- [x] **CB-048** — Security-finding contract enforcer — status: done
- [x] **CB-049** — Security skill content pass — status: done
- [x] **CB-050** — RequirementsAgent + requirements-engineering skill + /cb-requirements
- [x] **CB-051** — Durable plan artifact: format, linter, status (the advisory-loop core)
- [x] **CB-052** — Durable execution loop: fresh executor, staged review, resume, stop-rule
- [x] **CB-053** — TestEngineerAgent
- [x] **CB-054** — Pyramid skills: test-strategy, unit-testing, integration-testing
- [x] **CB-055** — Automation + specialized-layer skills: bdd-gherkin, selenium-webdriver, component-testing, functional-testing
- [x] **CB-056** — Wire test skills into QAWorkflow + agent-selection-policy
- [x] **CB-057** — languages: python, go, kotlin
- [x] **CB-058** — frameworks: nodejs, nextjs
- [x] **CB-059** — data: oracle, redis, elasticsearch
- [x] **CB-060** — infrastructure: nginx, linux-ops, cloud-architecture, observability
- [x] **CB-061** — delivery: release-engineering, artifact-management
- [x] **CB-062** — practices: event-driven-architecture, microservices, performance-engineering, accessibility, technical-writing, legacy-modernization
- [x] **CB-063** — Agent frontmatter enrichment (skills / disallowedTools / model)
- [x] **CB-064** — Document extraction (docx/xlsx/pptx/pdf) — status: done
- [x] **CB-065** — OCR fallback (F-class) — status: done
- [x] **CB-066** — Skill relations metadata (requires / complements / escalate_to)
- [x] **CB-067** — XML/XSD create, parse, validate (tooling + skill)
- [x] **CB-068** — coding-standards skill + project standards bundle format
- [x] **CB-069** — DevSecOps deepening: supply chain, paved road, policy-as-code
- [x] **CB-070** — Integration hardening (reverted, then corrected)
- [x] **CB-071** — Windows Python + project-anchored runtime state
- [x] **CB-073** — Context ledger (root cause: 128K overflow, 37-minute run lost)
- [x] **CB-074** — HistoryArchiveHook (PreCompact)
- [x] **CB-075** — Run plan file
- [x] **CB-076** — Disposition record for the reverted integration work
- [x] **CB-077** — Run continuity + root-resolution hardening
- [x] **CB-078** — Implementation isolation (second 128K incident)
- [x] **CB-085** — Context gates (tool output · declared files · attempt ceiling)
- [x] **CB-086** — Artifact lifecycle (ownership · history/ · state.md · staleness gate)
- [x] **CB-087** — Input path (hat classification · inbox · guard window)
- [x] **CB-088** — Migration completion + checkers
- [x] **CB-089** — /cb-think (DeliberationWorkflow — divergent, file-backed)
- [x] **CB-090** — commands/ → skills/ entry-point migration (14 commands)
- [x] **CB-091** — Reconstruction checkers as code
- [x] **CB-092** — rules/: the constraint layer
- [x] **CB-093** — Skills for domains that have none
- [x] **CB-094** — Dynamic context budget
- [x] **CB-097** — Task-scoped skill loading
- [x] **CB-098** — Discovery cascade across the skill pool
- [x] **CB-099** — Staleness bounds on the run-active flag
- [x] **CB-100** — Rules layer: close the half-built axes
- [x] **CB-101** — /cb-do: direct execution without a spec
- [x] **CB-102** — Context monitor: the budget stops resting on a guess
- [x] **CB-103** — DelegationGuard named the wrong writer
- [x] **CB-104** — The front page stops lying about the repo
- [x] **CB-105** — History archived outside the runtime directory
- [x] **CB-106** — DelegationGuard blocked the conductor from its own plan
- [x] **CB-107** — Runtime state committed; scratch files left at the root
- [x] **CB-108** — Leakage check as a verify suite
- [x] **CB-108** — Constraint coverage, and what measuring it found
- [x] **CB-109** — Rules ignored the stack profile the project already computes
- [x] **CB-110** — Refactor scaffolding and the examples stub removed
- [x] **CB-111** — Prior art described by class, never named
- [x] **CB-112** — Document index: reach the right page without reading the book
- [x] **CB-113** — Execution floor: a surface cannot close unverified
- [x] **CB-114** — Reachability: new code that nothing calls is not done
- [x] **CB-115** — Runtime stage: environment lifecycle and health-gated attribution
- [x] **CB-116** — Cross-surface contract as a referenceable artifact
- [x] **CB-117** — The front page says what this is before how to install it
- [x] **CB-118** — Every README claim re-derived from the tree; five were wrong
- [x] **CB-119** — Architecture assets generated from the tree, not drawn then checked
- [x] **CB-120** — Correct and unread: the generated panels reverted for a systems note
- [x] **CB-148** — The Codex manifest fails its vendor's own validator, and the contract is now measured
- [x] **CB-167** — The leak guard ran after the thing it was guarding
- [x] **CB-166** — Correct evidence that nobody could read
- [x] **CB-165** — Seventeen of ninety-four was the right number, and the alarm was mine
- [x] **CB-162** — Closed by CB-165: the premise was wrong, no capability is lost
- [x] **CB-164** — A set variable was being read as a working credential
- [x] **CB-163** — Nobody had asked whether the host accepts the package at all
- [x] **CB-161** — Every host job held every provider's credential
- [x] **CB-160** — The Codex manifest was rejected for two reasons, not one
- [x] **CB-159** — A crashed validator was recorded as a rejected manifest
- [x] **CB-158** — The measurement sat behind a token scope instead of a decision
- [x] **CB-157** — A pull request probed one host and three drivers went untested
- [x] **CB-156** — All four hosts measure what a runner can reach without a session
- [x] **CB-154** — The runtime workflow, proven on one host before three inherit it
- [x] **CB-153** — Runtime evidence had no contract, so no artifact could be trusted
- [x] **CB-152** — A smoke run returned one verdict for the whole host
- [x] **CB-151** — The Codex manifest fails its vendor's own validator, measured by running it
- [x] **CB-150** — Gemini review: durable instruction separated from product policy
- [x] **CB-147** — Manifest review — displayName, convention discovery, a contested field recorded
- [x] **CB-146** — A session opened knowing nothing about the run it was resuming
- [x] **CB-145** — Gemini binds further than the first reading said
- [x] **CB-144** — Recovering a correction that missed its merge window
- [x] **CB-142** — Host references get a home in the frozen documents
- [x] **CB-141** — Gemini CLI stopped serving most tiers before this release
- [x] **CB-140** — Cursor gets manifests and a binding, declared from the reference
- [x] **CB-139** — Codex gets a binding, declared from the published reference
- [x] **CB-138** — Evidence has three states, and the middle one carries its citation
- [x] **CB-137** — The Codex manifests did not match the published schema
- [x] **CB-136** — Say bound host where the text meant Claude Code
- [x] **CB-135** — Cross-check candidate events against configurations that run
- [x] **CB-134** — Revert the split — compression did the job
- [x] **CB-133** — The gate always runs and says which case it is in
- [x] **CB-132** — Install prints a config the operator can paste
- [x] **CB-130** — A release branch reaches main empty
- [x] **CB-129** — The loop moves to a policy, the ceiling gets a checker
- [x] **CB-128** — The refusal is decided in eighteen places and expressed in one
- [x] **CB-126** — Manifests for adjacent hosts, without moving a file
- [x] **CB-125** — Every published matrix cell traces to evidence
- [x] **CB-124** — Concept to capability to host — the binding grows a middle hop
- [x] **CB-123** — A path named in a prompt has to exist
- [x] **CB-122** — Host capability is measured by running it, not read off a page
- [x] **CB-127** — The Claude binding is frozen before anything moves
- [x] **CB-121** — Rewrite: the old behaviour is ruled, not transcribed
