# Manual Test Scenario — /cb-docs

Reproducible by a third party using only this document. ~15 minutes.

## Setup

1. Install the plugin. Scratch repo with docs that will drift:
```bash
mkdir -p /tmp/cb-docs-test/src/handlers && cd /tmp/cb-docs-test && git init -b main
printf 'def handle():\n    return "ok"\n' > src/handlers/ping.py
printf '# Service\n\nHandlers live in `src/handlers/`.\nThe ping handler (`src/handlers/ping.py`) returns "ok" and is unauthenticated by design.\n' > README.md
git add -A && git commit -m "baseline"
git checkout -b chore/rename
git mv src/handlers src/endpoints && git commit -m "chore: rename handlers to endpoints"
```
**Planted drift:** README references `src/handlers/` twice; one
reference is mechanical (path), one sentence encodes behavior
("unauthenticated by design").

## Execution

2. Run: `/cb-docs chore/rename vs main`

## Expected results

- [ ] Both stale references found, each as a doc-line ↔ code-change
      evidence pair.
- [ ] The PATH references are fixed directly (mechanical drift),
      listed one entry per fix.
- [ ] The behavioral sentence is NOT silently rewritten — if any
      rewording is proposed there, it is surfaced as a QUESTION with
      proposed text.
- [ ] Unchanged-behavior docs are left untouched (surgical scope).
- [ ] Output in DECISION → EVIDENCE → REASONING → RISK → CONFIDENCE
      with the pending-question count in DECISION.

## Fail conditions

A stale path missed; the behavioral sentence silently rewritten;
fixes applied without doc↔code evidence pairs.
