# Post-edit checks

What a project should run when files change, per language and
framework. This is setup guidance for the operator who configures the
project's own hooks and `$CB_DIR/config/test-command`. The plugin's own
enforcement hooks are a separate fixed set, described in
`hooks/README.md`; nothing here changes them.

It used to live as fifteen `rules/**/hooks.md` files selected by path,
which charged every edit of a `.java` file ~1,076 tokens of advice that
no hook read and no checker enforced. Two files kept the name and
stayed in `rules/`, because they are code constraints rather than setup
advice: `frameworks/react/hooks.md` (call order, effects) and
`frameworks/spring-security/hooks.md` (filter placement, providers).

## The common policy

Everything below extends this.

**Purpose** — every check names the failure it prevents. A check whose
output nobody reads is removed.

Avoid: a check added because a tool offers it · a check nobody can
attribute to a past failure.

**Scope** — a post-edit check touches only what the edit affected.

```text
edited file        format and lint that file
affected module    compile and unit-test that module
whole repository   on explicit request, or in the pipeline
```

Avoid: a full build after a one-line edit · the whole suite on every
save · a check ignoring which files changed.

**Timing** — anything past a few seconds moves to commit or to the
pipeline.

```text
on edit      format, lint, type-check the file
on commit    affected tests, secret scan
in pipeline  full suite, security scan, coverage
```

Avoid: an end-to-end suite bound to a save · a scan on every keystroke
· a check that trains people to disable hooks.

**Tooling** — a check states its required tool and what happens when it
is absent.

```text
required   stated, with the failure message
optional   skipped with a warning, never silently
offline    an alternative, or an explicit gap
```

Avoid: a missing-command error as the failure mode · a silent skip that
looks like a pass · a hook assuming a network.

**Blocking** — reserved for what cannot be undone later. Every block
states how to proceed deliberately.

```text
blocks   destructive commands, a credential leaving the machine
warns    style, formatting, thresholds
```

Avoid: style violations blocking a commit · a block with no escape ·
rules that push a team to disable hooks entirely.

**Output** — in every language below, build and test output passes
through the run-quiet gate. The digest returns; the raw stream never
enters an agent's context. Avoid a build log pasted into a response, a
stack trace returned whole, or a second unwrapped run to see more.

## Java

```text
on edit           format the edited file
                  style-check it against committed configuration
                  compile the containing module
                  expect exit code and file:line errors only
                  budget seconds, never a packaging phase
edited a test     that test class
edited a source   the module's unit tests
never on edit     integration, container-backed, end-to-end
build file        resolve the tree, offline where possible
                  inspect duplicate versions and new transitive entries
                  verify the resolution output is committed
output            exit code, failing test names, first assertion;
                  compile errors as file:line, deduplicated
```

Avoid: a full multi-module build after one edit · a packaging phase in
an edit hook · formatting applied to untouched files · a version change
merged without resolution.

## Kotlin

As Java, with `compile the containing module` in place of the Maven or
Gradle packaging phase, and:

```text
on edit           format, lint the edited file; compile its module
edited a test     that test class
build file        resolve the tree; verify the lock or resolution
                  output is committed
```

Avoid: a full project build after one edit · a daemon-cold compile on
every save.

## TypeScript and JavaScript

Identical policy; the tool names differ, the rules do not.

```text
on edit           format and lint the edited file, repo configuration
                  type-check the project incrementally
                  expect exit code and file:line diagnostics only
edited a test     that test file
edited a source   the tests covering it
never on edit     browser suites, container-backed tests
dependency        install with the lock respected, never regenerated
                  silently; audit for advisories; verify the lock
                  change is part of the diff
output            exit code, failing test names, first diagnostic per
                  file; type errors as file:line, deduplicated
```

Avoid: a full type-check from cold on every save · a repository-wide
lint after one edit · an install that rewrites the lock as a side
effect · an advisory noticed after release.

## Python

