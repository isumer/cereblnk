---
name: shell-testing
genre: constraint
category: languages
paths:
  - "**/*.sh"
  - "**/*.bash"
---

# Shell Testing

Extends [`common/testing.md`](../../common/testing.md).

## Run it

- A script is executed against a fixture tree before it is trusted
- Reviewing without running yields an assumption, not a fact

```bash
tree="$(mktemp -d)"
mkdir -p -- "${tree}/dir with spaces"
touch -- "${tree}/dir with spaces/file.log"

./cleanup.sh "${tree}"
```

Avoid: a script merged after review only · a claim about behavior with
no run behind it.

## Hostile fixtures

- The fixture carries the cases that break naive scripts

```text
names with spaces and newlines
a glob that matches nothing
a missing directory
a half-finished previous run
an unset required variable
```

Avoid: a fixture with only well-formed names · a test that never
exercises the failure path.

## Exit codes

- Every path returns a distinct, documented exit code
- Tests assert the code, not only the output

```bash
readonly EXIT_INVALID_ARGUMENTS=2
readonly EXIT_MISSING_DEPENDENCY=3
readonly EXIT_TARGET_UNSAFE=4
```

Avoid: a failure exiting zero · a code reused for two different
failures.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a script is written or changed | Run it |
| a test fixture is built | Hostile fixtures |
| a failure path is added | Exit codes |
