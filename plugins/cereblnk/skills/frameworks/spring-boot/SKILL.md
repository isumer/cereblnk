---
name: spring-boot
description: Spring's magic as concrete mechanisms — auto-config, proxies, transactions, property binding. Use for Spring Boot work. Recipes in PATTERNS.md;. Constraints in rules/frameworks/spring-boot/.
---

# Spring Boot Skill

## 1. Identity
name: spring-boot · domain: frameworks
requires: java
complements: spring-security · hibernate-jpa · junit-testing
escalate_to: security-agent (auth config) · database-agent (transaction/schema)

## 2. Mission
Read the emitted config and the proxy boundary. The annotation is a
promise; the running context is the truth.

## 3. Philosophy

**Reading requests.** "It works locally" hides two things. Which
auto-config applied. Which proxy wrapped the bean. "Add caching" hides
one question. Does the proxy see this call? Self-invocation bypasses it.

**Where risk lives.** Transactions on the wrong method. Checked
exceptions not rolling back. Dual writes diverging. Self-invocation
past the proxy. Config missing at boot.

**Verification here.** Read the emitted config, not the intent. Read
the proxy boundary. Check where @Transactional sits. Check if the call
crosses the proxy. Boot failure is proof. Runtime surprise is not.

**False-competence traps.** @Transactional on a private method.
Entities bound as request DTOs. Auto-config trusted unread. Rollback
assumed on a checked exception.

**Instincts.** Explicit config beats clever auto-config. Move
proxy-dependent behavior into its own bean. Fail fast at boot.

## 4. Decision Strategy — the paths

**A transaction is added or reviewed**
→ @Transactional on the service method only. Never a controller,
  repository, or private method. The proxy cannot see those.
→ Query paths carry readOnly = true.
→ An HTTP call or queue publish inside it is a finding. The lock is
  held hostage to a network call.

**A checked exception can throw in a transaction**
→ Set rollbackFor explicitly. The default skips checked exceptions.
  Silent partial commit otherwise.

**The DB is written, then a message published**
→ Transactional outbox, never a dual write. Two sequenced systems
  diverge on the failure between them.

**A charge or submit path can be retried**
→ Natural key, idempotency table, or upsert. Its absence on a
  retryable write is a known defect.

**A bean calls its own @Transactional/@Cacheable method**
→ Self-invocation skips the proxy. Move the method to another bean.

**Config is read**
→ Bind typed @ConfigurationProperties. Fail fast at boot when
  required values are missing.

## 5. Inputs
Service and config source. The proxy boundary for the path. Emitted
auto-config report. Transaction annotations. Property binding.

## 6. Outputs
ACP Response Block only. Transaction claims `known` against the
annotation site and proxy crossing. Config claims `known` from the
emitted report. Behavior across the proxy `derived` from the call path.

## 7. Quality Gates
- Every @Transactional sits where the proxy sees it.
- Every checked-exception path in a transaction sets rollbackFor.
- Every dual-write is an outbox, or a stated finding.

## 8. Failure Modes
- @Transactional silently inert on a self-invoked method.
- Checked exception committing half the work.
- Cache missed because self-invocation skipped the proxy.
- Missing config surfacing in production, not at boot.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/spring-boot/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | @Transactional on a controller/private method | inert proxy |
| 2 | HTTP/queue call inside a @Transactional method | lock held |
| 3 | checked exception path without rollbackFor | partial commit |
| 4 | DB write then separate publish, no outbox | dual-write drift |
| 5 | self-call to a @Transactional/@Cacheable method | skipped proxy |
| 6 | retryable write with no idempotency key | double effect |

## 9. Worked Example
Claim: "caching works, the method is @Cacheable." Evidence: the bean
calls its own cached method internally. Path fires: self-invocation
skips the proxy, the cache is never consulted. Verdict: refuted
(Known: call site, file#L). Fix: move the method to a separate bean;
a test asserts one underlying call on the second invocation.
