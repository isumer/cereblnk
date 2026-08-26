# Changelog

All notable changes to Cereblnk are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Frozen core documents (00–09) change only through explicit amendments
recorded in their own Amendment Logs; this file records what shipped.

## [1.4.2] — The map that described routing it could not do

`policies/skill-selection.yaml` declares 77 rules, each naming the roles
that own a skill. Measured on the real map, the field was inert for
routing:

```
select-agents --text "owasp threat model"   -> architect-agent (fallback)
select-agents --text "vulnerability"        -> architect-agent (fallback)
```

`owasp-threat-modeling` declares `roles: [security-agent]` and lists all
three phrasings as topics. It matched every time and placed nothing,
because placement was conditional on the role having ALREADY been
selected by the hardcoded tables above it:

```python
for role in r["roles"]:
    if role in agents:          # agents = what was selected already
```

So the map could enrich a routing decision, never make one. The sharper
consequence: a diff could not raise concern, only the user's own wording
could — which inverts what a routing layer is for.

### Fixed

- **A matched map rule now brings in its owner.** Bounded twice: only
  the first role (`roles:` lists every role that MAY use the skill,
  which is not every role a match should summon), and always at gate
  level 1 — the map carries no risk model, so it may add a specialist
  but never invent risk. Escalation stays with the hardcoded tables and
  the always-level-3 list.
- **Topic matching gained word boundaries.** It was a naive substring
  test, latent while a match could only attach a skill, consequential
  the moment a match could summon an agent. Measured: `tests` contains
  `ts` and recruited the typescript rule's roles; `stored` contains
  `store` and recruited redux's.
- **`auth/session` admits what auth actually handles.** `password`,
  `passwd`, `plaintext`, `hashed`, `hashing`, `salted`. A
  plaintext-password report — the textbook always-level-3 case — matched
  nothing before and routed at gate 1.
- **`tests` admits its own plural.** `\btest\b` took the bare singular
  only, so "write tests for this", "the tests are failing" and "testing
  strategy" all fell to the architect fallback. So did "these tests miss
  the failure mode", which is lifted from `/cb-pr-review`'s own text.
- **`documentation` is a text rule at last.** `docs-agent` appeared in
  zero text rules, so `/cb-docs` could not select the lead its own
  topology names, from its own trigger sentence.

### Measured, including what the first attempt got wrong

The first cut of the auth regex added bare `hash` and `salt`. Controls
caught it: "basalt tiles" and "hash browns" each took a mandatory gate-3
security review, and both were correctly unresolved before the change.
The noun forms are ambiguous in a codebase and in English; the verb
forms are not, and "password hash" is already caught by `password`.

The first cut of the map fix summoned every role in a matched rule. The
topic `gradle` then pulled backend, architect, debugger and refactoring
out of the java rule for a vague build-speed complaint — five
specialists from one sentence. Narrowing to the owner plus word-bounded
topics brought that to two.

| input | before | first cut | shipped |
|---|---|---|---|
| `the gradle build feels slow lately` | 1 | 5 | 2 |
| `the tests are failing` | unresolved | 3 | 1 |
| `basalt tiles` | unresolved | security @ 3 | unresolved |
| `db/changelog/001-init.xml` | 3 | 5 | 4 |

Gate levels were checked separately and did not move in any case.

### Fixed — the plan declares a spec the linter now reads (CB-159, F-38)

`/cb-implement` carries a staleness gate in prose: read the plan
header's `derived_from_spec`, read the spec's `spec_version`, halt if
the plan is behind. `plan-lint` runs before task 1 and already parses
the header — and never looked at either field. It required `spec:` to
be present (R4) and accepted any value at all, so `spec: yes` and a
path to a file that does not exist both passed.

R7 resolves the declared path and, when the header pins `@v<N>`,
compares it against the spec's own `spec_version`. `spec: none` still
passes untouched: a direct `/cb-do` run has no spec and says so. The
defect was silence dressed as a declaration, not the absence of one.

Closes the mechanisable half of F-38. The other half stands as
recorded: nothing stops a spec-less implementation from starting, and
gating that would fire on the legitimate spec-less workflows.

### Changed — comments describe the code, not its history (CB-158)

