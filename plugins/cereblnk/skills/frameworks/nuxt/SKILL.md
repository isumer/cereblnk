---
name: nuxt
description: How to reason about Nuxt — where code runs, what the convention already decided, and state that must not leak between requests on the server. Use for Nuxt application work. Constraints in rules/frameworks/nuxt/.
---

# Nuxt Skill

## 1. Identity
name: nuxt · domain: frameworks
requires: vue
complements: typescript
escalate_to: cloud-architecture (deployment topology)

## 2. Mission
Answer where this runs before anything else. Then ask what the
directory convention already decided for you.

## 3. Philosophy

**Reading requests.** "Add a page" hides which rendering mode the route
uses and what the convention wires automatically. "Fetch the data here"
hides the decisive question: on the server, the client, or both — and
whether a secret leaks if the answer is wrong.

**Where risk lives.** Server state that outlives a request, because the
server process is shared while the client is not. Auto-imports hiding
where a symbol came from, so a rename breaks a file nobody edited.
Secrets reachable from client code. And hydration divergence, where
server and client disagree and the fix is usually a timing assumption.

**Verification here.** A "runs on the server" claim is checked against
the build output, not the directory name. A secret's absence is checked
in the client bundle. A state-leak claim is verified by two requests,
not by reading. Rendering mode is read from the route's declaration.

**False-competence traps.** Module-level state on the server, which is
per-process rather than per-request. A composable holding a value the
next visitor inherits. Auto-imports treated as magic instead of a
resolvable convention. Runtime configuration used for a secret the
client can read.

**Instincts.** Declare the rendering mode per route. Keep request state
in request scope. Read secrets only in server code. Verify boundaries
against the bundle, never against intent.

## 4. Decision Strategy — the paths

**Code holds state at module level**
→ Ask whether it runs on the server. There it is shared across every
  request, and one visitor's value becomes another's.

**Data is fetched**
→ State where it runs and what caches it. The same call on server and
  client fetches twice unless the result is transferred.

**A secret is read**
→ Confirm the reading module never reaches the client. Runtime
  configuration splits public from private, and the split is checkable.

**A route is added**
→ Declare its rendering mode. An unstated mode means the framework
  chose one and nobody verified which.

**A symbol appears with no import**
→ Resolve where the convention brings it from. Auto-import is a
  resolvable rule, not magic, and a rename can break a distant file.

**Server and client render differently**
→ Find the divergence: time, randomness, or storage. Suppressing the
  warning preserves the bug.

**A composable stores a value**
→ Ask what its lifetime is on the server. A composable is not a
  request scope by itself.

## 5. Inputs
Route and component source with line refs. Rendering mode declarations.
Build output and client bundle for boundary claims. Runtime
configuration split. Two-request observations for state-leak claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Boundary claims are `known`
only against bundle evidence. State-leak claims cite two requests.

## 7. Quality Gates
- Every route states its rendering mode.
- Every server-only value is verified absent from the client bundle.
- Every server-side state holder is request-scoped or proven immutable.

## 8. Failure Modes
- One visitor's data served to the next from module-level state.
- A private value shipped in the client bundle.
- The same data fetched twice, once per side.
- Hydration divergence suppressed and preserved.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/nuxt/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | module-level state in server code | shared across requests |
| 2 | a private value read outside server code | secret in the bundle |
| 3 | a route with no rendering mode | framework chose it |
| 4 | a fetch with no stated side | duplicated request |
| 5 | a hydration warning suppressed | divergence preserved |
| 6 | a composable holding state on the server | lifetime undecided |
| 7 | an auto-imported symbol renamed | distant file broken |

## 9. Worked Example
Claim: "the cache is per user, it lives in a composable." Evidence: the
value is declared at module scope and the code runs on the server. Path
fires: module-level state in server code. Verdict: refuted (Known:
declaration and route mode, file#L). Fix: move it into request scope,
then prove it with two requests from different users.
