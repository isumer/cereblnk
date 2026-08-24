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
# Identity, matched on the last segment (F-10, F-32).
#
# The baseline is written with policy role names; SubagentStop hands
# back whatever the harness has. Measured in a real session: a bare hex
# id (`a9ca0309334d10b0e`, via the agent_id fallback because agent_type
# was absent) and the harness label `general-purpose`. Neither is a
# policy role, so the lookup returned nothing and the floor exited
# 0 — silently, for every real subagent, while a synthetic payload
# carrying `backend-agent` engaged correctly.
#
# The baseline now carries qualified names too
# (`cereblnk:engineering:backend-agent`), so matching happens on the
# last colon-segment from both directions.
agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)
agent_key = agent.rsplit(":", 1)[-1]
run = pathlib.Path(os.environ["CB_RUN"])

req = {}
for line in (run / "skills-required.yaml").read_text(encoding="utf-8").splitlines():
    # `[\w-]+` did not admit the colon, so a qualified key parsed as
    # nothing at all and the whole map came back empty.
    m = re.match(r"^\s{2}([\w:-]+):\s*\[(.*)\]\s*$", line)
    if m:
        req[m.group(1).rsplit(":", 1)[-1]] = [
            s.strip() for s in m.group(2).split(",") if s.strip()]
need = req.get(agent_key) or []
if not need and req and agent_key not in req:
    # Neither identity nor baseline is at fault when the harness hands
    # back an opaque id: the floor simply cannot tell who finished. It
    # still must not pretend it checked.
    # WARN: goes to stdout because the wrapper discards this block
    # stderr; the wrapper routes the prefix to stderr and exits 0. It
    # must not block — a floor that cannot identify the subagent has no
    # grounds to fail it, only grounds to say it did not check.
    print("WARN:cereblnk skill-floor: cannot match subagent %r against "
          "the baseline (%s). The skill floor did NOT run for this "
          "subagent." % (agent, ", ".join(sorted(req))))
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

case "$REASON" in
  WARN:*)
    echo "${REASON#WARN:}" >&2
    exit 0 ;;          # visible, not blocking: it could not check
  ?*)
    echo "$REASON" >&2
    exit 2 ;;
esac
exit 0