Several scripts had grown a second changelog inside their comments:
the run that failed, the timestamps that proved it, what the previous
version got wrong. `run-guard.sh` was 52% comment, `cbenv.sh` 50%,
`delegation-guard.sh` 42%.

That history belongs here, where it is indexed and dated. A comment is
for the reader of the code, and it earns its place by explaining what
the code does or why it is shaped that way.

Kept: decision tables, fail-open semantics, resolution orders, usage
blocks, and the reasons behind non-obvious structure — why identity is
parsed rather than substring-matched, why the mtime scan is a floor and
not an error path, why Store aliases are skipped without running them.

Removed: the measurement narratives. Across the files touched by
CB-148…CB-157 and the five densest hooks, roughly 300 lines.

### Fixed — three checkers that misread their own inputs (CB-157)

**F-51** — `shellwrite.py` listed `open(` as a write hint, and Python's
`open()` defaults to mode `"r"`. So the most ordinary read in an inline
one-liner — `python3 -c "d=json.load(open(f))"` — was reported as a
write, and DelegationGuard blocked a read-only diagnostic while naming
the specialist that should perform the "edit". A mode argument now
decides it. Two other hypotheses were tested against the same guard
first and refuted: `2>/dev/null` and a quoted `>` are both handled
correctly.

**F-42** — `behavior-check` had four paths returning exit 3 in silence.
Measured beside `env preflight`, which returns the same code and says
*"SKIP no config/runtime.md — the runtime stage is not configured"*:
same code, one of them tells the caller what to do. A gate the workflow
orders you to run before design starts, exiting mute, is
indistinguishable from a gate that passed. All four now say why.

**F-37** — `spec-assemble` accepted `Known`/`Derived` only, while ACP
blocks write the labels lowercase as field names. Four of six sections
from a real `/cb-design` run were rejected for having "no epistemic
label" while every one was labelled, in the spelling the protocol itself
uses. Not fixed by dropping case sensitivity — "it is known that" is
ordinary English — so the lowercase form is admitted only where it is a
label rather than a word.

### Changed — comments describe the code, not the finding

The fixes above and in CB-148…CB-156 were first written with the
measurement narrative inline. That belongs here, in the changelog, not
in the source: a comment explains what the code does. Removed across
ten files, net −165 lines.

### Fixed — run lifecycle (CB-151; F-43, F-49, F-56)

**A finished run had no verb.** `run-discipline` §5 has always said the
flag is HANDED OFF at final synthesis — `run-completed` is written, and
DelegationGuard reads it as the follow-up window. But eight workflow
skills said only *"Remove it at final synthesis"*, deferring to §5
without restating it, and `run-flag` had no subcommand that performed
the handoff. The only route left was a hand-written `touch`, which is
the exact failure this script was created to remove.

Measured live: a conductor followed its skill's own final line, ran
`run-flag disarm`, saw `run-flag: disarmed`, and had its next edit
blocked — *"the run-active flag was removed while the run ledger was
still being written"*. The guard was right. The instruction was wrong.

- `run-flag complete` performs the handoff: clears `run-active` and its
  siblings, writes `run-completed`, and verifies both — a failed handoff
  exits non-zero rather than reporting a run as ended.
- `run-flag disarm` now says what it is: a PAUSE, and names `complete`
  for the other case. The bare word "disarmed" read like "the run is
  over", which is how the wrong verb kept looking correct.
- the eight skills and §5 now name the right verb.

**The nudge budget survived a pause.** `run-active.state` outlived
`disarm`, and since every workflow disarms before any turn that ends
awaiting the user, a run that paused came back with its counter already
spent. Measured: the first Stop after re-arming skipped the nudge and
disarmed while a specialist was still out — the one thing that nudge's
own message tells the reader never to do. The counter belongs to an
uninterrupted armed period, so `disarm` now ends it.

**The progress metric counted its own inputs.** RunGuard counted every
`*.yaml` in the run directory, including the `skills-required.yaml` the
conductor writes at run start. Two consequences, both measured: the
count shown read as *"2/1 task blocks on disk"* — more blocks than
planned, i.e. finished — and the conductor's own bookkeeping could
advance the progress metric, buying a nudge no specialist earned. Now
`0/2` before any block arrives and `1/2` after the first.

