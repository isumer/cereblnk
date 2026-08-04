---
name: nextjs
description: How to reason about Next.js — where code runs, what crosses to the browser, what the framework cached. Use for App Router or Pages Router work. Constraints in rules/frameworks/nextjs/.
---

# Next.js Skill

## 1. Identity
name: nextjs · domain: frameworks
requires: react · typescript
complements: nodejs
escalate_to: cloud-architecture (edge and deployment topology)

## 2. Mission
Answer where this runs before anything else. The boundary decides
secrets, caching, and failure behavior alike.

## 3. Philosophy

**Reading requests.** "Make this page faster" hides the rendering
strategy question. Static, server-rendered, client, or streamed? Each
carries different data, caching, and failure behavior. "Fetch the data
here" hides a second question. On the server or the client, and does a
secret leak if the answer is wrong?

**Where risk lives.** The server and client boundary. A server-only
import pulled into a client component ships to every browser. A client
boundary drawn too high forfeits server rendering entirely. Below
that: stale cached data, hydration divergence, and fetch waterfalls.

**Verification here.** A "runs on the server" claim is checked against
the bundle, not against intent. Confirm the component sits outside any
client boundary and its imports are server-safe. A caching claim is
checked against the actual directives and revalidation window. Build
output is the evidence.

**False-competence traps.** A server environment value read inside a
client component. A client directive placed at the top of the tree.
Data assumed fresh because it was fetched. Hydration warnings
suppressed instead of resolved.

**Instincts.** Choose the rendering strategy per route, deliberately.
Keep the client boundary as low as it goes. Verify secrets in the
bundle, never by intent. State caching and revalidation explicitly.

## 4. Decision Strategy — the paths

**A component needs interactivity**
→ Draw the client boundary at the smallest subtree that needs it. A
  boundary at the top converts the whole page to client rendering.

**A secret or server-only value is read**
→ Confirm the reading module never crosses to the client. Check the
  emitted bundle. Intent is not evidence here.

**Data is fetched for a page**
→ State where the fetch runs and what caches it. Fetches nested inside
  awaited components serialize into a waterfall.

**Data must be current**
→ State the revalidation explicitly. The framework's default may serve
  a value from the previous window, correctly.

**Server and client render differently**
→ Find the divergence: time, randomness, or browser-only state.
  Suppressing the warning keeps the divergence and hides it.

**A route's strategy is chosen**
→ Name it per route. An unstated strategy means the framework picked
  one, and nobody verified which.

**A third-party client library is imported**
→ Check whether it forces a client boundary. One import can convert a
  server subtree silently.

## 5. Inputs
Route and component source with line refs. Client boundary markers.
Build output and bundle contents for boundary claims. Cache and
revalidation configuration. Network timing for waterfall claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Boundary claims are `known`
only against build or bundle evidence. Freshness claims cite the
revalidation setting.

## 7. Quality Gates
- Every route states its rendering strategy.
- Every server-only value is verified absent from the client bundle.
- Every caching claim cites its revalidation directive.

## 8. Failure Modes
- An environment value shipped to every browser.
- A whole subtree rendered on the client for one button.
- Last window's data served as current.
- Hydration divergence suppressed and preserved.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/nextjs/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | server env value read under a client boundary | secret in the bundle |
| 2 | client directive near the tree root | server rendering lost |
| 3 | freshness claimed with no revalidation setting | stale by default |
| 4 | hydration warning suppressed | divergence preserved |
| 5 | sequential awaited fetches in nested components | waterfall |
| 6 | route with no stated rendering strategy | framework chose it |
| 7 | client-only library imported in a server module | silent boundary shift |

## 9. Worked Example
Claim: "the API key is safe, it is in an environment variable."
Evidence: the module reading it is imported by a component under a
client boundary. Path fires: a server-only value crossing to the
client. Verdict: refuted (Known: import chain, file#L). Fix: read it
in a server module and pass only the result. A bundle grep for the
key name must return nothing.
