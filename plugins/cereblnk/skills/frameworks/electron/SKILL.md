---
name: electron
description: How to reason about Electron — a browser with an operating system behind it, where one webPreferences flag turns cross-site scripting into code execution. Use for main, preload, or renderer work. Constraints in rules/frameworks/electron/.
---

# Electron Skill

## 1. Identity
name: electron · domain: frameworks
requires: nodejs
complements: typescript · owasp-threat-modeling
escalate_to: security-agent (trust boundary decisions)

## 2. Mission
The renderer is untrusted content with a machine behind it. Every
question here is about what crosses from there to here.

## 3. Philosophy

**Reading requests.** "Give the renderer access to the file system"
is never the request to satisfy literally. The operation it needs is. Behind one fixed channel. "Turn off context isolation, the library needs it" removes two
protections. Disabling isolation also disables the process sandbox.
Any sandbox setting is overridden by it.

**Where risk lives.** The webPreferences of every window. In a modern version the safe values are the defaults. So the danger
is not forgetting to enable them. It is switching them off to unblock
a library. Then the preload script, which is far more privileged than
the renderer it serves. Then every inter-process message, which is a
request from an untrusted client. Then navigation, external links, and
the auto-updater.

**Verification here.** Read the effective preferences of the window that loads the content.
Not the constructor you found first. A webview tag or a second window
may differ. A bridge claim is
verified by reading what the preload exposes — a narrow function or a
generic invoke. A validation claim is verified in the main process,
where the decision is made, never in the renderer that asked.

**False-competence traps.** A general message sender exposed through the bridge. The renderer
then reaches every channel, and it reads as correct because a bridge
was used. Node integration enabled during
development and shipped. Web security disabled to load a local file.
Permission requests granted wholesale because the default felt
inconvenient.

**Instincts.** Keep the defaults and justify any departure in writing.
Expose one function per operation, never a channel. Validate the
argument and the sender in the main process. Restrict navigation and
new windows by allow-list. Assume the bundle is readable, so secrets
stay in the main process.

## 4. Decision Strategy — the paths

**A window is created**
→ Read its effective preferences. Isolation on, node integration off,
  sandbox on, web security on. A departure is documented with what it
  unblocks and what it costs.

**Node integration is proposed**
→ Refuse by default. Enabling it disables the process sandbox for
  that renderer, so one flag removes two protections.

**The preload exposes something**
→ Expose the operation, not the mechanism. A generic sender lets the
  renderer call any channel, and using the bridge does not make that
  safe.

**A message arrives from a renderer**
→ Validate the arguments and the sender before doing privileged work.
  Treat it as a request from an untrusted client, because it is one.

**Content navigates or opens a window**
→ Decide by allow-list, in the main process. An external target is
  validated before it reaches the shell.

**A permission is requested**
→ Deny by default and grant only what the feature needs. The handler
  is explicit; there is no safe implicit answer.

**An update is shipped**
→ Verify signature and integrity. Keep the staging path user-owned. An unsigned artefact or a writable staging directory is
  an update hijack.

## 5. Inputs
Window construction sites and their effective preferences, including
webview tags. The preload script's exposed surface. Message handlers
with their validation. Navigation and permission handlers. Update
configuration and signing.

## 6. Outputs
ACP Response Block only. Facts labeled. A preference claim is `known`
only against the effective values of the window that loads the
content. A bridge claim cites the exposed surface, not the intent.

## 7. Quality Gates
- Every window's departure from the secure defaults is documented.
- Every exposed bridge function is one operation on a fixed channel.
- Every privileged message validates its arguments and its sender.

## 8. Failure Modes
- A scripting flaw becoming code execution because isolation was off.
- A renderer reaching any channel through a generic exposed sender.
- A preload leaking a privileged interface into untrusted content.
- An update replaced from a writable staging directory.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/electron/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | node integration enabled on a renderer | sandbox disabled with it |
| 2 | context isolation disabled | preload tamperable, sandbox off |
| 3 | a generic sender exposed on the bridge | every channel reachable |
| 4 | a message handler with no argument check | untrusted input privileged |
| 5 | a handler that does not check its sender | any frame can ask |
| 6 | navigation or window opening unrestricted | arbitrary target loaded |
| 7 | web security disabled | same-origin policy removed |
| 8 | an update with no signature check | hijack path |

## 9. Worked Example
Claim: "the renderer is safe, we use the context bridge." Evidence: the
preload exposes an object carrying a general invoke function. Path
fires: a generic sender exposed on the bridge. Verdict: refuted
(Known: preload lines, file#L). The renderer can reach every channel,
and the bridge only changed how it asks. Fix: expose one function per
operation with a fixed channel, then validate arguments and sender in
the main process.
