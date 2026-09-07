#!/usr/bin/env bash
# RunGuardHook: ledger growth resets stagnation; MAX_NUDGES stagnant Stops disarm.
# Hosts cannot report live agents, so preserve three cases; pinned state/errors fail open.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0

FLAG="$CB_DIR/flags/run-active"
STATE="$CB_DIR/flags/run-active.state"
MAX_NUDGES=3
[ -f "$FLAG" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

NEWEST="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$NEWEST" ] || exit 0
PROGRESS="$NEWEST/run-guard.last-progress"

# Verification is progress; RESPONSE_BLOCKS stays separate so the task message remains literal.
BLOCKS=$(grep -El '^[[:space:]]*kind:[[:space:]]*(response|verification)([[:space:]]*(#.*)?)?$' \
  "$NEWEST"*.yaml 2>/dev/null | wc -l | tr -cd '0-9'); BLOCKS=${BLOCKS:-0}
RESPONSE_BLOCKS=$(grep -El '^[[:space:]]*kind:[[:space:]]*response([[:space:]]*(#.*)?)?$' \
  "$NEWEST"*.yaml 2>/dev/null | wc -l | tr -cd '0-9'); RESPONSE_BLOCKS=${RESPONSE_BLOCKS:-0}
MANDATED_NOTE=""
if [ -n "${PYBIN:-}" ] && [ -f "$NEWEST/agents-required.yaml" ]; then
  # CB-177: plan-less /cb-do bypasses plan-lint; report mandated agents
  # missing Response or Verification Blocks, but keep reconciliation fail-open.
  MISSING=$(CB_RUN="$NEWEST" $PYBIN -c '
import os, pathlib, re

run = pathlib.Path(os.environ["CB_RUN"])

def top(text, key):
    m = re.search(r"^\s*%s\s*:\s*(.*)$" % re.escape(key), text, re.M)
    return m.group(1).split("#", 1)[0].strip() if m else ""

def norm(value):
    return re.sub(r"[^a-z0-9]", "", value.rsplit(":", 1)[-1].lower())

required = []
for line in (run / "agents-required.yaml").read_text(
        encoding="utf-8", errors="replace").splitlines():
    m = re.match(r"^\s*-\s*agent\s*:\s*([^\s#]+)", line)
    if m:
        name = m.group(1).rsplit(":", 1)[-1]
        if norm(name) not in [key for key, _name in required]:
            required.append((norm(name), name))

responded = set()
for path in run.glob("*.yaml"):
    body = path.read_text(encoding="utf-8", errors="replace")
    if top(body, "kind") in ("response", "verification") and top(body, "role"):
        responded.add(norm(top(body, "role")))

print(", ".join(name for key, name in required if key not in responded))
' 2>/dev/null || true)
  [ -z "$MISSING" ] || MANDATED_NOTE="; mandated agents with no response or verification block: $MISSING"
fi
if [ -f "$NEWEST/plan.md" ]; then
  TASKS=$(grep -Ec '^[[:space:]]*-[[:space:]]+\[[ xX]\]([[:space:]]|$)' \
    "$NEWEST/plan.md" 2>/dev/null | tr -cd '0-9'); TASKS=${TASKS:-0}
  PENDING=" ($RESPONSE_BLOCKS/$TASKS plan tasks have a response block in ${NEWEST#$CB_DIR/}$MANDATED_NOTE)"
else
  PENDING=" ($RESPONSE_BLOCKS response blocks in ${NEWEST#$CB_DIR/}$MANDATED_NOTE)"
fi

COUNT=0; LAST=$BLOCKS; RUNKEY="${NEWEST:-none}"
if [ -f "$STATE" ]; then
  # State is <stagnant_stop_count> <runkey>.
  read -r COUNT SAVEDKEY < "$STATE" 2>/dev/null || { COUNT=0; SAVEDKEY=""; }
  [ "$SAVEDKEY" = "$RUNKEY" ] || { COUNT=0; LAST=$BLOCKS; }   # different run: reset
  if [ "$SAVEDKEY" = "$RUNKEY" ] && [ -f "$PROGRESS" ]; then
    read -r LAST < "$PROGRESS" 2>/dev/null || LAST=-1
  fi
fi

if [ "$BLOCKS" -le "$LAST" ]; then
  if [ "$COUNT" -ge "$MAX_NUDGES" ]; then
    mv -f "$FLAG" "$FLAG.nudged" 2>/dev/null || rm -f "$FLAG" 2>/dev/null
    rm -f "$STATE" "$PROGRESS" 2>/dev/null
    exit 0
  fi
  COUNT=$((COUNT+1))
fi

printf '%s %s\n' "$COUNT" "$RUNKEY" > "$STATE" 2>/dev/null || true
printf '%s\n' "$BLOCKS" > "$PROGRESS" 2>/dev/null || true
printf '{"decision":"block","reason":"A Cereblnk run is still active%s — continue nudge %s/%s. Three cases, and they are not the same. SPECIALISTS STILL OUT: this nudge is informational — do NOT disarm, the flag is what judges them when they return, and waiting is the normal state of a multi-agent run. WAITING ON THE USER: disarm first (scripts/run-flag disarm), then ask. NEITHER: reconcile the run ledger (plan.md vs Response Blocks), execute the NEXT unconfirmed task, then gates and synthesis. Nudges continue only while the ledger grows."}\n' "$PENDING" "$COUNT" "$MAX_NUDGES"
exit 0
