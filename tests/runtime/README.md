# Runtime verification

Everything in `policies/hosts/` except `claude.yaml` says `declared:` —
taken from a vendor's own reference, which establishes what an interface
offers and nothing about whether our hooks fire on it. This directory
holds the machinery for closing that gap with runs.

It is an evidence layer. It does not decide what Cereblnk can do:
capabilities come from `policies/capabilities.yaml`, bindings from
`policies/hosts/<host>.yaml`, and a probe that started answering those
questions would be a second source of truth competing with the first.

    capabilities.yaml → hosts/<host>.yaml → gen-bindings
                                                 ↓
                                            host-probe
                                                 ↓
                                         runtime evidence
                                                 ↓
                                          host matrix

## Stages

A run is walked in stages so that a failure says which layer it failed
at. "The host worked" is not a result anyone can act on.

| stage | what it demonstrates |
|---|---|
| `install` | the host CLI is present and reports a version |
| `context` | the host loads the instruction file |
| `marketplace` | a repo-local registry is accepted |
| `plugin` | the package is discovered and installed |
| `skill` | a Cereblnk skill is discovered and invoked |
| `agent` | a specialist is selected |
| `subagent` | a subagent runs and finishes |
| `hook` | a hook script is reached at all |
| `veto` | a hook refuses **and the action does not happen** |
| `finish` | the run guard is reached at the end of a turn |

Not every host reaches every stage. `scripts/host-probe` carries the set
each one can, and a stage outside it is recorded `UNSUPPORTED` rather
than left out — a missing stage reads as untested, and untested is not
unsupported.

## Statuses

| status | meaning |
|---|---|
| `PASS` | the expected behaviour was observed |
| `FAIL` | the stage ran and contradicted the contract |
| `BLOCKED` | an external dependency stopped it — no credentials, a runner restriction, a vendor outage |
| `UNMEASURED` | no valid measurement exists yet |
| `UNSUPPORTED` | the host exposes no equivalent capability |

Two rules do the work here. **`BLOCKED` never becomes `FAIL`**, because a
missing credential is not a defect in this repository. **`UNMEASURED`
never becomes `PASS`**, because that is the failure the probe exists to
refuse. `BLOCKED` and `UNSUPPORTED` must carry a `reason`; a status that
says a thing did not happen without saying why is a note to nobody.

Uppercase is deliberate. Capability states in the matrix are lowercase —
`M`, `declared:M`, `unmeasured` — and stage results are uppercase. They
answer different questions and one word appearing in both would invite
exactly the conflation this layer exists to avoid.

## Running a probe

    scripts/host-probe install <host>

That prints the hook configuration to paste and the stages to walk. Then,
as each stage is reached:

    scripts/host-probe attest codex --stage hook --result PASS \
        --capability veto.destructive-command \
        --evidence "hook script reached, exit 0"

    scripts/host-probe collect codex --write

`--capability` is checked against `capabilities.yaml` and refused if
absent. A stage classifies an observation; it never names a capability.

Two facts no ordinary session shows are attested separately, because a
person has to provoke them:

    scripts/host-probe attest codex --refusal-enforced yes|no
    scripts/host-probe attest codex --failure-mode open|closed

## The veto stage, and the trap in it

A veto stage proves two things, not one: the guard refused, **and the
action did not happen**. A hook can print a refusal into a stream nobody
reads while the tool call goes through underneath, and a probe checking
only stderr records `PASS` for a guard that is not guarding.

So the provocation writes to a path a guard refuses, and the check is
whether that path exists afterwards. Absence is the evidence. See
`fixtures/veto-fixture/`.

Never provoke a guard with an operation that would matter if it
succeeded. A probe that depends on a refusal holding has assumed its own
result.

## Running the whole sequence

    tests/runtime/run-host codex --out summary.json

One runner, not four. The stages are the same questions on every host and
only the commands differ, so four near-identical runners would drift
apart in the way this repository spends most of its checkers preventing.
Host-specific logic is a stage script:

    tests/runtime/<host>/stages.sh

Each stage prints its result and the runner reads it:

    CB_STATUS=PASS|FAIL|BLOCKED|UNMEASURED|UNSUPPORTED
    CB_REASON=<why>            required for BLOCKED and UNSUPPORTED
    CB_CAPABILITY=<id>         must exist in capabilities.yaml
    CB_EVIDENCE=<observation>  a path in the artifact, or a short note

