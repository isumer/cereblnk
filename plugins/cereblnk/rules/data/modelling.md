---
name: data-modelling
genre: constraint
category: data
density: neutral
paths:
  - "**/entity/**/*"
  - "**/model/**/*"
  - "**/schema/**/*"
---

# Data Modelling

Judgment lives in `skills/data/data-modeling/`.

## Invariants

- An invariant the database can hold is held there
- Application code enforces it too, never instead

```text
in the schema    not-null, unique, check, foreign key
in the code      rules the schema cannot express
never            an invariant living only in one writer
```

Avoid: a rule enforced by one service while a job writes around it. A
nullable column standing in for an unmodelled state. A constraint
dropped to make an import pass.

## Identity

- Keys are meaningless and stable; business values are attributes
- A natural key that can change is not the primary key

Avoid: a key carrying meaning that later must change. An identifier
reused after deletion. A composite key that grows a column.

## Shape

- Normalised until a measured plan objects
- A denormalised value names its single update path

Avoid: denormalisation before a measurement. Two copies of one truth
with two writers. A key-value table standing in for a model nobody
designed.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a table or column is defined | Invariants |
| an identifier is chosen | Identity |
| a shape is denormalised | Shape |
