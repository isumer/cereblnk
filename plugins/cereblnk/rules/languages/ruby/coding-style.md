---
name: ruby-coding-style
genre: constraint
category: languages
paths:
  - "**/*.rb"
  - "**/*.rake"
  - "**/Gemfile"
  - "**/*.gemspec"
---

# Ruby Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/ruby/`.

## Layout

- The repository's checked-in linter config decides style
- Snake case for methods and variables, Pascal case for classes,
  screaming snake for constants
- Predicate methods end in a question mark; mutating ones in a bang

Avoid: a style argument in review. A per-file lint disable. A bang
method that does not mutate.

## Objects over cleverness

- Domain rules live in plain objects, not in a DSL
- Metaprogramming sits behind a narrow, tested boundary

```ruby
# frozen_string_literal: true

class SettlementWindow
  def initialize(opens:, closes:)
    @opens = opens
    @closes = closes
  end

  def include?(date)
    date >= @opens && date <= @closes
  end
end
```

Avoid: a core class reopened for convenience. A method defined at
runtime with no test naming it. A DSL written for one caller.

## Mutation

- Shared strings and collections are frozen or copied on the way out
- A method either returns a new value or mutates, never both

```ruby
def with_item(item)
  self.class.new(items: items + [item])
end
```

Avoid: an internal array returned directly. A frozen-literal file
mutating a string in place. A caller's argument modified in a method.

## Callbacks

- A callback protects the record's own integrity, nothing further
- External effects are invoked by the caller, in a service

```ruby
class Order < ApplicationRecord
  before_save :normalize_reference

  private

  def normalize_reference
    self.reference = reference.strip.upcase
  end
end
```

Avoid: mail sent from a save callback. A callback chain that fires
during a test fixture. Business rules reached only through persistence.

## Queries

- A collection loaded for iteration loads what the loop reads
- Statement counts are asserted where the shape matters

```ruby
orders = Order.includes(:items).where(settled_at: nil).limit(100)
```

Avoid: an association touched inside a loop. A count issued per row. A
scope that returns every record.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a name or lint change | Layout |
| a class, module, or runtime definition | Objects over cleverness |
| a string or collection is shared | Mutation |
| a persistence callback | Callbacks |
| a collection is iterated | Queries |
