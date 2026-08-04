# Manual Test Scenario — Fast Path (Verification Level 1)

Closes Phase 1 exit criterion 5's level-1 gap.
Expected duration: ~5 minutes.

## Setup

1. Install the plugin (see pr-review-scenario.md step 1).
2. Use any small repo (the /tmp/cb-pr-test fixture works).

## Execution

3. Run a trivially low-risk request through the orchestrator:
   `/cb-orchestrate what does SKEW_TOLERANCE_S control in src/auth_filter.py?`

## Expected results (all must hold)

- [ ] The orchestrator routes to the **fast path**: no planner-agent,
      no specialist mesh, no gate agents are spawned (single-agent run).
- [ ] Only the relevant file is read — not the repository tree.
- [ ] The answer still uses the fixed ordering
      DECISION → EVIDENCE → REASONING → RISK → CONFIDENCE, with the
      config value cited as Known with a file/line reference.
- [ ] The response notes level-1 self-verification (the five-question
      self-test), not a Verifier/Challenger pass.

## Escalation spot check

4. Run: `/cb-orchestrate quickly bump the token expiry check, tiny change`
- [ ] Despite "quickly/tiny", the auth surface forces risk **high**
      (always-level-3 list) — the fast path is refused and the full
      pipeline (or at minimum an explicit escalation statement) engages.

## Fail conditions

Fast path spawns gate agents for the trivial question; or the
escalation spot check stays on the fast path.
