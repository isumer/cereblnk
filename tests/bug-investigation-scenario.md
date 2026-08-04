# Manual Test Scenario — BugInvestigationWorkflow (/cb-bug)

Reproducible by a third party using only this document.
Expected duration: ~15 minutes.

## Setup

1. Install the plugin (see pr-review-scenario.md step 1).
2. Create a scratch repo with a reproducible bug:

```bash
mkdir -p /tmp/cb-bug-test && cd /tmp/cb-bug-test && git init -b main
cat > cart.py << 'PYEOF'
def apply_discount(total_cents, percent):
    # BUG: integer division truncates before scaling
    return total_cents - (total_cents // 100 * percent)

def checkout(items, discount_percent=0):
    total = sum(i["price_cents"] * i["qty"] for i in items)
    return apply_discount(total, discount_percent)
PYEOF
cat > test_cart.py << 'PYEOF'
from cart import checkout

def test_ten_percent_discount():
    items = [{"price_cents": 999, "qty": 1}]
    # 10% of 999 = 99.9 -> expected 899 (banker-free floor of 899.1)
    assert checkout(items, 10) == 899
PYEOF
git add -A && git commit -m "cart with discount bug"
python3 -m pytest test_cart.py -q || true   # confirm the failure exists
```

**Root cause (ground truth):** `total_cents // 100 * percent` floors the
per-percent unit first (999//100 = 9), so the discount is computed on
900, not 999 — result 909, expected 899.

## Execution

3. Run: `/cb-bug test_cart.py::test_ten_percent_discount fails — discount amount is wrong`

## Expected results (all must hold)

- [ ] The workflow reproduces the failure FIRST (runs the failing test)
      before proposing anything.
- [ ] A **root-cause statement precedes any fix proposal** in the
      output (the iron rule), with an evidence reference to the
      truncation expression in `cart.py`.
- [ ] Hypotheses are traced one at a time; each traced hypothesis ends
      in a labeled verdict (confirmed/refuted/inconclusive).
- [ ] The fix is minimal (the discount expression only — no refactors
      of `checkout`, no new abstractions).
- [ ] The failing test passes after the fix, and a regression test (or
      the strengthened existing test) is named.
- [ ] Output arrives in fixed order:
      DECISION → EVIDENCE → REASONING → RISK → CONFIDENCE.

## 3-strike rule spot check (optional, +10 min)

Ask the workflow to continue "fixing" while rejecting its first three
proposed fixes. Expected: after the 3rd rejection it STOPS proposing
patches and raises an architectural question instead of a 4th attempt.

## Fail conditions

The run fails review if: any fix is proposed before a demonstrated root
cause; the root cause lacks an evidence reference; or scope exceeds the
minimal fix.
