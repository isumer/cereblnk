---
name: sql-testing
genre: constraint
category: languages
paths:
  - "**/*.sql"
---

# SQL Testing

Extends [`common/testing.md`](../../common/testing.md).

## Against the real engine

- Statements run on the production engine, at its version
- Fixtures are shaped like production, not like a dev table

```sql
-- fixture shaped like production, not like a demo
insert into orders (id, tenant, total_minor_units, due_date)
select gen_random_uuid(), 'acme', 1200, current_date - 40
from   generate_series(1, 100000);
```

Avoid: a query proven on a substitute engine · a plan read on ten rows
· a dialect difference found after release.

## Migrations

- Forward and rollback both execute in the pipeline
- A destructive step says whether the data returns

```sql
-- forward
alter table orders add column settled_at timestamptz;

-- rollback
alter table orders drop column settled_at;
```

Avoid: a rollback written and never run · a drop whose rollback only
restores the column · a migration tested on an empty table.

## Constraints

- Every constraint has a violating case, and it is rejected

```sql
-- expected to fail
insert into orders (id, total_minor_units) values ('ord_1', -1);
```

Avoid: a check constraint added with no failing case · a foreign key
trusted without a test · a unique index assumed, not proven.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a query is written | Against the real engine |
| a schema change is written | Migrations |
| a constraint is added | Constraints |
