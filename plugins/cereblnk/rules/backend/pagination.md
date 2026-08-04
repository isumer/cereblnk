---
name: backend-pagination
genre: constraint
category: backend
density: neutral
paths:
  - "**/*Controller.*"
  - "**/*Repository.*"
  - "**/queries/**/*"
---

# Pagination

Extends [`http-apis.md`](http-apis.md) and [`../data/querying.md`](../data/querying.md).

## Every collection is bounded

- A collection endpoint has a default and a maximum page size
- A request above the maximum is clamped, and says so

Avoid: an unbounded list endpoint. A maximum enforced only by the
client that happens to call it.

## Cursor over offset

- Ordered, changing data is paged by cursor
- Offset paging is used only where the set is small and stable

```text
    cursor    opaque, encodes the sort key and the last row
    stable    the sort must be total, with a tiebreaker
    offset    acceptable for fixed reference data
```

Avoid: offset paging over a table that receives inserts. A sort without
a unique tiebreaker, which repeats or skips rows.

## Counting

- Total counts are optional and requested explicitly
- An expensive count is answered as an estimate, labelled as one

Avoid: a count query run on every page request. An exact count promised
over a table that cannot deliver one cheaply.

## Response shape

- The response carries the items and the means to continue
- A final page is distinguishable from a full one

```text
    items         the rows
    next_cursor   absent on the last page
    page_size     what was actually applied
```

Avoid: a client inferring the end from a short page. A cursor the
client is expected to construct.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an endpoint returning a list | Every collection is bounded |
| limit, offset, or a page parameter | Cursor over offset |
| a total or count field | Counting |
| a collection response type | Response shape |