### Fixed — context measurement (CB-150; F-45, F-46, F-47)

**The monitor was maximally wrong at the moment its reading mattered
most.** `UserPromptSubmit` fires before the next assistant turn is
written, so on the first prompt after a `/compact` the newest `usage`
record in the tail still describes the pre-compaction turn:

```
telemetry/context.log, compaction at 15:52
  15:21:26  occupancy=702145  pct=77.8   <- before
  15:58:43  occupancy=706493  pct=78.2   <- FIRST PROMPT AFTER
  16:05:48  occupancy=103817  pct=11.5   <- next prompt, self-corrects
```

The true figure sat in the same tail the hook already read:
`compactMetadata.postTokens: 31272`. It reported 22x that. Structural,
not a fluke — it happens on every compaction. Observed harm: the reader
throttled its own work and deferred a task on that number.

A compaction record carries no `usage` of its own, so it is tracked
separately and preferred only when it comes *after* the last `usage`
record. The second prompt after a compaction still reads its own turn.

**The hedge escaped through the reserve.** `input_capacity = window −
output_reserve`, resolved independently, but the hedge test only looked
at `window:`. A `settings.json` naming the window while the reserve fell
back printed a confident percentage over a partly guessed denominator —
the exact failure F-13's fix existed to prevent, through the door beside
it. It now matches `context-budget`'s own aggregate `labelled: assumed`
line rather than re-deriving that logic.

The warning text broadened with its condition. It used to say "the
window was never measured", which is wrong in precisely the case this
change added, and sent the reader to set a variable that was already set.

**The telemetry could not diagnose its own worst error.** F-45 was
invisible in the log; finding it took hand-reading `compactMetadata` out
of the raw transcript. The line now carries `compacted=` and
`capacity_source=`, appended at the end so `occupancy=`/`capacity=`/`pct=`
still parse unchanged.

Measured on transcript fixtures, including the ordering case that decides
the fix: compaction record *after* the last usage → `occupancy=31272
compacted=yes`; compaction record *before* a newer usage → falls back to
the usage sum, `compacted=no`. No-usage, malformed-JSON and
`postTokens: 0` transcripts all stay silent at exit 0.

### Added — RouteHintHook (CB-149, F-57)

`TOPOLOGY.md` says cb-dispatch "routes engineering work to the right
Cereblnk workflow automatically" whenever a request touches a codebase
without naming a `/cb-` command. Measured across a full session of
codebase work — branch edits, a release, a PR:

```
skills-loaded.log, whole session:
  1787657616  main  dispatch      <- typed by the user
  1787667468  main  orchestrate   <- typed by the user
```

Zero automatic invocations. Description matching is the host model's
discretion, not a mechanism, and nothing else pushed: the only
UserPromptSubmit hook was ContextMonitorHook, which injects a token
warning and says nothing about routing. The platform's own entry point
was REGISTERED and never ENGAGED.

The new hook supplies the push and only the push. It runs the same
`select-agents` every workflow already runs and injects one line naming
the resolved specialists and gate level. It does **not** name a
workflow: that table lives in `skills/dispatch` Step 3, and a second
copy would diverge from the first — which is the defect CB-148 closed
one layer down.

Silence is the larger half of the design, since a hook that speaks every
turn spends the budget it exists to protect:

| condition | why |
|---|---|
| prompt names a `/cb-` command | the explicit command wins, and always has |
| `flags/run-active` is armed | a workflow already owns this turn |
| selector returns `inferred: true` | unresolved is silence, never a guess |
| `flags/no-route-hint` | opt-out, same shape as careful/boundary |

Measured after CB-148 landed, because it depends on it: before the
word-boundary fix, `"the tests are failing"` resolved to three
specialists and this hook would have injected two wrong ones on every
such prompt.

### Known residual

A generic path rule still fires alongside a specific one on the same
file: `xml-processing` (`\.xml$`) matches a Liquibase changelog that
already has `liquibase-migrations`. Rule specificity is a map design
question, not a selector bug, and is left open.

## [1.4.1] — The run every hook was in was a guess

