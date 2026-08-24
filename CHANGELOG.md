# Changelog

All notable changes to Cereblnk are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Frozen core documents (00–09) change only through explicit amendments
recorded in their own Amendment Logs; this file records what shipped.

## [1.4.0] — What an outside test found, and what it cost to look

An external test journal ran 1.3.5 against a real Spring Boot fixture
and filed twenty-nine findings. Several describe mechanisms this
project advertises as enforcement that were, in an ordinary setup,
doing nothing at all — and saying nothing about it.

Minor rather than patch: `select-agents` gains surfaces, the flag
mechanism gains a subcommand, and root resolution changes for anyone
who opens a session above their project. Behaviour that was silently
absent becomes present, which is a change even when it is the change
that was always intended.

### The root was split, so the floors were not floors

`CLAUDE_PROJECT_DIR` won unconditionally, and only hooks receive it. A
script run by an agent walked up from `$PWD` instead. In a session
opened above the project — one workspace, several repositories, a
common arrangement — the two resolved different trees:

```
scripts (cwd inside the project)  -> <workspace>/cb-testbed/.claude/cereblnk
hooks   (CLAUDE_PROJECT_DIR)      -> <workspace>/.claude/cereblnk
```

`select-agents` writes the skill baseline under one; `skill-floor`
looks for it under the other, does not find it, and exits 0. Every
floor reads the run directory the same way. The enforcement layer was
not weakened, it was absent, and the only thing that would have said so
was the thing that was absent.

The same split disabled `/cb-careful` and `/cb-boundary`: both wrote
their flag with a relative path while the hooks read `$CB_DIR`. A
controlled experiment ran the same recursive delete twice — it
executed when the flag sat where the skill wrote it, and was blocked
when it sat where the hook looks. Both skills report the protection as
enabled either way. A system announcing a guarantee it does not hold is
worse than one with no guarantee, because the user then takes more
risk.

Resolution now prefers the nearest project marker at or below
`CLAUDE_PROJECT_DIR`. A marker outside it is ignored — the session
boundary is still a boundary. This does not converge every case: a hook
whose cwd is the session root and a script whose cwd is the nested
project still disagree, and `CB_ROOT_HINT` records the other candidate
so `run-flag` can say so rather than reporting a success the hooks
cannot see.

### Fixed

- **Subagent floors match identity on the last segment.** The baseline
  is keyed by policy role names; SubagentStop hands back whatever the
  harness has — measured as a bare hex id and as `general-purpose`.
  Neither matched, so the floor exited 0 for every real subagent while
  a synthetic payload engaged correctly. When the identity cannot be
  matched at all the floor now says so on stderr and still allows: it
  has no grounds to fail a subagent it cannot name, only grounds to
  admit it did not check.
- **Every shipped script is executable, and `check-exec-bit` looks.**
  `run-flag` shipped in 1.3.5 as the only non-executable file among
  twenty, and ten workflows name it as their first action —
  `Permission denied`, exit 126, and each of those skills then says a
  non-zero exit means the run is not guarded. The checker's rule set
  covered hooks and `scripts/verify`; X-3 now covers the package
  scripts too.
- **`careful`, `boundary` and `refactor` arm through `run-flag`**,
  which grows a `flag <name> arm|disarm` subcommand with optional
  content. One mechanism, verified after writing, for every flag rather
  than for one.
- **Shell, configuration and AI-configuration surfaces route.** `.sh`,
  `Makefile`, `.yaml`, `.xml`, `.toml` and the `.claude/` tree matched
  no rule, so a request about any of them fell through — while `.sql`,
  `.css` and `nginx.conf` resolved fine, which is why the stack gate
  they share was never the cause. Cereblnk's own tree is mostly shell.
- **Rules are addressed by name, not by index.** `RULES[5]` and
  `RULES[10]` were compiled into `UI` and `AUTHORED`; adding three rows
  above them repointed both at the wrong pattern, and the only thing
  that noticed was a fixture two suites away.
