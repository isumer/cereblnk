---
name: yaml-security
genre: constraint
category: languages
paths:
  - "**/*.yml"
  - "**/*.yaml"
  - "**/values*.yaml"
---

# YAML Security

Extends [`common/security.md`](../../common/security.md).

## Secrets

- A credential is referenced, never written
- The reference names where the value comes from at runtime

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: settlement-db
        key: password
```

Avoid: a password, token, or key as a literal. A secret encrypted in
the file with the key beside it. A credential in an example file
committed for convenience.

## Parsing

- Untrusted documents are parsed with a loader that cannot construct
  arbitrary objects
- Document size and nesting depth are bounded before parsing

```yaml
# the consumer's loader, stated where the contract is
parser:
  loader: safe
  max_document_bytes: 1048576
  max_alias_depth: 8
```

Avoid: a full-object loader on input from outside. An unbounded
document accepted from a caller. An anchor expansion with no depth
limit.

## Exposure

- A committed file carries no host name, internal path, or account
  identifier that is not already public

```yaml
# example values, safe to commit
database:
  host: "db.example.internal"
  name: "settlement"
```

Avoid: a real internal endpoint in an example. A production account
identifier in a template. A debug block left enabled in a shared
file.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a credential is referenced | Secrets |
| a document is parsed | Parsing |
| a file is committed | Exposure |