A `backend-agent` edited `RegistrationController.java` and `pom.xml`,
never ran the configured `api` check, and finished. `exec-floor` did not
block it. The ledger was intact the whole time — the edits were on disk,
in the right file, with the right agent name:

```
context/R-2026-08-24-002/exec.log:
  cereblnk:engineering:backend-agent	edit	api     (x3)
context/R-2026-08-25-001/exec.log:
  absent
```

The floor read the second one. `exec-floor.sh:35` is
`[ -f "$RUN/exec.log" ] || exit 0`, and `$RUN` came from
`ls -1dt "$CB_DIR"/context/*/ | head -1` — newest by mtime, recomputed
on every hook invocation. The timestamps say the rest. The agent edited
source first (`1787653044`–`050`), when the newest directory was still
`R-2026-08-24-002`, so the edits recorded there. It then wrote its
Response Block (`1787653090`+), and that **created**
`R-2026-08-25-001`. At SubagentStop the floor picked the newest, found
no `exec.log`, and exited 0.

Nothing was broken. Every part did what it was written to do. Run
identity was inferred rather than carried, and the inference is wrong
for any agent whose Response Block lands after its edits — which is
every agent that finishes normally.

### Eight hooks shared the guess

`skill-floor`, `exec-floor`, `reach-floor`, `contract-floor`,
`exec-ledger`, `skill-ledger`, `digest-cap` and `run-guard` each derived
the run directory with their own copy of that scan. Writers and readers
guessed independently, so the split does not just silence one floor: it
desynchronises the runtime record layer, with the ledgers appending to
one directory while the floors read another.

Sorting differently does not fix it. `R-2026-08-25-001` sorts after
`R-2026-08-24-002` under any ordering, so the empty directory still
wins. "Newest" is the wrong selector, not the wrong sort key — the set
of directories does not record which run an agent belongs to.

### Fixed

- **The run id is carried on the flag, and resolved in one place.**
  `run-flag arm "" <run_id>` writes the id into
  `flags/run-active`. `cb_run_dir()` in `scripts/lib/cbenv.sh` reads it
  and is now the only thing that answers "which run is this"; all eight
  hooks call it. The pin is validated rather than trusted: anything that
  is not a bare run id is rejected, and an id whose directory no longer
  exists is discarded. Both cases fall back to the old mtime scan, which
  is still correct whenever one run directory exists. A stale pin is
  asymmetric — for the floors it means reading an old ledger, but for
  the ledgers it means writing into a dead directory, silently, which is
  the same defect from the other side.
- **`exec-floor` compares when, not whether.** The floor built the set
  of surfaces an agent edited, subtracted the set it executed, and
  blocked on the difference. A set difference has no order in it, so an
  agent that ran the check and *then* edited the file counted as
  covered — the state that shipped was never run. The ledger already
  carried the timestamps. A surface is unrun when it has no exec, or
  when its last edit is later than its last exec; ties break on the
  ledger's own append order. The per-agent filter is unchanged.

### Verification

`scripts/test-run-identity` is new: it records the edits, *then* creates
the newer directory, *then* invokes the floor, because that is the only
ordering that fails against the old code. It also asserts that the
fixture reproduces the mtime race before trusting the result — the first
draft did not, because writing `exec.log` bumped the old directory's
mtime past the new one and the test passed for the wrong reason. Beyond
the regression it covers a removed pin falling back, six hostile flag
values rejected including `../../etc`, and all eight hooks exiting 0 on
an empty resolver result. That last one is the price of sharing: an
error in `cb_run_dir` now reaches the whole record layer rather than one
hook, so every caller's fail-open path is asserted rather than assumed.

`scripts/test-exec-floor` gains the exec-then-edit case, per-surface
ordering both ways, and same-second ordering.

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

### The second pass

The first round closed thirteen and deferred the rest with reasons.
The reasons were then re-examined one at a time, and most of them did
not survive contact with the measurement.

