# Manual Test Scenario — Chained /cb-frame → /cb-design → /cb-implement

Reproducible by a third party using only this document. ~35 minutes.

## Setup

1. Install the plugin (see pr-review-scenario.md step 1).
2. Scratch repo:
```bash
mkdir -p /tmp/cb-chain-test && cd /tmp/cb-chain-test && git init -b main
printf 'from flask import Flask\napp = Flask(__name__)\n\n@app.get("/notes")\ndef list_notes():\n    return []\n' > app.py
printf 'flask\n' > requirements.txt
git add -A && git commit -m "baseline notes app"
```

## Stage 1 — /cb-frame

3. Run: `/cb-frame users should be able to share notes with each other`

Expected:
- [ ] Three-level reading stated (literal / operational / constraint).
- [ ] Falsifiable premises presented for your confirmation (e.g. "notes
      currently have an owner", "sharing means read access") — answer
      them; reject at least one on purpose.
- [ ] 2–3 sized paths proposed (S/M/L) with exclusions; pick one.
- [ ] A brief file appears under `.claude/cereblnk/memory/briefs/` containing
      your confirmed/rejected/assumed premise rulings.

## Stage 2 — /cb-design

4. Run: `/cb-design <brief slug>`

Expected:
- [ ] Refuses to run if you point it at a nonexistent brief (spot
      check), routes you to /cb-frame.
- [ ] Spec written to `.claude/cereblnk/memory/specs/` containing ALL seven
      sections: architecture, data flow, state transitions, failure
      modes, trust boundaries, diagram(s), test matrix.
- [ ] At least one diagram (Mermaid or ASCII) present.
- [ ] security-agent involvement visible on the trust-boundary section.

## Stage 3 — /cb-implement (verification-blocking check)

5. Run: `/cb-implement <spec slug>`, then when the first slice is
   presented, deliberately reject/fail it (e.g. reply that the slice's
   test fails on your machine).

Expected:
- [ ] Planner slices the spec; slices carry acceptance criteria lifted
      from the test matrix.
- [ ] On the failed slice: the run does NOT proceed to slice 2 — the
      slice returns to its specialist with the verdict attached.
- [ ] After fixing, progression resumes; final output in
      DECISION → EVIDENCE → REASONING → RISK → CONFIDENCE order.

## Fail conditions

Missing spec sections; no diagram; slice 2 starting despite a failed
slice 1; a brief/spec never written to `.claude/cereblnk/memory/`.
