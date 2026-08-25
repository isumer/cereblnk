# Agent Selection Policy

Class: D — deterministic rules the orchestrator and PlannerAgent apply
when assigning `assigned_role` and `verification_level` to tasks. This
is the honest, static form of a "dynamic scheduler": rules, not an
engine (05 the execution-mechanism map — no plugin mechanism exists for a runtime
scheduler). **Checker: VerifierAgent** — during gate review it
confirms every mandatory specialist for the task's signals was
actually spawned; a missing mandatory specialist is a `weakened`
verdict on the run and a re-plan trigger.

## 1. Signal → specialist mapping (mandatory = must spawn)

| Task signal (surface touched / file types) | Mandatory specialists | Advisory (spawn if budget allows) | Min gate level |
|---|---|---|---|
| UI only (components, templates, styles; *.tsx/*.jsx/*.vue/Angular templates) | frontend-agent | qa-agent | 1 |
| Server-side logic (services, handlers; *.java/*.py/*.go/*.ts server) | backend-agent | architect-agent | 2 |
| Schema / migration (DDL, changelogs, ORM mappings) | database-agent, security-agent (data exposure) | backend-agent | **3** (always-level-3 list) |
| Auth / authz / session / crypto / secrets | security-agent | backend-agent | **3** + challenger mandatory |
| API contract (specs, DTOs, versioned endpoints) | apidesign-agent | backend-agent, security-agent | 2 |
| Payments / money / billing | security-agent, backend-agent | database-agent | **3** |
| Deletion / retention / bulk data ops | database-agent, security-agent | — | **3** |
| Infra / IaC (Dockerfile, K8s/Helm, Terraform) | infra-agent | security-agent (exposure) | 2; **3** for state/destroy/prod config |
| CI/CD pipelines | infra-agent | security-agent (credentials/injection) | 2 |
| Test-only changes | qa-agent | testengineer-agent | 1 |
| New endpoint / server logic needing tests | testengineer-agent (unit + integration layers) | qa-agent (sufficiency) | 2 |
| New UI component needing tests | testengineer-agent (component layer) | qa-agent | 1 |
| New user journey / acceptance behavior | testengineer-agent (one E2E, WRITTEN not run + functional/BDD) | qa-agent | 2 |
| Docs-only changes | docs-agent | technicalwriter-agent (restructuring) | 1; escalate to the described topic's level if docs state security/migration behavior |
| Refactor (declared behavior-preserving) | refactoring-agent, qa-agent | architect-agent | **3** (workflow-fixed, /cb-refactor) |
| Rewrite (declared behavior-changing: the design itself is replaced) | legacy-analyst-agent, testengineer-agent (characterization), requirements-agent (ruling), architect-agent, the replaced surface's specialists | apidesign-agent (migration rows), security-agent, qa-agent | **3** (workflow-fixed, /cb-rewrite) |
| Bug investigation | debugger-agent (tracing), then per root-cause surface | qa-agent (regression) | per surface; iron rule applies |
| Performance-sensitive paths (flagged hotspots, query changes) | performance-agent | database-agent (if queries) | 2 |
| Cross-cutting structure (module moves, boundary changes) | architect-agent | affected surface specialists | 2 |
| XML / XSD / WSDL artifacts (schemas, contracts, config XML, feeds) | backend-agent or apidesign-agent (per surface) — skill: xml-processing | security-agent (external XML intake: entity expansion, XXE) | 2; **3** when the XML crosses a trust boundary |
| Any code-touching task on a surface with a declared standards file | the surface's mandatory specialists above — skill: coding-standards (context-policy R-4 bundle) | — | unchanged (standards do not change risk) |

> Test-layer note: TestEngineerAgent decides WHICH pyramid layer and
> tool (selecting the fitting test skill by context — test-strategy,
> unit/component/integration/functional-testing, bdd-gherkin,
> selenium-webdriver/playwright-testing). QAAgent decides whether the
> resulting coverage is sufficient. E2E/browser runs are F-class:
> written + run-command named, never claimed executed here.

## 2. Combination rules

1. **Union, never max-only:** a task touching several rows spawns the
   UNION of mandatory specialists and takes the HIGHEST gate level.
2. **Risk floor:** the always-level-3 list (`risk-model.md`) overrides
   any row downward-looking reading — level is never below the floor.
3. **Gate agents are not selected here:** Verifier/Challenger/
   Consistency attach per gate level automatically (gate-policy.md).
4. **Fast path eligibility:** only a task matching exactly one row
   with min gate level 1 AND risk `low` may fast-path; anything
   ambiguous runs the pipeline. Eligibility is checked once, on entry.
   The exit is the fast-path abort (`risk-model.md`) — a run that
   aborts out re-runs selection here and never fast-paths again.
5. **Escalation preserved:** any spawned agent's `status: escalated`
   raises the level; selection is then re-run — new mandatory
   specialists may appear (e.g. a "UI-only" task discovering an auth
   header handler).

## 3. Worked dry-runs (the policy's own acceptance evidence)

| Sample task | Rows matched | Selected | Gate level |
|---|---|---|---|
| "Restyle the settings page (CSS + component markup)" | UI only | frontend-agent (+qa advisory) | 1 |
| "Add `deleted_at` column + Liquibase changeset" | Schema/migration | database-agent + security-agent (+backend advisory) | 3 |
| "Change JWT refresh expiry handling" | Auth | security-agent + challenger mandatory (+backend advisory) | 3 |

## 3b. Surface-specialist mandate (all stages, design included)

The specialist that owns a surface participates in EVERY stage that
shapes that surface — not only the build. A design/spec, review, or
investigation touching UI without frontend-agent, touching
infrastructure without infra-agent, or with hot-path/scale stakes
without performance-agent (advisory) is a selection violation exactly
like a missing mandatory specialist in §1. Division of labor in
design: architect-agent leads structure and boundaries; each surface
specialist authors its surface's sections of the spec with its skill
closure loaded (§4) — an architect writing React state design from
general knowledge is trap #11 (authority substituted for
verification) at the planning stage, where it is cheapest to prevent
and most expensive to ship.
**Checker:** unchanged and already in place — VerifierAgent confirms
during gate review that every mandatory specialist for the task's
signals was actually spawned; this section extends "task" to
design/spec stages explicitly.

**How the floor is computed (CB-143, finding F-07).** This mandate was
prose only. `scripts/select-agents` fired a rule on a path match or a
topic match and then used the stack token as a veto, so a token could
only ever subtract: a project *being* a Spring Boot project added
nothing. All twenty map rules carrying backend-agent were language or
framework rules whose topics are technology names, so
`--text "add a REST endpoint for user registration"` in a four-token
Spring repository returned what an empty repository returned —
apidesign-agent alone. The surface's designer was mandatory in
mechanism; its implementer was mandatory only on this page. Two
changes close that, and neither relaxes the mandate:

1. A TEXT rule names **server-side behaviour** (endpoint, handler,
   controller, service, persistence, worker, webhook) and routes
   backend-agent at level 2, per the server-side row of §1. It pairs
   with the API-contract row under §2.1 union rather than replacing
   it — a request for an endpoint asks for a contract *and* the
   behaviour behind it, so a new endpoint makes backend-agent
   **mandatory via the server-side row**, not merely advisory via the
   contract row.
2. **Bounded stack completion:** a role already in the floor receives
   the skills its own map rules declare for stack tokens the profile
   carries, even when the request text never named the technology. The
   bound is what makes it safe — completion attaches a skill, never a
   role; it requires a declared token the profile confirms; and it does
   not run for the inferred fallback, so an unroutable request still
   reads `inferred: true` with an empty floor rather than a
   confident-looking wrong one.

Neither makes the floor a ceiling: both are additive, and the policy
above stays authoritative for signals no path or verb carries. The
fixture in `scripts/test-skill-selection` asserts the floor for the
measured request, so this section and the mechanism cannot drift apart
again silently.

**Exclusion is also selection (/cb-rewrite).** Two agents are absent
from a rewrite's design stage by rule. RefactoringAgent, because its
domain is behavior-preserving transformation and a rewrite preserves
no such mandate — present, it reintroduces the structure the run
exists to replace. LegacyAnalystAgent, because it read the old source:
it hands the behavior contract over and does not return. The firewall
is an agent absent from the room rather than a rule the architect must
remember. **Checker:** VerifierAgent, same gate review — either agent
spawned after the ruling stage is a selection violation.

## 4. Skill relations resolution (skill-relations-policy.md)

After §1–§2 fix the specialists and the agent frontmatter fixes each
specialist's base skill set, the orchestrator expands that set through
skill relations before spawning:

1. For every selected skill, add its `requires` closure (transitive).
2. Add `complements` entries only where the task signal also matches
   their surface AND the agent's budget allows.
3. Budget squeeze follows skill-relations-policy.md §3: complements
   drop first and silently; transitive requires drop farthest-first
   with an `assumed` fact recorded; a direct `requires` that cannot be
   loaded makes the agent report `blocked`, never reason without it.
4. `escalate_to` conditions travel with the skill: an executing agent
   hitting a stated hand-over condition escalates (rule §2.5) or
   records the gap as an unknown — silent continuation past a declared
   boundary is the violation ConsistencyAgent looks for.

Checker split: **ConsistencyAgent** validates the relations graph
itself (references resolve, `requires` acyclic, no confidence tokens);
**VerifierAgent** confirms, as part of its existing §1-mandatory-
specialist check, that no agent reasoned past a declared `escalate_to`
boundary without an escalation or a recorded unknown.

### Conductor override (human only)

DelegationGuard blocks conductor edits during a run. The block names
the specialist to spawn; it names no way around itself, deliberately.
A model reads the last sentence of a block as its instruction, and the
old message ended by naming the flag to delete.

A person who genuinely needs a conductor edit creates
`$CB_DIR/flags/conductor-override`. It expires after
`CB_OVERRIDE_TTL_MIN` minutes, default 60, so it cannot be forgotten
into a permanent hole. Deleting `run-active` is no longer a route:
while the run ledger is still being written, the guard re-arms from
its own witness file.


## 4c. Task-scoped skill resolution (CB-097)

Agent frontmatter `skills:` preloads full skill content on EVERY spawn.
It therefore carries only what is true on every invocation of that
role. Everything stack-shaped resolves per task instead.

Resolution order, per run:

1. `scripts/detect-stack` writes the stack profile once per manifest
   change. It answers what this project is built from.
2. `scripts/select-agents` intersects the task signal (changed paths,
   or `--text` on the request when nothing has changed yet) with the
   stack profile, through `policies/skill-selection.yaml`. It emits
   `skills_required` per role.
3. The orchestrator copies that block to
   `$CB_DIR/context/<run_id>/skills-required.yaml` and writes each
   role's list into its Task Block.
4. The specialist loads exactly those with the Skill tool, then adds
   any skill its own evidence obliges through the map's `discovery`
   triggers. It reports every load in `skills_loaded`.

**Checkers.** `SkillLedgerHook` records each load; `SkillFloorHook`
blocks a SubagentStop whose floor is unmet; **VerifierAgent** compares
`skills_loaded` against the required list at gate review.
`scripts/check-agent-skills` holds the graph itself: no dangling
reference, no unreachable skill, no preload above the budget cap.

It ships with the plugin, so an install holds the checker and not just
the rule. It lived in the repository `scripts/` until a test journal
observed that the package did not carry it — the rule was there, the
checker was not, and that is the state this project calls a wish.

**Empty floor is a failure, not a default.** `select-agents` exits 3
when no signal matches. The conductor supplies `--text` or names the
surface. A silent single-agent default is how a run gets the wrong
specialist.


## 4b. Rules layer resolution (which constraints an agent reads)

Rules files are not `SKILL.md` files. The platform never discovers
them, and a `paths:` glob sitting on a non-skill file is read by
nothing. The rules layer therefore loads explicitly, in three steps.

1. **The skill body names the directory.** Every skill with a rules
   directory carries a `## Constraints` section instructing the read.
   A mention in the skill `description` is prose, not an instruction:
   only the body section loads anything.
2. **The globs choose the files.** Inside that directory the agent
   reads only the files whose `paths:` glob matches a path the task
   actually touches. Globs are per file, never per directory — a
   Spring controller pulls its matching handful, not the whole tree.
   A rule with no file type declares `applies_when:` instead and
   matches on the task signal (R-4). A glob answers what kind of file
   this is; it cannot answer whether the framework is part of the
   project. `scripts/select-rules <path>` applies both — the glob and
   the stack token the owning skill declares — and returns the list to
   read. A framework rule for a dependency the project never declared
   is not a floor, it is the wrong project's idioms.
3. **The common layer is read once per run**, not once per matched
   file. `rules/common/` carries what holds regardless of language.

**Who reads them.** The executing specialist, never the conductor.
Rules are file contents, and run-discipline §2 puts file contents in
subagent windows. A conductor that opens a rules file has violated
that policy whatever the rule said.

**Citation.** A violated constraint is cited by file and section so
the reader can check it. An uncited constraint claim is `assumed`,
never `known`.

**Why the globs stay narrow.** A rules file enters context unasked the
moment its glob matches, so every line taxes each session touching a
matching file. Breadth of attachment is a budget decision, not a
completeness one.

**Checkers.** `check-rules` R-4 rejects an attachment matching
everything or nothing; R-8 rejects a skill whose declared rules path
does not resolve. **VerifierAgent** confirms during gate review that
every constraint claim carries its file and section — an uncited
claim is a `weakened` verdict, the treatment §1 gives a missing
mandatory specialist.

**Known gap.** Step 1 has no mechanical checker. Nothing today reads a
skill body to confirm that a skill owning a rules directory actually
instructs the read, so a rules directory can go live and be loaded by
no one. Detection is review-only until a checker exists.
