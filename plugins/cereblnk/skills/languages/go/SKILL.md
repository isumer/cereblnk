---
name: go
description: How to reason about Go — goroutine ownership, error branches, races, and zero values that look initialized. Use for any .go implementation or review. Constraints in rules/languages/go/.
---

# Go Skill

## 1. Identity
name: go · domain: languages
complements: junit-testing
escalate_to: microservices (service topology decisions)

## 2. Mission
Every goroutine has an owner and a stop signal. Every error is a
branch the code must actually take.

## 3. Philosophy

**Reading requests.** "Make this concurrent" hides two questions. What
owns each goroutine's lifetime? Who closes the channel? Unowned
goroutines are leaks with a delay. "Handle the error" is literal here.
A discarded error is a branch never taken.

**Where risk lives.** Goroutines started with no cancellation. Data
races on shared memory. A nil interface holding a nil pointer. Zero
values that look initialized and are not. Writing to a nil map panics.

**Verification here.** Run the tests with the race detector. A
thread-safety claim without it is Speculative. Audit every returned
error and confirm it is handled. A goroutine claim names its stop
condition: a context, a done channel, a wait group.

**False-competence traps.** Channel choreography where a mutex was
simpler. Errors returned unwrapped, arriving with no origin. The
underscore discard hiding a failure. Goroutines with no lifetime owner.

**Instincts.** Wrap errors with context. Give every goroutine an owner
and a cancellation path. Run the race detector in CI. Keep interfaces
small and defined at the consumer. Accept interfaces, return structs.

## 4. Decision Strategy — the paths

**A goroutine is started**
→ Name its owner and its stop signal before anything else. No stop
  path means a leak that appears only under load.

**A channel is used**
→ State who closes it and when. Ambiguous ownership produces either a
  send on a closed channel or a permanent block.

**An error is returned**
→ Wrap it with the operation that failed. An unwrapped error reaching
  the top says nothing about where it came from.

**An error is discarded**
→ That is a decision. Write why, on that line, or handle it.

**Shared memory is touched by two goroutines**
→ Run the race detector against the real path. Reasoning about
  ordering is not evidence here.

**An interface value is compared to nil**
→ A nil pointer inside an interface is not a nil interface. Check the
  concrete type when the comparison decides control flow.

**A map or slice field is used before assignment**
→ Confirm construction. The zero value reads fine and panics on write.

## 5. Inputs
Source chunks with line refs. Entry points and goroutine start sites.
Race detector output for concurrency claims. Module file for versions.

## 6. Outputs
ACP Response Block only. Facts labeled. Concurrency claims are `known`
only against race detector output. Lifetime claims name the stop path.

## 7. Quality Gates
- Every goroutine start site has a named owner and stop signal.
- Every returned error is handled, wrapped, or explicitly refused.
- Every concurrency verdict cites a race detector run.

## 8. Failure Modes
- Goroutines accumulating under load with no cancellation.
- An error surfacing at the top with no origin context.
- A nil-pointer-bearing interface passing a nil check.
- A panic on first write to an unconstructed map.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/go/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | goroutine started with no context or done path | leak under load |
| 2 | error returned without wrapping | origin lost |
| 3 | underscore discard on an error | branch never taken |
| 4 | channel with no stated closer | block or panic |
| 5 | concurrency claim with no race run | speculation |
| 6 | interface nil check deciding control flow | typed-nil surprise |
| 7 | map field written before construction | guaranteed panic |

## 9. Worked Example
Claim: "the worker stops when the request ends." Evidence: the
goroutine is started with no context and no done channel. Path fires:
a start site with no stop signal. Verdict: refuted (Known: start site,
file#L). Fix: pass the request context and select on its done channel.
A test cancels the parent and asserts the worker returns.
