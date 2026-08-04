---
name: angular
description: Change detection, injector scope, subscriptions, signals — how to reason about Angular work. Use for any Angular implementation or review. Constraints in rules/frameworks/angular/.
---

# Angular Skill

## 1. Identity
name: angular · domain: frameworks
requires: typescript
complements: component-testing · accessibility
escalate_to: security-agent (guard/interceptor order on auth paths) · performance-engineering (CD profiling)

## 2. Mission
Reason in change-detection cycles and injector lifetimes: what
triggers the view, who owns the subscription, which scope holds the
service.

## 3. Philosophy

**Reading requests.** "The view doesn't update" is a change-detection
question before a data question: zone, OnPush inputs, mutation versus
reference. "Add a service" hides the injector-scope decision — three
lifetimes, three bug families.

**Where risk lives.** Subscription leaks. OnPush fed by mutation.
Guard and interceptor order encoding unwritten security assumptions.
Effects ordered by template accident.

**Verification here.** Trace the trigger path: event → zone/signal →
CD cycle. Prove leaks by counting live subscriptions across
create/destroy cycles. Template plausibility is not evidence.

**False-competence traps.** Operator golf hiding one race. Async-pipe
theater above a leaking manual subscribe. OnPush adopted with mutation
left in place, then markForCheck sprinkled blindly. A copied
guard stack with unread order.

**Instincts.** OnPush pairs with immutable data. Subscriptions are
owned by lifecycle or template, never by hope. DI scope is decided
out loud. Simplify the state model before the operator chain.

## 4. Decision Strategy — the paths

**The view does not update**
→ Check the input reference: mutated object under OnPush never
  triggers. Fix the data flow; do not sprinkle markForCheck.
→ Signal-based: confirm the read is inside a reactive context.

**A subscription is created**
→ Template async pipe first. Manual subscribe carries
  takeUntilDestroyed, or it is a leak finding.
→ Verify: live-subscription count across two create/destroy cycles.

**A service is added**
→ Decide the scope aloud: root singleton, lazy-module, or
  component-scoped. State the chosen lifetime in the block.

**A guard or interceptor changes**
→ Read the whole chain order first. Auth-relevant order is a
  security surface: escalate to security-agent at level 3.

**RxJS complexity grows past the state's complexity**
→ Simplify the state model first. Five-operator chains hide races;
  re-derive before trusting.

**OnPush is proposed for speed**
→ Only with immutable inputs proven. Otherwise the view freezes and
  the workaround becomes the bug.

## 5. Inputs
Component/service source. The injector tree for the path. Guard and
interceptor chain. Subscription instrumentation or harness tests.

## 6. Outputs
ACP Response Block only. Update-path claims `known` via repro or
harness test. Leak claims `known` via subscription counts. Order
assumptions `assumed` until the chain is read.

## 7. Quality Gates
- Every manual subscription names its owner (lifecycle or template).
- Every new service states its injector scope and why.
- Guard/interceptor changes cite the full chain order.

## 8. Failure Modes
- Long-lived observable in a short-lived component.
- OnPush view frozen by upstream mutation.
- Interceptor reorder silently widening an auth exemption.
- Route resolver swallowing errors into an empty view.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/angular/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | subscribe without takeUntilDestroyed/async pipe | leak |
| 2 | OnPush component receiving mutated objects | frozen view |
| 3 | markForCheck without a stated data-flow reason | symptom patch |
| 4 | guard/interceptor added without chain-order citation | auth order |
| 5 | five-plus operator chain on simple state | hidden race |

## 9. Worked Example
Claim: "the price panel updates live." Evidence: OnPush component;
the feed mutates the same array instance. Path 1 fires: reference
never changes, CD never runs — worked in dev only via unrelated
events. Verdict: refuted (Known: input identity, file#L). Fix: emit
new arrays; harness test asserts render on emission.
