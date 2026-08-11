#!/usr/bin/env bash
# SkillFloorHook (SubagentStop) — CB-097, hard enforcement.
#
# The floor computed by scripts/select-agents is written to the run
# ledger as skills-required.yaml. A specialist that finishes without
# loading its floor has reasoned about a stack from general knowledge:
# false-competence trap #11, at the one moment it is cheapest to catch.
#
# SubagentStop blocks on exit 2 — the subagent does not stop, it reads
# stderr and continues. That is the whole mechanism.
#
# Loop safety, in run-guard.sh's shape and for the same reason:
#   1. stop_hook_active in stdin -> always allow the stop.
#   2. Nudge state is keyed to run dir + agent; a stale file from an
#      older run never insta-disarms a fresh one.
#   3. Hard cap MAX_NUDGES per agent per run, then allow the stop —
#      a specialist that will not load its skills is a question for the
#      user, not a loop.
#   4. Fail open on every error path: no project root, no interpreter,
#      no required file, unparseable input -> exit 0.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
# shellcheck source=../lib/hostio.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/hostio.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

RUN="$(ls -1dt "$CB_DIR"/context/*/ 2>/dev/null | head -1)"
[ -n "$RUN" ] || exit 0
[ -f "$RUN/skills-required.yaml" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

REASON="$(printf '%s' "$INPUT" | CB_RUN="$RUN" CB_MAX="${CB_SKILL_NUDGES:-2}" $PYBIN -c '
import json, os, pathlib, re, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)
run = pathlib.Path(os.environ["CB_RUN"])

req = {}
for line in (run / "skills-required.yaml").read_text(encoding="utf-8").splitlines():
    m = re.match(r"^\s{2}([\w-]+):\s*\[(.*)\]\s*$", line)
    if m:
        req[m.group(1)] = [s.strip() for s in m.group(2).split(",") if s.strip()]
need = req.get(agent) or []
if not need:
    sys.exit(0)

loaded = set()
log = run / "skills-loaded.log"
if log.exists():
    for line in log.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) == 3 and parts[1] == agent:
            loaded.add(parts[2])
missing = [s for s in need if s not in loaded]
if not missing:
    sys.exit(0)

state = run / ("skill-floor.%s.state" % agent)
count = 0
if state.exists():
    try:
        count = int(state.read_text(encoding="utf-8").strip() or 0)
    except ValueError:
        count = 0
if count >= int(os.environ["CB_MAX"]):
    sys.exit(0)
state.write_text(str(count + 1), encoding="utf-8")
print("%s finished without loading its required skills: %s. Load each one "
      "with the Skill tool, redo the affected reasoning against it, and "
      "state in your Response Block which skills you loaded "
      "(skills_loaded). Selection floor: policies/skill-selection.yaml; "
      "an uninformed claim about this stack is trap #11."
      % (agent, ", ".join(missing)))
' 2>/dev/null || true)"

if [ -n "$REASON" ]; then
  cb_block "$REASON"
fi
exit 0