- **`digest-cap` prints a path an agent can act on.** It printed
  `{run}<task_id>.yaml` — a literal placeholder with no separator
  before it, resolving outside any run directory. Two specialists
  received it and both declined to follow it, which is the right
  outcome reached without the protocol's help.
- **The conductor may write its own run journal.** The block message
  counts verdicts among what the conductor holds and the ownership
  table had no path for one. Scoped to `context/<run>/*.md`:
  `memory/specs` remains the technical writer's surface, as the routing
  table says.
- **An assumed context window says so.** `context-budget` labels the
  window `source: assumed`; the monitor printed the derived percentage
  as fact. A session warned at 101.8% and 104.7% of a guessed
  denominator — a figure above 100 is the tell — and reshaped its work
  around it.
- **`check-agent-skills` ships with the plugin.** The policy cites it
  as a live guarantee; it lived in the repository `scripts/`, which the
  package does not carry. Moved rather than copied: two copies of a
  checker drift.

### What this does not claim

Twenty-nine findings were filed and this closes thirteen. Left open:
the discovery cascade has a parser and no caller, which is a design
question rather than a defect to patch; seventy-seven skills sit two
directories deep and the Skill tool only reaches the first level, which
needs a packaging decision; the DestructiveCommand hook matches
patterns inside heredoc data and blocks the escape its own message
recommends, which is its own release; and the `bin/` directory named in
`PATH` does not exist, which is harmless because every caller uses a
full path.

Four findings were not defects: one is Claude Code's scope, one was
resolved by `/reload-plugins` during the test itself, and two were
dispatch errors the journal records honestly as its own.

## [1.3.6] — A name nothing could spawn, and a refusal with no way out

Two corrections to routing, both to things this project shipped and one
of them added a release ago.

**The name.** The platform addresses an agent as
`cereblnk:engineering:docs-agent`. `select-agents` emitted `docs-agent`,
DelegationGuard copied that into `NEXT ACTION: spawn docs-agent`, and a
run did exactly what it was told — four times, each rejected with
`Agent type 'docs-agent' not found` and answered with the full 27-agent
roster, until the model reverse-engineered the shape from the error.

Nothing in the tree carried the qualified form. Not the agent
frontmatter, not TOPOLOGY, not the policies. It existed only as a
directory path nobody surfaced, while the one component that owns the
roster and knows where every file lives printed a name the spawn API
does not accept. A routing table whose output cannot be handed to the
API it routes for is a suggestion, not a mechanism.

**The refusal.** 1.3.1 fixed a real loop: the unresolved message
answered a `--text` call by asking for a `--text` call. The fix went
further than the loop and added that reading the policy by hand "is not
the fallback." That closed the only route a caller had left, and the
route offered instead — resolve the request to a repository path — does
not exist for every surface. A request to restructure `.claude/` or
`CLAUDE.md` names configuration, the rule table has no configuration
surface, and so no path resolves. Observed as a run cycling through
candidate agents for minutes and reaching none.

Forbidding the remaining option without opening another is worse than
the loop it replaced. A wrong specialist chosen out loud is visible and
correctable; a run that cannot proceed at all is neither.

### Fixed

- **`select-agents` emits spawnable names.** `specialists:` and the
  `skills_required` keys both carry `cereblnk:<dir>:<name>`, derived
  from where the agent file actually lives. A name with no agent file
  passes through unchanged rather than being invented. DelegationGuard's
  handoff carries the same form, and `acp-lint` takes the last segment
  before checking the roster, so a block naming its agent correctly is
  not the one the linter rejects.

### Changed

