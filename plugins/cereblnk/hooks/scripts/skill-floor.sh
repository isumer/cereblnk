#!/usr/bin/env bash
# SkillFloorHook (SubagentStop) — CB-097. Exit 2 enforces the recorded skill floor.
# Re-entry is bounded per run/agent; recursion and errors fail open.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
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
# F-10/F-32: harness identities may be qualified names, labels, or opaque IDs;
# match the last segment, but never claim the floor ran for an opaque ID.
agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)
agent_key = agent.rsplit(":", 1)[-1]
run = pathlib.Path(os.environ["CB_RUN"])

req = {}
for line in (run / "skills-required.yaml").read_text(encoding="utf-8").splitlines():
    # The old `[\w-]+` rejected qualified keys and silently emptied the map.
    m = re.match(r"^\s{2}([\w:-]+):\s*\[(.*)\]\s*$", line)
    if m:
        req[m.group(1).rsplit(":", 1)[-1]] = [
            s.strip() for s in m.group(2).split(",") if s.strip()]
need = req.get(agent_key) or []
if not need and req and agent_key not in req:
    # The wrapper discards inner stderr, so WARN travels via stdout; an
    # unidentifiable agent cannot be blocked, but the missed check stays visible.
    print("WARN:cereblnk skill-floor: cannot match subagent %r against "
          "the baseline (%s). The skill floor did NOT run for this "
          "subagent." % (agent, ", ".join(sorted(req))))
if not need:
    sys.exit(0)

# Judge only ledger lines since the previous stop for this agent.
log = run / "skills-loaded.log"
lines = log.read_text(encoding="utf-8").splitlines() if log.exists() else []
mark_f = run / ("skill-floor.%s.mark" % agent)
start = 0
if mark_f.exists():
    try:
        start = int(mark_f.read_text(encoding="utf-8").strip() or 0)
    except ValueError:
        start = 0
if start > len(lines):        # log rotated or truncated: judge all of it
    start = 0

loaded = set()
for line in lines[start:]:
    parts = line.split("\t")
    if len(parts) == 3 and parts[1] == agent:
        loaded.add(parts[2])
missing = [s for s in need if s not in loaded]

state = run / ("skill-floor.%s.state" % agent)
if not missing:
    try:
        mark_f.write_text(str(len(lines)), encoding="utf-8")
        state.unlink()
    except OSError:
        pass
    sys.exit(0)

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
