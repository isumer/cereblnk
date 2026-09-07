#!/usr/bin/env bash
# ExecFloorHook (SubagentStop) — CB-113. Exit 2 requires checks after the last surface edit.
# Missing commands are logged as skipped; re-entry is bounded and errors fail open.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0
[ -f "$RUN/exec.log" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

REASON="$(printf '%s' "$INPUT" | CB_RUN="$RUN" CB_CFG="$CB_DIR/config" \
  CB_MAX="${CB_EXEC_NUDGES:-2}" $PYBIN -c '
import json, os, pathlib, sys, time

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)

run = pathlib.Path(os.environ["CB_RUN"])
cfg = pathlib.Path(os.environ["CB_CFG"])

# F-32: set difference treated edit-after-test as covered; compare event order.
# File position breaks same-second timestamp ties.
edited, executed = [], {}
last_edit = {}
for pos, line in enumerate(
        (run / "exec.log").read_text(encoding="utf-8").splitlines()):
    parts = line.split("\t")
    if len(parts) != 4 or parts[1] != agent:
        continue
    stamp, _, kind, surface = parts
    try:
        when = (int(stamp), pos)
    except ValueError:
        continue
    if kind == "edit":
        if surface not in edited:
            edited.append(surface)
        last_edit[surface] = when
    elif kind == "exec":
        executed[surface] = when

unrun = [s for s in edited
         if s not in executed or last_edit[s] > executed[s]]
if not unrun:
    sys.exit(0)

blocking, skipped = [], []
for s in unrun:
    f = cfg / ("check-command.%s" % s)
    cmd = ""
    if f.is_file():
        try:
            cmd = f.read_text(encoding="utf-8").splitlines()[0].strip()
        except (OSError, IndexError):
            cmd = ""
    (blocking if cmd else skipped).append((s, cmd))

if skipped:
    try:
        with (run / "exec.log").open("a", encoding="utf-8") as fh:
            for s, _ in skipped:
                fh.write("%d\t%s\tskip\t%s\n" % (int(time.time()), agent, s))
    except OSError:
        pass

if not blocking:
    sys.exit(0)

state = run / ("exec-floor.%s.state" % agent)
count = 0
if state.exists():
    try:
        count = int(state.read_text(encoding="utf-8").strip() or 0)
    except ValueError:
        count = 0
if count >= int(os.environ["CB_MAX"]):
    sys.exit(0)
state.write_text(str(count + 1), encoding="utf-8")

detail = "; ".join("%s -> %s" % (s, c) for s, c in blocking)
print("%s edited %s and finished without running it. Run the configured "
      "check for each surface, read the output, and fix what it reports "
      "before finishing: %s. If a check reports a failure your change did "
      "not cause and that sits outside this task, report it instead of "
      "fixing it — but only when you can say how you confirmed it "
      "predates your change: run the check again with your change "
      "reverted and show it fails the same way there. A claim that "
      "something is pre-existing without that comparison does not clear "
      "this floor. State the result in your Response Block. This floor "
      "sees that the command ran, never what it proved: it cannot tell a "
      "check that exercises your change from one that would have passed "
      "before it. So running it does not by itself earn a known label — "
      "say what the output rules out, and if the configured check does "
      "not reach your change, say that instead of labelling on it."
      % (agent, ", ".join(s for s, _ in blocking), detail))
' 2>/dev/null || true)"

if [ -n "$REASON" ]; then
  echo "$REASON" >&2
  exit 2
fi
exit 0