- **Unresolved now infers a specialist instead of refusing.** The
  refusal was built to force a human choice. It never produced one:
  twice it produced improvisation — a specialist invented out of a
  project's skills directory, and minutes of cycling through
  candidates. The rule table is permanently incomplete, so the branch
  this fires on is not an edge case to be closed but a standing
  condition, and an unrecorded guess is precisely what refusing was
  meant to prevent.

  So the run proceeds with `architect-agent` — by elimination, a
  request naming no code surface is about structure, boundaries or
  setup, and an agent that decides rather than implements does the
  least damage when the inference is wrong. What survives from the old
  behaviour is the half that mattered: `inferred: true` in stdout, a
  `signals:` line saying the choice was inferred and not routed, and
  the stderr note unchanged. A wrong default is visible and
  correctable; a model choosing quietly never was.

  A risk gate was designed and dropped as dead code. Payment, auth,
  migration and deploy all resolve through the text rules already, so a
  high-risk request never reaches this branch. The one that did —
  secret rotation — turned out to be a missing word in the auth rule,
  which the path rule had all along. That is fixed at the rule rather
  than guarded by a second mechanism.

- **The unresolved message stops forbidding the fallback.** It still
  names the path route as the better one, and now says plainly that a
  request naming no code surface is not covered by any rule: choose from
  §1 and record in the plan that the choice was made by hand. The loop
  fix stays; the prohibition goes.

### What this does not claim

The rule table still has no configuration surface — `.claude/`,
`CLAUDE.md`, agent and skill files route nowhere. This release stops
that gap from stalling a run; it does not close it.

## [1.3.5] — The arm that failed, and the boundary that went with it

Eleven files told the conductor to arm a run by hand:

```
mkdir -p "$CB_DIR/flags" && touch "$CB_DIR/flags/run-active"
```

A raw command carries no environment. `$CB_DIR` is exported by
`lib/cbenv.sh`, which that pair never sources, so the target resolved to
`/flags` — the root of the filesystem — and the run died on
`mkdir: cannot create directory '/flags': Permission denied`.

Nothing looked. DelegationGuard and RunGuard read
`$CB_DIR/flags/run-active` and treat its absence as "no run in
progress", which is correct for a session that is not a run and
catastrophic for one that tried to be. The failed arm did not weaken
the delegation boundary; it removed it. From the outside the two states
are identical.

That session then ran a full `/cb-rewrite` workflow — a skill whose own
topology names ten specialists — entirely inline. No Task Blocks
reached disk. The rule payload, the source and a Maven failure shared
one window, and the model returned a context-length error at 96001
tokens against a 96000 ceiling.

Everything 1.3.1 through 1.3.4 added depends on that flag existing. A
guard that cannot be armed is not a guard.

### Added

- **`scripts/run-flag arm|disarm|status`.** Sources cbenv so `$CB_DIR`
  resolves the way `run-status` and `plan-status` resolve it; stats the
  file after writing it; exits non-zero when it is not there, saying
  that the run is not guarded rather than failing quietly. One stable
  command string, so a host that remembers a permission decision can
  match it next time — eleven improvised spellings never did.

### Changed

- **Nine skills, `orchestrate`, and `run-discipline` §5 call the
  script.** Writing the mechanism changes nothing while the prose the
  conductor actually reads still hands it a raw command. The raw form
  is now absent from the tree, and `verify` greps for it so it cannot
  return in the next skill someone writes.

### What this does not claim

The script can refuse; it cannot make a conductor stop. A run that
reads a non-zero exit and proceeds anyway is the same failure class as
the selector that returned exit 3 twice and was abandoned. Closing that
needs a hook, and which hook depends on platform behaviour that has not
been measured here, so it is not designed against.

## [1.3.4] — Rules that claimed every class in the project

1.3.3 made the stack gate apply for the first time. This is the other
half of the same question, and the larger half: the gate decides which
*families* of rules are relevant, and the path globs inside each family
decide which *files* pull them.

Three spring-boot rules claimed `**/src/main/java/**/*.java` — every
class in a Maven project. Opening one service class pulled all five
spring-boot rule files, and the service used two of them.

Each of those files already says something narrower, in its own Trigger
table:

| File | Its own triggers |
|---|---|
| `hooks` | a property file changed · a controller mapping changed · a bean or configuration class changed |
| `patterns` | a unit of work spans writes · an exception reaches the edge · work runs off the request thread |
| `security` | an endpoint is added or mapped · a request payload is bound · management or error output changes |

None of those is "any class in the project". The globs now say what the
tables have said all along, which is why this is a correction rather
than an opinion.