- **The destructive hook read its own documentation as a threat**
  (CB-135). The pattern ran over the raw command string, so a heredoc
  whose body *mentioned* a recursive delete was blocked while writing a
  file. A project cannot document the operations this hook guards
  against while the hook is on. The same header this repository already
  wrote for `delegation-guard.sh` — read the parsed payload, never a
  substring of it — applies here in mirror image: there the risk was a
  planted bypass, here it was a false positive. The block message also
  prescribed an escape the hook itself refused, so a user who turned the
  protection on could be unable to turn it off; the message now names a
  command the pattern permits. `/cb-careful` decides its direction by
  exact match instead of interpolating the argument into a comparison.
  An adversarial matrix written for the fix found and closed one real
  bypass (`cat <<EOF | bash`).

- **No role is denied the tool its own workflow requires** (CB-136).
  Eight agent definitions denied `Write` while the workflows that
  dispatch them asked for files on disk; one was measured complying
  through `cat > file <<'EOF'`. The declared restriction decided which
  tool did the work and nothing else. Half of that lived in the
  definitions and is fixed there — run-discipline §1 requires every
  subagent to write its Response Block, so no agent may be denied
  `Write` (checker: `check-agent-skills` A-7). The other half is the
  restriction that remains: twelve agents deny `Edit`/`NotebookEdit`
  because they decide and record rather than modify source, and `sed -i`,
  `patch` and `ed` do exactly that under a tool the denial never named.
  `ToolFloorHook` closes that path, with the same declared bound
  CB-123 wrote for itself: it sees ordinary in-place forms, not a
  determined bypass.

- **The domain floor beats the level the block was assigned** (CB-137).
  A Task Block carried `verification_level: 1` into a security task
  whose own definition says the domain is always level 3. Nothing said
  which won; the specialist chose correctly by judgment. Precedence is
  now written where both dispatcher and specialist will find it, and a
  fixture asserts it.

- **The Boot skill answers the Boot question it was silent on**
  (CB-138). Searching the Spring Boot skill for validation guidance
  returned one line. Bean Validation and `@ControllerAdvice` error
  contracts — the most common Boot design decision — were absent.

- **The `bin/` on PATH is a decision, and the tree records it**
  (CB-139). The directory named in `PATH` did not exist. Harmless,
  because every caller uses a full path; recorded rather than left as a
  discrepancy between the claim and the tree.

- **The cascade is advisory, and the policy now says so** (CB-142).
  `skill-selection.yaml` declares ninety-four `discovery` triggers and
  §4c read as though something resolved them. Nothing did. The obvious
  fix — a `PostToolUse` hook scanning tool responses for trigger tokens —
  was rejected on measurement rather than taste: a scan sees text, and
  cannot separate a stack from a mention of one. All ninety-four triggers
  occur inside `skill-selection.yaml` itself and all ninety-four inside
  the discovery fixtures, so a single Read of the map would have demanded
  all thirty-seven targets at once. Every one of those targets is a
  group-nested skill, which is the exact set CB-141 addresses, so each
  demand would have been one the Skill tool may not satisfy.

  §4c now says the specialist SHOULD follow a fired trigger, and records
  the rejected design so the next reader does not re-derive it.
  `check-discovery-claim` binds both halves: no consumer outside the
  declared validators, and both documents stating the advisory status.
  Build the executor and C-1 fails by name, which forces §4c to be
  revisited rather than quietly outgrown.

- **The floor routed the contract and forgot the implementer**
  (CB-143). `select-agents --text "add a REST endpoint for user
  registration"`, in a repository whose stack profile carried `java`,
  `maven`, `spring-boot` and `hibernate-jpa`, returned exactly what the
  same command returned in an empty repository: the contract designer,
  alone. Two causes, and neither closes without the other. No map rule
  connected request *semantics* to `backend-agent` — all twenty rules
  carrying that role are technology-name rules, matching `java` or
  `spring`, never `endpoint`. And a declared stack token was applied
  only as a veto, so even a correctly routed implementer would have
  arrived with an empty skill floor.

  §3b was fixed by honouring it, not by rewriting it: it names
  VerifierAgent as its checker and is the only statement making a
  missing implementer a selection violation. Demoting it to a
  description of current behaviour would have removed a guarantee and
  put nothing in its place. A text rule now routes server-side
  behaviour, and stack completion attaches profile-confirmed skills to
  a role **already** in the floor — completion adds a skill, never a
  role, so a documentation request in a Java repository still resolves
  to nothing and says so. The measured request now yields
  `[apidesign-agent, backend-agent]` with
  `backend-agent: [java, spring-boot, hibernate-jpa]`, and each signal
  states why it fired.

