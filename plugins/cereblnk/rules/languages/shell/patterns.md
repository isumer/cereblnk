---
name: shell-patterns
genre: constraint
category: languages
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/Makefile"
---

# Shell Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Idempotence

- A second run is safe
- Safe too after a first run that died midway

```bash
mkdir -p -- "${target}"

if ! grep -qF "${entry}" "${config}"; then
    printf '%s\n' "${entry}" >> "${config}"
fi
```

Avoid: an append that duplicates on retry · a step assuming the
previous run finished · a state file written before the work did.

## Temporary state

- Temporary files are created by a helper and removed by a trap

```bash
workdir="$(mktemp -d)"
trap 'rm -rf -- "${workdir}"' EXIT
```

Avoid: a fixed temporary path · a cleanup step that never runs on
failure · leftover state that blocks the next run.

## Pipelines

- Failure propagates through a pipeline
- The last command's success is not the step's result
- A deliberate ignore states its reason on that line

```bash
set -o pipefail

if ! output="$(build_project 2>&1)"; then
    printf '%s\n' "${output}" >&2
    exit 1
fi
```

Avoid: a green step whose first command failed · a blanket ignore that
hides future failures.

## Rehearsal

- A destructive script offers a dry run
- It defaults to the dry run where the blast radius is wide

```bash
if [[ "${DRY_RUN:-1}" == "1" ]]; then
    printf 'would remove: %s\n' "${target}"
    exit 0
fi
```

Avoid: a destructive script with no rehearsal · a prompt in a script
meant for automation.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a script may be re-run | Idempotence |
| temporary files are created | Temporary state |
| commands are piped | Pipelines |
| the script destroys something | Rehearsal |