### Fixed

- **`frameworks/spring-boot/{hooks,patterns,security}.md` narrowed** to
  the surfaces their Trigger tables name. Measured on a Spring profile:
  a service class drops from five spring-boot rules to two; a
  controller keeps four.
- **Every directory glob is paired with a filename glob** —
  `**/service/**/*.java` *and* `**/*Service.java` — the idiom
  `hibernate-jpa` already used. A project that does not split layers
  into directories still matches, so nobody loses a constraint to a
  naming convention they never adopted. Losing a rule silently is the
  failure this release is most exposed to, and the pairing is the guard
  against it.

### Unchanged, deliberately

`coding-style` keeps `**/src/main/java/**/*.java`. Its triggers — a
bean is declared, a setting is read, a controller or entity is touched
— really are project-wide. Narrowing it would have been an opinion
about Spring rather than a reading of the file, and the suite asserts
it stayed broad so a later tidy-up cannot quietly take it.

### What this does not touch

Five families each ship a `testing.md` matching `**/*Test.java`, so a
single test file in scope pulls five rule files. Whether that is
redundancy or five genuinely different sets of test constraints is not
something this release measured, and cutting it on the assumption that
frameworks have nothing distinct to say about their own tests would be
a guess.

## [1.3.3] — A gate that had never once applied

CB-109 added a stack gate to the rules layer: a rule file is returned
when its glob matches the file **and** the owning skill's stack token
appears in the profile `detect-stack` caches. The point was that a lone
`.tsx` in a project with no Next.js dependency should not pull the
Next.js ruleset.

It never applied. Not once.

`detect-stack` writes to `$CB_DIR/context/stack-profile.yaml`.
`select-rules` looked for `.claude/cereblnk/stack-profile.yaml`, without
the `context/` segment, found nothing, and took the documented
absent-profile branch: return every glob match. That branch is correct —
a missing constraint is worse than an extra one — so the failure printed
`stack_profile: absent — no gate applied` and looked like a project
without a profile rather than a reader that could not find one.

`select-agents` reads the same cache from `$CB_DIR/context/` and finds
it, which is why the agent half of the gate worked and nobody noticed
the rules half did not. Two copies of a path convention drift for the
same reason two copies of a policy table drift, which is what 1.3.1
cost.

Observed in a live run: one agent loading java, spring-boot,
spring-security, hibernate-jpa, junit-testing, backend and security
rules for a single review, then re-reading several of them with `Read`.

### Fixed

- **`lib/cbpaths.py` — runtime path resolution, answered once.**
  `$CB_DIR` when set, otherwise `.claude/cereblnk` found by walking up
  from the working directory, otherwise nothing. The walk-up is not
  decoration: `select-rules` is called directly by agents, from
  anywhere in the tree, often with no sourced environment. Absence
  still means "no evidence" and still returns more rules rather than
  fewer.
- **`select-rules` reads the profile through it**, so the stack gate
  applies. Measured on a java-only profile: 19 rule files before, 15
  after — the four `frameworks/spring-boot/` files drop, and the four
  `languages/java/` files stay, because language rules carry no stack
  token and are never gated.

### Also fixed

- **`CB-097` no longer ships into other people's repositories.** A run's
  `T-00N.yaml` was observed carrying a Cereblnk backlog number. It came
  from a comment in `protocols/acp-response-block.template.yaml`: an
  agent copies the template to write its Response Block, and copies the
  comments with it. A backlog id means nothing in someone else's tree.
  The comment loses the reference and `verify` gains
  `protocols carry no backlog ids`, so the next one fails the suite
  instead of shipping.

  Scoped to `protocols/` deliberately. Policies, skills and agents cite
  CB numbers as provenance and are read, not copied — removing them
  there would delete useful history to solve a problem those files do
  not have. It is also not the leakage scanner's job: that wordlist is
  uncommitted precisely because publishing it would be the leak,
  whereas backlog numbers are already public in `BACKLOG.md`. Different
  problem, separate check.

### Dropped

