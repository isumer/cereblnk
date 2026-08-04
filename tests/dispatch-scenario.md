# Manual Test Scenario — Cereblnk Dispatch Skill

Reproducible by a third party using only this document. ~15 minutes.
Verifies that plain-language engineering requests route to the right
workflow WITHOUT a /cb- command, and that non-engineering requests do
NOT trigger dispatch.

## Setup

1. Install the plugin (see pr-review-scenario.md step 1).
2. Reuse the `/tmp/cb-pr-test` fixture (pr-review-scenario.md step 2)
   with its `feature/refresh-fast-path` branch, and open a Claude Code
   session in that repo.

## Execution and expected results

**Probe A — review intent, plain language:**
Say: "feature/refresh-fast-path branch'ine bir bak, merge edilebilir mi?"
- [ ] Dispatch announces the route in one line (PR review, risk high →
      level 3) and runs the /cb-pr-review flow.
- [ ] The expiry-bypass finding surfaces exactly as in
      pr-review-scenario.md's expectations.

**Probe B — hidden risk under casual phrasing:**
Say: "küçük bir şey: token expiry kontrolünü hızlıca güncelleyiver"
- [ ] Risk is scored HIGH (auth surface) despite "küçük/hızlıca";
      no fast path — the response states the escalation.

**Probe C — vague feature intent:**
Say: "kullanıcılar notlarını paylaşabilsin istiyorum"
- [ ] Routes to /cb-frame (not straight to code); premises are
      presented for confirmation.

**Probe D — non-trigger (knowledge question):**
Say: "JWT nedir, kısaca anlatır mısın?"
- [ ] NO workflow runs, no routing announcement — a direct answer.

**Probe E — non-trigger (explicit command wins):**
Say: "/cb-qa main"
- [ ] The command's own definition runs; dispatch adds nothing.

**Probe F — ambiguity handled loudly:**
Say: "şu login modülüyle ilgilenir misin"
- [ ] Dispatch does NOT silently pick; it offers the plausible
      readings (review it? bug? redesign?) as one short question.

## Fail conditions

Any probe A–C running without a route announcement; probe D or E
triggering dispatch; probe F silently picking an interpretation;
probe B taking the fast path.
