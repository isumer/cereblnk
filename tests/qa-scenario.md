# Manual Test Scenario — /cb-qa

Reproducible by a third party using only this document. ~15 minutes.

## Setup

1. Install the plugin; reuse `/tmp/cb-bug-test` from
   bug-investigation-scenario.md (the cart repo), or recreate it.
2. Create a fix branch with the discount bug fixed:
```bash
cd /tmp/cb-bug-test && git checkout -b fix/discount
sed -i 's|total_cents - (total_cents // 100 \* percent)|total_cents - (total_cents * percent // 100)|' cart.py
git commit -am "fix: compute discount before flooring"
```

## Execution

3. Run: `/cb-qa fix/discount vs main`

## Expected results

- [ ] Affected surfaces derived from the DIFF (cart.py + its
      dependents/tests) — not a whole-repo test sweep narrative.
- [ ] The existing failing test is executed and now passes (`known`
      fact with the run output).
- [ ] A regression test for the confirmed fix is generated and run —
      demonstrated failing on `main`'s code path or asserting the
      exact truncation case (999 @ 10% == 899).
- [ ] Trap-#8 analysis present: what the suite would still NOT fail on
      (e.g. percent > 100, negative totals) listed as gaps/unknowns.
- [ ] No browser/live-device tooling invoked or assumed (F-class).
- [ ] Output in DECISION → EVIDENCE → REASONING → RISK → CONFIDENCE.

## Fail conditions

Regression test missing or never executed; surfaces chosen without
diff evidence; any F-class tool assumed.