- **CB-126 — an additive binding surface for project-local skills.**
  Filed when a run turned `domain-expert`, a skill in the project's own
  directory, into an agent it then spawned. The reading at the time was
  that Cereblnk has no way for a project's skills to reach a specialist,
  so it needed one.

  It already has one, and it is not Cereblnk's. The host puts project
  skills in front of every agent — a live run shows
  `Skills restored (domain-expert, cereblnk:orchestrate,
  cereblnk:dispatch)` — and the Verifier treats a skill outside
  `skills-required.yaml` as unremarkable, since only a *missing* one
  weakens a verdict. A binding surface would have been machinery for a
  path that is already open.

  What the same run does expose is narrower and was not the filed item:
  those skills arrive by restore, not by a `Skill()` call, so
  `SkillLedgerHook` never fires and `skills-loaded.log` stays empty.
  "The agent loaded its skills" is unverifiable in exactly the case the
  ledger was built to make verifiable. That is a gap in the evidence
  chain, not in binding, and it is left recorded rather than fixed here.

### What this does not claim

Fifteen files is smaller, not small. Eleven of them are `common/`,
returned for every file in every language, and whether all eleven need
to be resident is a real question this does not touch — it could not be
asked honestly while the gate was dead. The same goes for the duplicate
loading in that run, where files arrived through the rules layer and
were then read again with `Read`: that is a behaviour, not a path bug,
and it should be measured before anything is designed against it.

## [1.3.2] — A verdict from a specialist that was never shipped

1.3.1 closed three refusals a run had walked around. This is the fourth,
and it followed directly from the third. Having abandoned
`select-agents` and chosen by hand, the conductor asked for
`domain-expert` — a name it took from the project's own skills
directory, where it is a skill, not an agent, and which ships with no
agent file at all.

The Task returned "Done" with zero tool uses and no Response Block. A
silent no-op, read by the run as a finished task. It then re-ran the
work on a general-purpose agent under a domain-expertise prompt and
wrote the block itself, so a fabricated specialist's verdict reached the
gate and the gate believed it. Nothing in the pipeline asked whether the
specialist existed.

The category error is worth naming because it is what produced the
failure: a skill is a capability an agent loads, not an agent. The check
that catches it needs no discovery at all. It needs only the roster
Cereblnk ships, which it knows by definition — no directory is scanned
and no project layout is assumed, which matters because a plugin that
expects one project's structure has stopped being general.

### Changed

- **ACP is amended to v1.2 (A3): the `role:` vocabulary is closed.**
  The spec had never said which values were legal — `role:` appeared
  only in two examples, both spelling it `SecurityAgent`, and no rule
  anywhere constrained it. That silence was load-bearing: it is the gap
  the invented role walked through. §4.2 now states that a role names
  an agent that exists, matched without regard to case or separators,
  and that a request needing expertise the roster does not name is
  answered by the surface specialist carrying the relevant skills —
  never by a role invented at the point of use. Former §4.2–4.4 shift
  down one; `grounding-policy` G-5 pointed into that range for the
  `unknowns` field and now cites §3, where the field actually lives.

### Fixed

- **`acp-lint` validates `role:` against the shipped roster.**
  CamelCase (`SecurityAgent`) resolves to filenames
  (`security-agent.md`); a role with no agent file is a V-1 violation,
  and the message lists the agents that do exist and names the
  skill/agent distinction. Fails open when `agents/` cannot be
  resolved: acp-lint is run against blocks outside the plugin tree, and
  a linter that rejects every role because it cannot find its own
  roster is worse than one that checks a field less.
- **The check runs on Task Blocks too.** The assignment is where an
  invented role is written first; the Response Block is only where the
  fabricated answer lands, twenty-seven minutes later. Catching it at
  the assignment is the difference between a refused block and a wasted
  run. `tests/fixtures/acp/good-task-block.yaml` asserted
  `role: LegalReviewAgent` — a name with no agent file, and the only
  evidence anyone had ever considered the question — and now reads
  `RequirementsAgent`, with its objective unchanged.

### What this does not claim

