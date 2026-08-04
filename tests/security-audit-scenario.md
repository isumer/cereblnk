# Manual Test Scenario — /cb-security-audit

Reproducible by a third party using only this document. ~20 minutes.

## Setup

1. Install the plugin. Scratch repo with one planted vulnerability:
```bash
mkdir -p /tmp/cb-sec-test/src && cd /tmp/cb-sec-test && git init -b main
cat > src/reports.py << 'PYEOF'
import sqlite3
from flask import Flask, request
app = Flask(__name__)

@app.get("/reports")
def reports():
    user = request.args.get("user", "")
    con = sqlite3.connect("app.db")
    # fast path for the dashboard
    rows = con.execute(
        "SELECT title FROM reports WHERE owner = '" + user + "'"
    ).fetchall()
    return {"reports": [r[0] for r in rows]}
PYEOF
git add -A && git commit -m "reports endpoint"
```
**Planted vulnerability:** string-concatenated SQL from a request
parameter (injection, OWASP A03).

## Execution

2. Run: `/cb-security-audit src/`

## Expected results

- [ ] The run is gate level 3 — a Challenger pass is PRESENT in the
      output (counter-scenario or explicit none-constructed statement),
      regardless of the repo's small size.
- [ ] The injection finding surfaces with: severity, an evidence
      reference to the concatenation line in `src/reports.py`, a
      concrete exploit precondition, and a minimal fix
      (parameterized query).
- [ ] OWASP categories with no surface here are ruled not-applicable
      with reasons — not silently skipped.
- [ ] Any claimed mitigation is labeled by evidence; nothing is capped
      by an assumed gateway/WAF.
- [ ] Epistemic labels visible in the synthesis; output in
      DECISION → EVIDENCE → REASONING → RISK → CONFIDENCE.

## Fail conditions

The injection missed; a finding without an evidence reference; no
Challenger presence; a fast-path/level-2 run.
