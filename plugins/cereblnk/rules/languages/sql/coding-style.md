---
name: sql-coding-style
genre: constraint
category: languages
paths:
  - "**/*.sql"
  - "**/db/migration/**"
  - "**/changelog*.xml"
---

# SQL Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/sql/`.

## Layout

- Keywords in one case, consistently, across the repository
- One clause per line; a joined table and its condition stay together
- Columns listed explicitly, never a wildcard in shipped code

```sql
select o.id,
       o.tenant,
       o.total_minor_units
from   orders o
join   customers c on c.id = o.customer_id
where  o.settled_at is null
  and  o.due_date < :cutoff
order  by o.due_date;
```

Avoid: a wildcard in a view, an API, or a migration · a query written
as one long line · two keyword cases in one file.

## Naming

- Tables plural, columns singular, both lowercase with underscores
- A foreign key names the table it points at
- Units and currency scale live in the column name

Avoid: a column named for its type · an abbreviation invented for one
table · a boolean column whose name does not read as an assertion.

## Predicates

- Comparisons against nullable columns state the three-valued outcome
- A negated set membership excludes nulls explicitly

```sql
where c.deleted_at is null
  and o.status not in ('cancelled', 'refunded')
  and o.customer_id not in (
      select id from customers where blocked and id is not null
  );
```

Avoid: an equality test against null · a negated subquery that may
contain null · a function wrapping an indexed column in a predicate.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a query is written | Layout |
| a table or column is created | Naming |
| a comparison against a nullable column | Predicates |