- **The checkpoint is this project's threshold, not the host's**
  (CB-145). `input_capacity = window − output_reserve` with a percentage
  taken off it is not what the host compacts on; the host uses its own
  effective window less a summary buffer. The sharp edge is the third
  variable: the host also reads `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`, and
  not in these units, so tuning the Cereblnk checkpoint with it moves
  something in the host too. Recorded as `inferred` — the host's side
  was read from the shipped binary, not from published documentation.

- **A conductor counted idle while its specialists run** (CB-144). The
  continue-nudge named one case — waiting on the user — and prescribed
  disarming for it. Measured against a real run it was wrong twice: the
  conductor was waiting on two live specialists, which is the normal
  state of a multi-agent run, and there was no ledger to reconcile
  because the run had written no `plan.md`. Its remedy was worse than
  the nudge, since disarming while specialists are out removes the
  floors that judge them when they return.

  No host signal reports a live subagent, and inferring one from
  undocumented task files would make a hook depend on an F-class
  mechanism, which tasks may not do. So the fix is not detection: the
  message now names three cases and attaches the disarm advice to the
  one where disarming is correct. `test-hooks` fails if any case goes
  unnamed, or if disarm is offered before the case that justifies it.

- **A suite that reads its own shell is not a suite** (CB-146). The
  README tells the operator to export the two budget variables so the
  context budget reports a measured window; doing so made four
  context-monitor cases fail, because they hardcode the assumed capacity
  and `run()` inherited the environment wholesale. A contributor who
  followed the setup instructions could not run the suite guarding the
  code they were contributing to, and CI never saw it — Actions sets
  neither variable, so the failure lived only on the machine of the one
  reader the suite most needs to serve. The helper now strips the
  variables and hands them back to the cases that care. The case missing
  on the other side was added: once the window IS measured, the hedge
  must go, because a warning that cries `ASSUMED` at a figure the
  operator supplied teaches the reader to ignore the word.

- **The seventy-seven skills the host could not see** (CB-141).
  Discovery walks one level under a skills root; seventy-seven of
  ninety-four sit a level deeper. First sized as a migration of every
  skill file — then the published plugin reference supplied a `skills`
  field in `plugin.json` that declares extra scan roots, so the files
  stay where they are and the grouping survives. `check-agent-skills`
  A-8 fails when a group directory is not declared, verified against a
  constructed failure. Confirmed live rather than assumed: after a
  reload, `Skill(cereblnk:spring-boot)` returned the skill body from
  `skills/frameworks/spring-boot` — the nested path that answered
  `Unknown skill` three times during the test.

### What this does not claim

Twenty-nine findings came from the journal and a thirtieth appeared
while fixing them. This closes all of them.

Five findings were closed without a change (CB-140), and the reason is
recorded rather than assumed: one is Claude Code's scope, not this
plugin's; one was resolved by `/reload-plugins` during the test itself;
two were dispatch errors the journal records honestly as its own; and
one — that an epistemic label certifies an observation was made, not
that it was correct — is a true statement about the protocol rather
than a defect in it. The journal proved that point three times: once
against a specialist that labelled a false fact `known`, once against
its own author drawing a wrong inference from a right measurement, and
once against the same author making the measurement itself incomplete —
`discovery_pairs` was reported as having no callers when it has two,
both validators. Each correction is recorded where the claim was made
rather than edited away.

Closing every finding is not the same as being correct, and this
section is titled for the difference. One test journal found thirty
defects in one pass, several of them mechanisms this project advertised
as enforcement while they did nothing. The reasonable inference is not
that the list is now empty — it is that a second reader would find a
second list. What changed is that the mechanisms named here now have
checkers, and a checker fails where a paragraph would have kept
agreeing with itself.

The deterministic layer is green. It covers scripts, hooks, linters and
the skill graph; it does not cover whether the agents reason well, and
it never will. Nothing in this release establishes that. It establishes
that what was silently absent is now present, and that the next time
one of these goes missing, something other than a human running an
experiment will say so.

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