A stage cannot award itself a result the runner did not see, because
nothing but the runner writes the artifact.

When `install` is BLOCKED or FAIL the run halts, and everything
downstream is recorded UNMEASURED rather than BLOCKED. Nobody measured
them; calling them blocked would claim to know why.

All four have drivers. What each measures without credentials differs,
because the hosts differ:

| host | measured offline |
|---|---|
| claude | marketplace source resolves; the committed binding matches its generator |
| codex | the repo-local registry parses; the vendor validator's verdict on the manifest |
| cursor | marketplace source resolves; the hooks redirect points at the generated binding |
| gemini | the context file resolves; **the hooks collision, as FAIL** |

Gemini's `hook` stage is the one to look at. It needs no session: this
host reads `hooks/hooks.json` from the extension root, that file is
Claude Code's binding, and whether it is Claude's is a fact about this
tree. It reports FAIL, because surfacing that is the point — a runtime
test that hid a known collision would be worse than no runtime test.

Cursor's stages distinguish two things a single BLOCKED would blur: no
credentials, and no way to reach the surface from a runner at all. The
second is a finding about the host, and its install stage says so rather
than leaving an absent install step to look like an oversight.

## In CI

`.github/workflows/runtime-smoke.yml`, in tiers:

| tier | what | when |
|---|---|---|
| 1 | packaging and generation, no host binary | relevant pull requests, once |
| 2 | host CLI install, version, discovery | relevant pull requests, all four hosts |
| 3 | authenticated session — skill, hook, veto | wherever secrets exist |

A pull request probes **all four hosts**, not one. A change to the shared
runner or to `capabilities.yaml` reaches every host, and a workflow that
quietly probed one would let three drivers rot untested — which is what
happened for a day between the drivers landing and the matrix arriving.
`workflow_dispatch` probes the host you name.

Tier 1 runs once as a gate rather than inside each probe: a runtime
result measured against a tree nobody vouched for is worth nothing, and
four identical verifications of the same commit is three wasted runners.

Tier 3 is not mandatory, and that is a decision rather than an omission.
CI that depends on a vendor session is flaky CI, and flaky mandatory CI
teaches people to ignore red. Without credentials those stages report
BLOCKED with a reason, which is evidence — so the workflow costs nothing
extra until a secret exists, and needs no change when one does.

## Taking the measurement

Configure whichever of these the repository has access to:

    CODEX_API_KEY · ANTHROPIC_API_KEY · GEMINI_API_KEY

Then a push to a release branch runs the matrix with them. Dispatch works
too, but it needs an `actions:write` token, and a measurement should sit
behind a decision rather than behind a permission. A merge is a thing
that happens anyway.

Nothing else changes. The stage scripts check for a credential and take
the authenticated path when they find one; until then, `needs_auth`
returns BLOCKED and no session is opened, so no cost is incurred.

The artifact uploads even when stages failed. A failed run is the
evidence somebody needs most, and discarding it leaves only a red tick.

## Fixtures

`fixtures/safe-project/` is the disposable target. Copy it to a temporary
directory; never point a probe at this repository. It is deliberately
small and deliberately worthless.

## Evidence

`schema/runtime-evidence.schema.json` is the written contract;
`scripts/check-runtime-evidence` is the executable one, and
`--self-test` asserts the two have not drifted apart.

An artifact records host, host version, repository, source commit,
timestamp and per-stage results. **A `PASS` without a host version is
weak evidence**, because host behaviour changes independently of
anything here — a stage that passed last month and fails today is either
a regression or a vendor contract change, and only the version tells you
which.

## What is not committed

Run results are not. The repository stores how to reproduce evidence; a
particular execution's evidence belongs in CI artifacts. A committed log
becomes stale truth that nobody re-derives.

Never in an artifact: credentials, tokens, authorization headers, or a
whole host configuration directory. `check-runtime-evidence` looks for
the obvious shapes before an upload, which is a last look rather than a
secret scanner.

## What this layer must not do

It may prove a distribution problem exists. It must not fix one. Three
hosts want the same conventional hooks filename and CB-143 holds that
decision; a `dist/` tree introduced here to make a probe pass would be
outside `check-generated` and would recreate the drift the binding
architecture exists to prevent.

`scripts/verify` stays offline and deterministic. Host runtime
certification is an online integration layer that runs beside it, never
inside it.
