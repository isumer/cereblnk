---
name: nginx
description: How to reason about nginx — which block actually matches, what a child silently drops from its parent, and reading the effective config rather than the fragment. Use for proxy and TLS work.
---

# Nginx Skill

## 1. Identity
name: nginx · domain: infrastructure
complements: linux-ops · kubernetes · observability
escalate_to: security-agent (TLS and header exposure) · sre-agent (production traffic)

## 2. Mission
Read the effective configuration, then trace one real request. The
fragment you edited is not what the server runs.

## 3. Philosophy

**Reading requests.** "Add a proxy rule" hides which block will
actually match and what it inherits. "It returns a gateway error" is a
question about the upstream and the timeout settings, not about the
proxy being broken. The literal ask is a directive; the real ask is
the request's full path through matching, rewriting, and proxying.

**Where risk lives.** Match precedence, where a rule that should apply
does not. Inheritance, where a child block declaring its own headers
silently drops the parent's. Trailing-slash semantics that change the
proxied path. TLS and header handling, where security lives.

**Verification here.** Read the full effective configuration with
includes expanded and inheritance resolved. Never reason from the
fragment. Then trace a real request with the exact host and path, and
read the logs. A "this rule applies" claim is verified by the request,
not by the file's appearance.

**False-competence traps.** Reasoning from an edited fragment. Header
blocks copied into a child, dropping everything the parent set. A
trailing slash added or removed without checking the resulting path.
Reloads reported as proof that the intended rule took effect.

**Instincts.** Dump the effective config before judging anything.
Trace one request end to end. Keep header settings in one place per
path. Treat every timeout as a decision, not a default.

## 4. Decision Strategy — the paths

**A routing rule is added**
→ Confirm which block wins for the target path. Precedence rules
  decide this, and the intended block often loses.

**A child block sets headers**
→ Check what the parent set. Declaring headers in a child replaces
  the inherited set rather than adding to it.

**A proxy target is written**
→ Read the trailing slash on both sides. It decides whether the
  matched prefix is stripped, and the resulting path differs.

**A gateway error appears**
→ Investigate the upstream and the timeouts before the proxy. The
  proxy is reporting a failure, not usually causing it.

**TLS or forwarded headers are configured**
→ Confirm what reaches the application. Missing forwarded headers
  turn every client into the proxy's address.

**A reload is performed**
→ Verify with a traced request. A successful reload means the syntax
  parsed, not that the intent took effect.

**Timeouts are left at defaults**
→ Decide them against the upstream's real behavior. Defaults were
  chosen for a different application.

## 5. Inputs
The full effective configuration with includes expanded. Traced
request output with exact host and path. Access and error logs.
Upstream behavior and timings. TLS and header settings.

## 6. Outputs
ACP Response Block only. Facts labeled. Matching claims are `known`
only against a traced request. Configuration claims cite the effective
dump, not the edited file.

## 7. Quality Gates
- Every matching claim is proven by a traced request.
- Every child header block accounts for what the parent set.
- Every proxy target states its path-rewriting behavior.

## 8. Failure Modes
- A rule that never matches while looking correct in its file.
- Authentication headers lost because a child block redeclared them.
- A proxied path off by one segment from a trailing slash.
- Client addresses replaced by the proxy's own throughout the logs.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/infrastructure/nginx/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | rule judged from a fragment, not the effective config | wrong block wins |
| 2 | child block redeclaring headers | parent's headers dropped |
| 3 | proxy target with unexamined trailing slash | path off by a segment |
| 4 | gateway error blamed on the proxy | upstream unread |
| 5 | forwarded headers unset | client identity lost |
| 6 | reload cited as proof of behavior | syntax only |
| 7 | timeouts left at defaults | mismatched to upstream |

## 9. Worked Example
Claim: "the auth header is forwarded, it is in the config." Evidence:
the parent sets it; the matching child declares one header of its own.
Path fires: a child block redeclaring headers. Verdict: refuted
(Known: effective config and traced request). The child replaced the
inherited set. Fix: set the full header list where it applies, then
trace the request again.
