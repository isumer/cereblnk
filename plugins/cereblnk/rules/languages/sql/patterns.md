---
name: sql-patterns
genre: constraint
category: languages
paths:
  - "**/*.sql"
  - "**/db/migration/**"
  - "**/changelog*.xml"
---

# SQL Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Constraints in the schema

- An invariant the database can hold lives there

```sql
alter table orders
    add constraint orders_total_non_negative
        check (total_minor_units >= 0);

alter table order_items
    add constraint order_items_order_fk
        foreign key (order_id) references orders (id);

create index order_items_order_id_idx on order_items (order_id);
```

Avoid: a rule enforced only in application code · a foreign key with
no index on the child side · a nullable column standing in for an
unmodelled state.

## Set work

- One statement expresses the set
- Row-by-row work belongs outside the database

```sql
update invoices
set    status = 'overdue'
where  settled_at is null
  and  due_date < :cutoff;
```

Avoid: a statement executed once per row · a cursor performing a join
· a temporary table where one query reads clearly.

## Idempotence

- A data change re-runs without doubling its effect

```sql
insert into settlement_locks (order_id, acquired_at)
values (:order_id, now())
on conflict (order_id) do nothing;
```

Avoid: an insert that duplicates on retry · a counter increment with
no guard · a backfill that cannot be resumed.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a table, key, or check is defined | Constraints in the schema |
| rows are modified | Set work |
| a data change may be re-run | Idempotence |