The fabricated specialist is caught at the artifact, not at the spawn.
Whether a Task naming a nonexistent agent can be refused before it runs
depends on whether the platform delivers `Task` to `PreToolUse`, which
is unverified and therefore not designed against.

## [1.3.1] — Three refusals a run walked around

DelegationGuard blocked a run from writing a subagent's Response Block,
which is exactly its job. What happened next is the finding. The run
did not delegate. It went for the escape hatch, wrote
`flags/conductor-override` itself, and the guard's own flags exemption
allowed it — only ScratchGuard objected, by coincidence of shape rather
than by design, and ScratchGuard nudges twice and then allows. Refused
there too, it announced the next route in as many words: it would write
the files from the command line instead, where no delegation check was
registered. That plan would have worked.

Two doors, then, and the guard was holding both. A third refusal fell
the same way in a later run: `select-agents` returned exit 3 on a
request that named a class and a verb, correctly, because "review the
OrderValidator class" carries no surface. But the message answered a
`--text` call by asking for a `--text` call. The run made that call
twice, read the same sentence twice, and then chose the specialist by
reading `agent-selection-policy.md` itself — routing decided by a model
instead of by the table, which is the outcome exit 3 exists to prevent.

The pattern is one pattern. A mechanism refuses; the refusal does not
leave a usable next step; the run finds its own way past. This release
closes the two doors, and makes the third refusal say something the run
has not already tried.

The hatch was built to cost an explicit act by the person. That cost
was carried entirely by keeping its name out of model-facing messages —
the guard's own comment says so. Secrecy is not a mechanism: the name
is in the source, and the source ships with the plugin. A guard that
permits arming its own bypass enforces nothing it claims to.

The same table was wrong in the other direction. The orchestrator is
instructed to copy the selector's output to
`context/<run>/skills-required.yaml` (agent-selection-policy §3), and
the exemption list did not know about it, so the guard blocked the
conductor mid-run and told it to delegate a routing decision it had
already made — the CB-106 category error, in a second location.

For the shell, the hard part is not detection but the false-positive
budget. run-discipline requires the conductor to run `detect-stack`,
`select-agents`, `run-quiet` and git; two skills tell it to write a
boundary flag with `echo ... > $CB_DIR/flags/boundary`. A guard that
blocks commands wholesale stops the run it is protecting, and a guard
the conductor learns to route around protects nothing. So the question
asked is narrower: what does this command write?

### Fixed

- **`conductor-override` is carved out of the flags exemption**
  (`cb_is_conductor_owned`, first match wins). Every other lifecycle
  flag stays conductor-owned; this one is refused, on both path
  separators and through the shell. The way out of a block still exists
  and still works — it now requires someone writing the file outside
  the session, which is what it was documented to require.
- **`context/<run>/skills-required.yaml` is exempt.** It is the
  conductor's own control surface, named as such by the policy that
  tells the orchestrator to write it.
- **`select-agents` exit 3 stops repeating the step just taken.** The
  advice now differs by what was tried: without `--text`, ask for it;
  with `--text` and nothing matched, say the request names no surface
  and send the caller to resolve the symbol it does name into a
  repository path, which is the route that resolves. Reading the
  policy and choosing by hand is named as not the fallback. The
  section reference in that message was `policy.md 1` in the source —
  a pointer to nothing — and is now `§1`.
- **The delegation boundary reaches the shell.** DelegationGuard runs
  on the `Bash` matcher alongside DestructiveCommand. No write targets:
  allow. Every target conductor-owned: allow. Anything else, including
  a write whose target cannot be resolved: block, with the same handoff
  the edit path gives.

### Added

- **`scripts/lib/shellwrite.py`** — resolves the write targets of a
  shell command by walking `shlex` tokens: redirections that create or
  extend a file (`>&` excluded, so `2>&1` is not a write), `tee`,
  `touch`, `cp`, `mv`, `sed -i`, and the writers whose target it cannot
  name (`patch`, `dd`, `git apply`), which resolve to unknown. `sh -c`
  and `bash -c` are re-read as shell rather than guessed at; other
  inline interpreters are unknown only when the code names a write, so
  `python3 -c "print(1)"` is not a blocked command. `$CB_DIR` is never
  expanded in the payload, so it is substituted before the ownership
  check rather than read as an unowned path.

