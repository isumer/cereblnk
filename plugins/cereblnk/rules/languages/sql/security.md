---
name: sql-security
genre: constraint
category: languages
paths:
  - "**/*.sql"
  - "**/db/migration/**"
  - "**/changelog*.xml"
---

# SQL Security

Extends [`common/security.md`](../../common/security.md).

## Parameters

- Values bind. They never concatenate into the statement
- Identifiers that must vary come from an allow-list, not from input

```sql
select id, total_minor_units
from   orders
where  tenant = :tenant
  and  id = :order_id;
```

Avoid: a value formatted into the statement · a table or column name
taken from a request · dynamic SQL built from a parameter.

## Privileges

- The application's role holds the narrowest grants that work
- Schema changes run under a separate, elevated role

```sql
grant select, insert, update on orders to app_runtime;
revoke delete on orders from app_runtime;

grant usage on schema settlement to app_runtime;
```

Avoid: an application connecting as an owner · a wildcard grant on a
schema · a migration run with the runtime credential.

## Exposure

- Personal and secret data is never selected into logs or exports
- A view meant for reporting excludes columns nobody reporting needs

```sql
create view reporting.orders_summary as
select o.id,
       o.tenant,
       o.total_minor_units,
       o.settled_at
from   orders o;
```

Avoid: a debug query selecting every column · an export written before
its columns were reviewed.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a statement takes a value | Parameters |
| a grant or role changes | Privileges |
| data leaves the database | Exposure |
