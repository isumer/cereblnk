---
name: python-security
genre: constraint
category: languages
paths:
  - "**/*.py"
  - "**/*.pyi"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---

# Python Security

Extends [`common/security.md`](../../common/security.md).

## Input

- Values bind as query parameters; they never format into SQL
- Subprocess arguments are a list, never a shell string
- Paths are resolved and confined before opening

```python
cursor.execute(
    "select id, total from orders where tenant = %s and id = %s",
    (tenant, order_id),
)

subprocess.run(["git", "log", "--oneline", revision], check=True)
```

Avoid: an f-string building a query · `shell=True` with a built
command · a path joined from user input without resolution.

## Deserialization

- Untrusted bytes are parsed by a schema into a typed object
- Formats that can construct arbitrary objects are never used on
  untrusted input

```python
order = OrderRequest.model_validate_json(payload)
config = yaml.safe_load(text)
```

Avoid: pickling data from outside the process · loading YAML with a
full-object loader · evaluating a string as code.

## Secrets

- Credentials arrive from the environment or a secret store at runtime
- Required secrets are checked present at startup

```python
api_key = os.environ.get("PAYMENT_API_KEY")
if not api_key:
    raise RuntimeError("PAYMENT_API_KEY is not configured")

db_password = secrets_client.get("db/password")
engine = create_engine(url, connect_args={"password": db_password})
```

Avoid: a key in source · a token in a committed fixture · a credential
printed by a debug helper.

## Dependencies

- The lock file is committed; the tree is audited on change

```text
pinned      exact versions in the lock file, committed
audited     the resolved tree, not the direct requirement
reviewed    install hooks from a newly added package
```

Avoid: an unpinned production requirement · a package added to silence
an import error.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a query, command, or path is built | Input |
| bytes become an object | Deserialization |
| a credential appears | Secrets |
| a requirement changes | Dependencies |
