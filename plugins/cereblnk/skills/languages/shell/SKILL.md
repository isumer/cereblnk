---
name: shell
description: How to reason about shell scripts — unattended reruns, hostile filenames, destructive lines meeting dynamic values. Use for any .sh or CI script work. Constraints in rules/languages/shell/.
---

# Shell Skill

## 1. Identity
name: shell · domain: languages
complements: linux-ops
escalate_to: jenkins-pipelines (CI context) · github-actions (CI context)

## 2. Mission
Every line may run unattended, on another machine, against names
chosen by chaos. Write for that run, not the demo.

## 3. Philosophy

**Reading requests.** "Write a script that cleans up X" hides two
questions. What must never be deleted? What happens when the script
dies halfway? The literal ask is the happy path. The operational ask
is the unattended rerun at three in the morning.

**Where risk lives.** Anything destructive meeting anything dynamic.
Deletes, overwrites, and truncating redirects, combined with
variables, globs, or substitution. An unquoted variable on a
destructive line is this language's authentication bypass. Below
that sit pipelines that hide a failing first stage.

**Verification here.** Run it. Under strict mode, with tracing, over
a fixture tree holding the hostile cases. Spaces in names. An empty
glob. A missing directory. A half-finished previous run. A script
reviewed and never executed is Speculative.

**False-competence traps.** Option parsing and usage text wrapped
around an unquoted destructive line. Failure suppression added for
robustness. Listing output parsed as data. Portability contortions
for a script that runs on one known interpreter.

**Instincts.** Quote everything. Strict mode on, exceptions stated.
Temporary files and a cleanup trap. Idempotent by design. Destructive
work gets a dry run or an explicit confirmation.

## 4. Decision Strategy — the paths

**A destructive command takes a variable**
→ Quote it, and prove it cannot be empty. An empty value turns a
  scoped delete into a root-level one.
→ Add a dry-run mode before adding anything else.

**A script may be rerun**
→ Design for idempotence. A second run must be safe, including after
  a first run that died midway.

**Temporary files are created**
→ Create them with a temp-file helper and remove them in a trap. A
  fixed path collides, and a missed cleanup accumulates.

**A pipeline's first stage can fail**
→ Enable pipeline failure propagation. Otherwise the last command's
  success hides the first command's failure.

**A glob may match nothing**
→ Decide the empty case explicitly. Unset globs expand to themselves
  and get passed on as literal arguments.

**A failure is deliberately ignored**
→ Say why, on that line. Blanket suppression turns every future
  failure invisible too.

**File names come from the filesystem**
→ Iterate with null separation. Spaces and newlines in names are
  ordinary, not exotic.

## 5. Inputs
The script and its invocation context. The fixture tree used to
exercise it. CI configuration when it runs unattended. The failure
report when debugging.

## 6. Outputs
ACP Response Block only. Facts labeled. A behavior claim is `known`
only when the script was executed against the hostile fixtures.
Untested paths stay Assumed and are named.

## 7. Quality Gates
- Every destructive line has quoted, non-empty-proven arguments.
- Every script is idempotent or documents why it cannot be.
- Every ignored failure states its reason inline.

## 8. Failure Modes
- A scoped delete widened by an empty variable.
- A partial run leaving state that blocks the retry.
- A green pipeline whose first stage failed.
- A loop breaking on the first filename containing a space.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/shell/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | unquoted variable on a destructive line | catastrophic widening |
| 2 | no strict mode at the top of the script | errors continue silently |
| 3 | blanket failure suppression | future failures invisible |
| 4 | fixed temporary path, no trap | collision and leftover state |
| 5 | listing output parsed as records | breaks on real names |
| 6 | glob used without an empty case | literal pattern passed on |
| 7 | destructive script with no dry run | no safe rehearsal |

## 9. Worked Example
Claim: "the cleanup script is safe, it only deletes under the build
directory." Evidence: the path is built from an unquoted variable set
earlier in the same script. Path fires: destructive command taking a
dynamic value. Verdict: refuted (Known: assignment and delete lines,
file#L). Fix: quote it, fail when empty, add a dry run. A fixture
with an unset variable must exit non-zero without deleting.
