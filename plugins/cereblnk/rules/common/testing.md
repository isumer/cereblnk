---
name: common-testing
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Testing

Technology-neutral. Layer choice and suite design live in
`skills/practices/test-strategy/`.

## Red before green

- Write the test, run it, watch it fail — then fix
- A test that passes on the unfixed code encodes nothing

```text
1  write the test, run it, watch it fail
2  apply the minimal fix
3  run it again, watch it pass
4  keep both runs as evidence
```

Avoid: a test written after the fix and never run against the old
code · a regression test that passes on both versions.

## Arrange, act, assert

- Three parts in order, one behavior per test
- The name states the rule, not the method

```text
arrange   the smallest state the behavior needs
act       one call
assert    one behavior, however many fields it touches

names     returns an empty result when nothing matches
names     rejects a settlement past the window
names     falls back to the cache when the index is unavailable
```

Avoid: assertions interleaved with actions · six unrelated assertions
in one test · setup configuring unused collaborators · a name
repeating the method under test.

## Independence

- A test passes alone, repeated, and in any order
- It owns its data and removes it
- Time, randomness and the network are injected, never ambient

Avoid: a test depending on another test's data · a fixed sleep
standing in for a condition · a suite whose order decides its result.

## Coverage means failure modes

- Ask what each test would fail on, never how many there are
- A percentage counts lines, not the race that ships

Avoid: a coverage target treated as the goal · a suite judged by size
· a green run reported as confidence.

## Flake

- A flaky test is fixed or deleted, never retried into green
- Retrying trains the team to dismiss real failures

Avoid: a retry wrapper on a failing test · a quarantine list that only
grows.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a fix is submitted | Red before green |
| a test is added | Arrange, act, assert |
| a test uses shared state | Independence |
| coverage is reported | Coverage means failure modes |
| a test fails intermittently | Flake |