### Changed

- **The conductor-ownership table moved to `scripts/lib/cbowner.sh`.**
  Two callers now ask the same policy question, and this release exists
  because one copy had drifted from the policy in both directions at
  once. One table, both callers source it.

### What this does not claim

The shell boundary is a floor, not a proof. A script that redirects
internally, a base64 round trip, an editor invocation, an obfuscated
one-liner: all pass. The bound is the ordinary write forms a model
reaches for when a Write is refused, and the cost of the bypass goes
from zero to deliberate. Without Python the shell branch fails open and
the boundary is unenforced there; that is stated in the hook rather
than implied away. `rm` is untouched — deletion is DestructiveCommand's
surface, and mixing them would put two failure budgets in one checker.

## [1.3.0] — A rewrite that transcribes is not a rewrite

The four floors before this one ask whether a change works. This one
asks whether it was the change that was called for.

A rewrite is requested because the current design is wrong. It fails by
reproducing that design, and the defects that motivated it come along,
because nothing in the run ever separated the requirements from the
accidents. The old structure is the most concrete thing in the room and
every later stage anchors to it. Fidelity to legacy code is the failure
mode, not the goal.

The word does the damage first. "Refactor" is what users say for both
jobs, and the plugin only had the behaviour-preserving one, whose whole
mandate is to leave the structure standing. The request routed to a
workflow specified to do the opposite of what was wanted.

### Added

- **`/cb-rewrite`, and the ruling that separates it from a
  transcription.** The old code enters as behaviour, never as
  structure. LegacyAnalystAgent extracts one row per behaviour in the
  domain's language, classified `intentional`, `incidental` or
  `suspected-bug`. RequirementsAgent rules each row with the user:
  `keep`, `fix`, `drop` or `deferred`. Classification is a reading and
  ruling is a decision, and Law 1 keeps them in different hands.
- **`behavior-check`** — the checker for the rulings, over the
  `## Behavior` section of a contract. It refuses an unruled row, a
  defect ruled `keep`, a `keep` or `fix` with no `char:` oracle, and a
  `drop` or `deferred` with no reason. `contract-check` ignores
  sections it does not know, so behaviour rows share the file with the
  channels and migration rows they will produce.
- **The firewall, expressed as an absent agent.** LegacyAnalystAgent
  hands over the contract and does not return; RefactoringAgent is not
  spawned at all. Both exclusions are rules in
  `agent-selection-policy` §3b with VerifierAgent as checker. An agent
  that is not in the room cannot anchor the design, which is sturdier
  than a rule the architect has to remember.
- **The oracle discipline that makes validation differential.**
  `keep` and `fix` both require a characterization test pinned against
  the old system. `scripts/env preflight` (CB-115) decides whether that
  is possible at all; when the old system will not run, every row stays
  `derived`, the contract says so in its first line, and the run's
  confidence drops rather than the claim being quietly softened.

### Changed

- **Dispatch asks once, on a closed list.** A structural verb over
  existing code with no complaint naming form or responsibility is the
  ambiguous case, and only that case. A complaint about form routes to
  `/cb-refactor`, one about responsibility to `/cb-rewrite`, a named
  target structure to `/cb-do`. An open trigger would have turned every
  restructure request into a question and spent the one-question budget
  on requests that already answered themselves.
- **`/cb-refactor` states its mandate before the checklist**, and can
  hand over mid-run. Three closed triggers, all checkable once the
  target structure exists and before the first edit: a contract must
  change, a suspect behaviour is load-bearing, or the path will not cut
  into invariant-holding steps. The statement is not a question —
  rule 4 still gives the explicit command right of way.

### Notes

The contract gate is class D: `behavior-check` is the named checker and
`/cb-rewrite` runs it, but no hook blocks a design stage that skips it.
Promoting it to M is a separate task, and the honest label ships in the
meantime.

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
