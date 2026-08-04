---
name: nodejs
description: How to reason about Node servers — event loop blocking, unhandled rejections, stream backpressure, input reaching the edge. Use for server-side JavaScript work. Constraints in rules/frameworks/nodejs/.
---

# Node.js Skill

## 1. Identity
name: nodejs · domain: frameworks
requires: javascript
complements: typescript
escalate_to: event-driven-architecture (async topology) · devsecops (supply-chain risk)

## 2. Mission
One loop serves every request. Anything that blocks it blocks all of
them, and no amount of hardware fixes that.

## 3. Philosophy

**Reading requests.** "The server hangs under load" is almost always a
blocked event loop. A synchronous call, a computation on the request
path, an oversized parse. It is rarely a capacity problem. "Add error
handling" here means something specific. Every async path has a catch,
every stream has an error listener, and no rejection kills the process.

**Where risk lives.** Blocking work on the request path. Rejections
with no handler. Streams read without backpressure, climbing until
memory runs out. Untrusted input reaching a query or a file path.

**Verification here.** A non-blocking claim is verified under load,
not by reading. Find the synchronous call or the computation on the
hot path. Measure loop lag before blaming the network. For an error
claim, throw inside each async path and confirm a handler catches it.

**False-competence traps.** Synchronous file or crypto calls on the
request path. Fire-and-forget async inside a handler. Large files
streamed with no backpressure. Request values passed straight into a
query or a path.

**Instincts.** Nothing blocking on the hot path; offload computation.
Every promise awaited, returned, or explicitly caught. Streams with
error and backpressure handling. Validate at the edge. Audit the
dependency tree. Drain on shutdown, then exit.

## 4. Decision Strategy — the paths

**Work happens on the request path**
→ Ask whether it blocks. Synchronous file, crypto, or compression
  calls stop every other request while they run.

**Computation is CPU-bound**
→ Move it to a worker or a queue. The loop cannot serve while it
  computes, however fast the machine is.

**An async call appears in a handler**
→ Await it, return it, or catch it. An unattended rejection surfaces
  later, far from its cause, and can end the process.

**A stream is piped**
→ Attach an error listener and respect backpressure. Reading faster
  than writing grows memory until the process dies.

**A request value reaches a query or a path**
→ Validate and parameterize at the edge. Trust granted here cannot be
  withdrawn downstream.

**The process receives a termination signal**
→ Drain in-flight work, then exit. An abrupt exit drops requests that
  were already accepted.

**A dependency is added**
→ Read what it pulls in. The tree is the attack surface, not the
  direct dependency alone.

## 5. Inputs
Handler and middleware source with line refs. Event loop lag
measurements. Stream and file paths on the hot path. Dependency audit
output. Load test results for responsiveness claims.

## 6. Outputs
ACP Response Block only. Facts labeled. Responsiveness claims are
`known` only against measured loop lag or load results. Reading the
code yields `derived` at best.

## 7. Quality Gates
- No synchronous blocking call sits on the request path.
- Every async path in a handler has a named handler for failure.
- Every stream has error handling and respects backpressure.

## 8. Failure Modes
- One slow synchronous call stalling every concurrent request.
- A process exiting on a rejection raised minutes earlier elsewhere.
- Memory climbing until the container is killed mid-stream.
- Requests dropped because shutdown skipped draining.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/nodejs/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | synchronous file or crypto call in a handler | loop blocked |
| 2 | computation loop on the request path | all requests stalled |
| 3 | async call with no await, return, or catch | process-ending rejection |
| 4 | pipe with no error listener | silent stream failure |
| 5 | stream read with no backpressure handling | memory growth |
| 6 | request value concatenated into a query or path | injection surface |
| 7 | termination signal with no drain step | dropped in-flight work |

## 9. Worked Example
Claim: "the endpoint is fast, it just reads a small file." Evidence:
the read is synchronous and sits inside the handler. Path fires: a
blocking call on the request path. Verdict: refuted (Known: handler
line, file#L). Small is irrelevant; the loop stops for its duration
on every call. Fix: read asynchronously, or cache at startup. A load
test must show loop lag flat under concurrency.
