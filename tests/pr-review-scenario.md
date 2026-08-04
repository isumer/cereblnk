# Manual Test Scenario — PRReviewWorkflow (/cb-pr-review)

Reproducible by a third party using only this document.
Expected duration: ~15 minutes.

## Setup

1. Install the plugin: `/plugin marketplace add isumer/cereblnk` then
   `/plugin install cereblnk@cereblnk-marketplace` (or add a local clone).
2. Create a scratch repo with the input fixture:

```bash
mkdir -p /tmp/cb-pr-test/src && cd /tmp/cb-pr-test && git init -b main
cat > src/auth_filter.py << 'PYEOF'
import time

SKEW_TOLERANCE_S = 30

def validate(token, is_refresh=False):
    if not token.get("sig_ok"):
        return False
    if is_refresh:
        # refresh tokens are trusted downstream
        return True
    return token["exp"] + SKEW_TOLERANCE_S > time.time()
PYEOF
git add -A && git commit -m "baseline"
git checkout -b feature/refresh-fast-path
sed -i 's/# refresh tokens are trusted downstream/# PERF: skip expiry work on hot refresh path/' src/auth_filter.py
git commit -am "perf: fast refresh path"
```

**Planted vulnerability:** the refresh branch returns `True` without any
expiry check — expired tokens are accepted on the refresh path.

## Execution

3. In the scratch repo, run:
   `/cb-pr-review diff main..feature/refresh-fast-path`

## Expected results (all must hold)

- [ ] Risk is scored **high** (auth surface → always-level-3 list),
      therefore gate level 3: Verifier AND Challenger both run.
- [ ] The expiry-bypass finding surfaces in EVIDENCE with a file/line
      reference to `src/auth_filter.py` (the `is_refresh` branch).
- [ ] Output arrives in fixed order:
      DECISION → EVIDENCE → REASONING → RISK → CONFIDENCE.
- [ ] DECISION is do-not-merge (or merge-after-fix), stated in the
      first paragraph.
- [ ] Epistemic labels are visible in the output (at minimum: the
      bypass as Known/Derived; any gateway/downstream mitigation as
      Assumed in RISK).
- [ ] RISK contains at least one falsifier (e.g., evidence of
      downstream expiry re-validation).

## Fail conditions

The run fails review if: the finding is missing; the finding appears
without an evidence reference; the Challenger did not run at level 3;
or DECISION does not lead the output.
