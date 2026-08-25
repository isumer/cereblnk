#!/usr/bin/env bash
# SkillLedgerHook (PreToolUse: Skill) — CB-097, observation only.
#
# Records which subagent loaded which skill, into the run ledger. This
# is the evidence SkillFloorHook checks at SubagentStop and VerifierAgent
# checks at gate review; without it, "the agent loaded its skills" is an
# unverifiable claim about a context window nobody can inspect.
#
# Never blocks. A recording hook that can fail a tool call would trade a
# budget optimization for a broken session.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
printf '%s' "$INPUT" | CB_RUN="$RUN" $PYBIN -c '
import json, os, pathlib, sys, time
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
agent = d.get("agent_type") or d.get("agent_id") or "main"
ti = d.get("tool_input") or {}
name = ""
for k in ("skill", "name", "skill_name", "command"):
    v = ti.get(k)
    if isinstance(v, str) and v.strip():
        name = v.strip()
        break
if not name:
    sys.exit(0)
name = name.lstrip("/").split(":")[-1].split()[0]
p = pathlib.Path(os.environ["CB_RUN"]) / "skills-loaded.log"
try:
    with p.open("a", encoding="utf-8") as fh:
        fh.write("%d\t%s\t%s\n" % (int(time.time()), agent, name))
except OSError:
    pass
' 2>/dev/null || true
exit 0
