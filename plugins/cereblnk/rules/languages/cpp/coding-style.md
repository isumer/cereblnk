---
name: cpp-coding-style
genre: constraint
category: languages
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.cc"
  - "**/*.h"
  - "**/CMakeLists.txt"
---

# C++ Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/cpp/`.

## Layout

- Formatting by a tool with a committed configuration
- One standard version, stated in the build, not per file
- Headers self-contained: each compiles on its own

Avoid: a style argument in review. A header depending on an include
order. A compiler extension used without stating it.

## Resources

- Every resource is owned by an object and released by scope
- Exclusive ownership first; shared only when two owners exist

```cpp
auto connection = std::make_unique<Connection>(endpoint);

std::ifstream input{path};
if (!input) {
    throw std::runtime_error{"cannot open " + path.string()};
}
```

Avoid: raw allocation paired with manual release. A shared pointer
chosen because lifetime was unclear. A close call on the success path
only.

## Lifetime

- A returned reference outlives its call, or the value is returned
- A captured reference states that its referent outlives the capture

```cpp
[[nodiscard]] Money total() const { return total_; }

// the span's referent must outlive the span; state it at the boundary
[[nodiscard]] std::span<const LineItem> items() const& { return items_; }
auto items() && = delete;
```

Avoid: a reference to a local or a temporary. A lambda capturing by
reference and outliving the frame. A pointer stored with no stated
owner.

## Const and moves

- Parameters are references to const unless ownership transfers
- A transfer moves; a copy is deliberate and visible

```cpp
void record(const Receipt& receipt);
void adopt(std::unique_ptr<Connection> connection);

auto owned = std::move(candidate);
```

Avoid: a large object passed by value with no reason. A moved-from
object read afterwards. Const applied to the pointer and not the
pointee.

## Concurrency

- Shared state names its synchronisation, and the sanitisers run in CI

```cpp
class RateWindow {
public:
    void record() {
        const std::lock_guard guard{mutex_};
        ++count_;
    }

private:
    mutable std::mutex mutex_;
    std::uint64_t count_{0};
};
```

Avoid: shared mutable state with no lock named. A volatile qualifier
used as synchronisation. A race investigated by reading.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a header or build setting | Layout |
| a resource is acquired | Resources |
| a reference or pointer escapes | Lifetime |
| a parameter or a transfer | Const and moves |
| two threads share state | Concurrency |
