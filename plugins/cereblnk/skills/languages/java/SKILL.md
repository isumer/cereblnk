---
name: java
description: How to reason about JVM code — invariants, happens-before edges, resource paths, exception truth. Use for any .java implementation or review. Constraints in rules/languages/java/.
---

# Java Skill

## 1. Identity
name: java · domain: languages
complements: junit-testing
escalate_to: spring-boot (framework wiring) · performance-engineering (JVM tuning)

## 2. Mission
Read the invariant, not the annotation. A type promises. Only the
call sites prove.

## 3. Philosophy

**Reading requests.** "Fix this NPE" is rarely about the null. It is
about an absent invariant. Who constructed that object half-built?
"Make it thread-safe" usually hides a missing concurrency model. The
first question is which threads touch this state.

**Where risk lives.** Shared mutable state. equals/hashCode feeding
collections. Static initialization order. Cleanup paths that can
themselves throw. A swallowed exception is silent data loss.

**Verification here.** Read the actual synchronization scope. Read
the actual generic bounds. A thread-safety claim names its
happens-before edge, or it is Assumed. Read the version on the
classpath, not the docs of the latest.

**False-competence traps.** Locks added until the symptom stops. A
broad catch with a log line. Stream chains hiding a side effect.
Optional wrapping a field that stays mutable and public.

**Instincts.** Immutable by default. Smallest visibility that
compiles. Boring standard type over clever dependency. Let types
carry the invariants that comments carry today.

## 4. Decision Strategy — the paths

**A thread-safety claim is made**
→ Name the mechanism and its scope. A synchronized block, a volatile
  field, a concurrent collection's stated guarantee.
→ No named edge means the label drops to Assumed. Say so.

**A concurrent collection is used**
→ Check whether the call site composes two atomic calls. Safe type,
  racing usage is the common shape. Read the sequence, not the type.

**A resource is acquired**
→ Every path releases it, including the throwing one. Cleanup that
  can itself throw needs its own guard.

**An exception is caught**
→ Propagate, translate, or handle. Choose out loud. A log line and a
  swallowed cause is data loss wearing a helmet.

**A field is added to a class used as a map key**
→ equals and hashCode move with it. Otherwise lookups quietly miss.
  The bug then surfaces far from here.

**Mutable state is shared across threads**
→ Name its owner first. Locks added without an owner buy deadlock,
  not safety.

**A library version matters**
→ Read the dependency tree, not the documentation. Transitive
  resolution decides what actually runs.

## 5. Inputs
Source chunks with line refs. Build file, dependencies, Java version.
The failing test or stack trace. Thread and entry-point map for any
concurrency claim.

## 6. Outputs
ACP Response Block only. Facts labeled. Every `known` claim carries
its context ref and lines. Concurrency claims name their
happens-before evidence, or they are not `known`.

## 7. Quality Gates
- Every thread-safety verdict names its mechanism and scope.
- Every resource acquisition has a verified release path.
- Every exception path preserves or deliberately translates the cause.

## 8. Failure Modes
- Deadlock introduced by a lock added as a fix.
- Resources leaked on the exceptional path only.
- equals or hashCode drift after a field addition.
- A cast failure from a raw-type seam the generics hid.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/java/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | key check then put on a concurrent map | composed race |
| 2 | broad catch with only a log line | swallowed failure |
| 3 | lock added without a named owner | liveness risk |
| 4 | field added to a class used as a map key | stale equals/hashCode |
| 5 | release call outside a guarded path | leak when throwing |
| 6 | thread safety claimed from a type name | unproven edge |
| 7 | side effect inside a stream stage | hidden mutation |

## 9. Worked Example
Claim: "this cache is thread-safe, it uses a concurrent map."
Evidence: the call site checks for a key, then puts. Path fires: two
atomic operations composed non-atomically. The map is safe; the usage
races. Verdict: refuted (Known: call site, file#L). Fix: a single
atomic compute call. A test asserts one load under concurrent access.
