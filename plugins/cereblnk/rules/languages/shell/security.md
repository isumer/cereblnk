---
name: shell-security
genre: constraint
category: languages
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/Makefile"
---

# Shell Security

Extends [`common/security.md`](../../common/security.md).

## Input

- External values are validated before they reach a command
- A value never becomes part of a command string

```bash
case "${revision}" in
    *[!a-zA-Z0-9._/-]*)
        echo "invalid revision" >&2
        exit 1
        ;;
esac

git log --oneline -- "${revision}"
```

Avoid: a value passed to `eval` · a command assembled by string
concatenation · a filename taken from input without validation.

## Secrets

- Credentials arrive in the environment, never on the command line
- Tracing is off while a secret is in scope

```bash
: "${DEPLOY_TOKEN:?DEPLOY_TOKEN is required}"

set +x
curl --silent --header "Authorization: Bearer ${DEPLOY_TOKEN}" "${url}"
set -x
```

Avoid: a token as an argument, visible in the process list · a secret
echoed by tracing · a credential written to a temporary file.

## Permissions

- Files carrying secrets are created with restrictive permissions
- The script does not widen permissions to make something work

Avoid: a world-readable credential file · a recursive permission
change applied to fix an access error.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an external value is used | Input |
| a credential appears | Secrets |
| a file is created or its mode changed | Permissions |