```text
on edit           format, sort imports, lint the edited file
                  type-check the package containing it
                  expect exit code and file:line diagnostics only
edited a test     that test module
edited a source   the tests covering it
never on edit     container-backed or network-dependent suites
requirements      resolve with the lock respected; audit for
                  advisories; verify the lock change is in the diff
output            exit code, failing test node ids, first assertion;
                  type and lint errors as file:line, deduplicated
```

Avoid: a repository-wide lint after one edit · a type check from cold
on every save · an install that rewrites the lock as a side effect.

## Go

```text
on edit           format the edited file, imports included
                  vet and build the containing package
edited a test     that package's tests
concurrency work  the race detector, on that package
never on edit     integration tags, container-backed suites
module change     tidy; verify the checksum database agrees;
                  confirm both files are part of the diff
output            exit code, failing test names, first failure per
                  package; vet and build errors as file:line
```

Avoid: a repository-wide build after one edit · a linter suite bound to
every save · a dependency added without tidying · a checksum mismatch
noticed in the pipeline.

## SQL

```text
on edit           format; lint dialect-aware; parse against the target
                  engine's grammar
migration edit    apply forward against a disposable database
                  apply the rollback against the same database
                  compare the resulting schema with the expected one
                  never against a shared or production database
query change      capture the plan on production-shaped data
                  compare estimated against actual rows
                  flag a sequential scan on a large table
output            exit code, first diagnostic per file; plan summary
                  as rows, cost, scan types — never the full plan
```

Avoid: a lint configured for a different dialect · a migration applied
only forward · a rollback exercised for the first time during an
incident · a performance claim with no captured plan · a plan read on
development volume.

## Shell

```text
on edit           lint shell-aware; format; syntax-check without
                  executing
before it runs    verify the executable bit matches intent
                  verify strict mode is present
                  verify no unquoted expansion on a destructive line
output            exit code, first diagnostic per file, the failing
                  line and its rule
```

Avoid: a lint that ignores the shebang's dialect · a syntax check that
executes the script · a script committed without a permission review.

## Spring Boot

Extends Java.

```text
configuration     validate the property file parses
                  bind typed properties classes
                  check every referenced property exists
endpoint change   verify the endpoint has an access rule
                  verify the request type is validated
                  list mapped routes and diff against the previous list
startup-affecting run the context once, on the affected module;
                  expect exit code and the first failure only
```

Avoid: a property renamed in one file and read in another · a binding
failure found at startup in an environment · a route merged with no
access rule · a mapping collision found in production · a bean cycle
found by a person rather than a hook.

## Angular

Extends TypeScript.

```text
on edit           lint with the framework's rule set
                  type-check templates, not only the class
                  build the affected project, incrementally
edited a spec     that spec file, headless
edited a source   the specs covering it
never on edit     end-to-end suites, real browsers
workspace change  verify project configuration parses
                  verify budgets still hold for the affected project
```

Avoid: a template error found at runtime · a full workspace build after
one component edit · a bundle budget exceeded and noticed after
release.

## Next.js

Extends TypeScript.

```text
component edit    lint with the framework's rule set
                  verify no server-only import crosses a client
                  directive; type-check the project incrementally
route change      list the routes the build produces
                  diff against the previous list
                  verify each new route declares its strategy
on build          scan the client bundle for known secret names
                  report exit code and the matching file only
```

Avoid: a boundary violation found at build time in the pipeline · a
route added with no strategy stated · a dynamic route made static by a
default nobody read.

## Node.js

Extends JavaScript.

```text
on edit           lint; type-check where types exist
                  verify no synchronous filesystem or crypto call on a
                  request path
dependency        install with the lock respected; audit for
                  advisories; inspect install scripts of new packages
start-up path     run the process; it starts and reports ready
                  verify the shutdown path drains before exit
                  expect exit code and the first failure only
```

Avoid: a blocking call found under load rather than by a hook · an
install that rewrites the lock as a side effect · a start-up failure
found in an environment.
