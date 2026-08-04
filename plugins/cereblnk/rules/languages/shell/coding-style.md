---
name: shell-coding-style
genre: constraint
category: languages
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/Makefile"
---

# Shell Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md).
Judgment lives in `skills/languages/shell/`.

## Preamble

- Strict mode at the top; exceptions are stated on the line that needs them
- A shebang naming the interpreter the script was tested against
- Linted by a shell-aware tool, configured in the repo

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Avoid: a script relying on the caller's shell options · an exception
to strict mode with no comment · a lint suppression with no reason.

## Quoting

- Every expansion is quoted
- A destructive line proves its variable is set and non-empty first

```bash
target="${1:?target directory is required}"

if [[ -z "${target}" || "${target}" == "/" ]]; then
    echo "refusing to operate on '${target}'" >&2
    exit 1
fi

rm -rf -- "${target:?}"
```

Avoid: an unquoted expansion anywhere · a destructive command taking a
possibly-empty value · a path built by concatenation without a guard.

## Structure

- Work lives in functions; the script body calls them
- Constants are readonly and declared at the top

```bash
readonly MAXIMUM_ATTEMPTS=3

main() {
    parse_arguments "$@"
    run_migration
}

main "$@"
```

Avoid: a hundred lines of top-level statements · a function relying on
a global it never declares · a constant reassigned mid-run.

## Iteration

- File names are read with a null separator
- A glob that may match nothing states what happens then

```bash
find . -name '*.log' -print0 |
    while IFS= read -r -d '' file; do
        gzip -- "$file"
    done
```

Avoid: a loop over unquoted command output · listing output parsed as
data · a glob passed on as a literal when it matches nothing.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new script | Preamble |
| a variable expansion, or a destructive line | Quoting |
| the script grows | Structure |
| file names are iterated | Iteration |
