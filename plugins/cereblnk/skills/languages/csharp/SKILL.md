---
name: csharp
description: How to reason about C# — nullability the compiler can check, async that must not be blocked, and disposal the runtime will not do for you. Use for any .cs implementation or review. Constraints in rules/languages/csharp/.
---

# C# Skill

## 1. Identity
name: csharp · domain: languages
complements: api-design
escalate_to: performance-engineering (allocation and hot paths)

## 2. Mission
Nullability, disposal and async are the three the compiler will help
with only if you let it. Turn them on and read what it says.

## 3. Philosophy

**Reading requests.** "Fix this null reference" is usually a
nullability annotation the project never enabled. "Make it async" is
not a mechanical change: it alters cancellation, disposal order and
where exceptions surface.

**Where risk lives.** Blocking on an asynchronous call, which
deadlocks in some contexts and starves in others. Disposal skipped on
a throwing path. Struct copies where a reference was assumed. And
nullable warnings suppressed rather than answered.

**Verification here.** Read the compiler's nullable diagnostics on that
file, not the annotation. An async claim is verified by following the
call to something that truly awaits, not to a wrapper that blocks. A
disposal claim is verified by finding the using scope.

**False-competence traps.** An async method returning void, so its
failure has nowhere to go. `.Result` on a task inside a request.
Suppressions accumulating because the nullable rollout was never
finished. A disposable held in a field with no disposal of the holder.

**Instincts.** Nullable reference types on, warnings answered not
silenced. Async all the way, with cancellation passed through. Records
for values, classes for identity. Dispose what you create, in a using
scope.

## 4. Decision Strategy — the paths

**A null reference is reported**
→ Check whether nullable annotations are enabled here. Without them
  the compiler was never allowed to warn.

**A nullable warning appears**
→ Answer it. A suppression is a claim that needs the same
  justification as any other.

**An async call is made**
→ Await it, and pass the cancellation token onward. Blocking on the
  result trades a suspension for a stalled thread.

**An async method is declared**
→ Return a task, never void. A void async failure has nowhere to
  surface and terminates elsewhere.

**A disposable is created**
→ Scope it with using. If a field holds it, the holder disposes too.

**A struct is passed or stored**
→ Ask whether a copy is intended. Value semantics surprise callers who
  expected a reference.

**A collection is exposed**
→ Return a read-only view. A caller's mutation of an internal list is
  invisible at the boundary.

## 5. Inputs
Source with line refs. Project file: language version, nullable
setting, target framework. Compiler diagnostics. Async call chains for
scheduling claims. Disposal scopes.

## 6. Outputs
ACP Response Block only. Facts labeled. A nullability claim is `known`
only against compiler diagnostics. Async behavior claims name the
awaited call.

## 7. Quality Gates
- Nullable reference types are enabled and warnings are answered.
- Every async path awaits and forwards its cancellation token.
- Every disposable has a scope or a disposing holder.

## 8. Failure Modes
- A request thread stalled by blocking on a task.
- An async void failure terminating a process elsewhere.
- A connection leaked on the throwing path.
- A struct mutated on a copy while the caller saw no change.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/csharp/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | a null warning suppressed | claim without justification |
| 2 | blocking on a task result | stalled or deadlocked thread |
| 3 | an async method returning void | failure with nowhere to go |
| 4 | a disposable with no using scope | leak on the throwing path |
| 5 | a cancellation token not forwarded | work that cannot be stopped |
| 6 | an internal collection returned | mutation at a distance |
| 7 | `dynamic` in application code | checking deferred to runtime |

## 9. Worked Example
Claim: "the handler is asynchronous." Evidence: it calls an async
method and reads its result property. Path fires: blocking on a task
result. Verdict: refuted (Known: handler line, file#L). The thread
waits, and under load the pool starves. Fix: await the call and forward
the cancellation token.
