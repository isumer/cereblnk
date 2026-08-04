---
name: react-virtualization-patterns
genre: constraint
category: frameworks
paths:
  - "**/*List.tsx"
  - "**/*Table.tsx"
  - "**/virtual*/**/*.tsx"
---

# React Virtualization Patterns

Judgment lives in `skills/frameworks/react-virtualization/`.
Rendering constraints live in [`../../frontend/rendering.md`](../../frontend/rendering.md).

## When a list is virtualised

- Virtualisation starts where the row count is unbounded by data
- A bounded list renders plainly, with no windowing machinery

```tsx
{payments.length > VIRTUALISE_ABOVE
    ? <VirtualPaymentList items={payments} />
    : <PaymentList items={payments} />}
```

Avoid: windowing a list of ten rows. A threshold repeated as a literal
in several components.

## Row identity

- Every row is keyed by a stable domain identifier
- Row components are memoised on primitive props

```tsx
const Row = memo(({ index, style, data }: RowProps) => (
    <div style={style} key={data[index].reference}>
        {data[index].reference}
    </div>
));
```

Avoid: a key taken from the window index. A row prop that is a new
object on every parent render.

## Measurement

- Fixed row height is declared when the design guarantees it
- Variable heights are measured and cached, never estimated per render

```tsx
<VariableSizeList
    itemCount={items.length}
    itemSize={(i) => heights.current[i] ?? ESTIMATED}
    estimatedItemSize={ESTIMATED}
/>
```

Avoid: a fixed height applied to content that wraps. A measurement
recomputed for rows that have not changed.

## Scroll state

- Scroll position is restored from a stored offset, not a row index
- Data loading on scroll is triggered by a range callback

```tsx
<List
    onItemsRendered={({ visibleStopIndex }) =>
        maybeLoadMore(visibleStopIndex)}
    initialScrollOffset={savedOffset}
/>
```

Avoid: scroll restoration that jumps after data loads. A fetch fired on
every scroll event.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a long list or table | When a list is virtualised |
| a row component or key | Row identity |
| an item size or height | Measurement |
| a scroll handler or paging call | Scroll state |
