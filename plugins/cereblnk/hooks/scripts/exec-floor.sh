#!/usr/bin/env bash
# ExecFloorHook (SubagentStop) — CB-113, hard enforcement.
#
# Every other gate in a run is static: Verifier reads code, Challenger
# attacks reasoning, Consistency compares claims. None of them touches a
# running program. A specialist can write a module, never execute it, and
# close green — the claim "it works" is then unfalsifiable rather than
# verified.
#
# ExecLedgerHook records which surfaces an agent edited and which it ran.
# This hook asks the one question nothing else asks: did you run what you
# changed.
#
# A surface with no configured check command is recorded as skipped and
# allowed through. The gap becomes visible in the ledger instead of being
# silently absent — a floor that turns a project red for a command it was
# never given would be a worse failure than the one it prevents.
#
# SubagentStop blocks on exit 2 — the subagent does not stop, it reads
# stderr and continues. That is the whole mechanism.
#
# Loop safety, in skill-floor.sh's shape and for the same reason:
#   1. stop_hook_active in stdin -> always allow the stop.
#   2. Nudge state is keyed to run dir + agent; a stale file from an
#      older run never insta-disarms a fresh one.
#   3. Hard cap MAX_NUDGES per agent per run, then allow the stop.
#   4. Fail open on every error path.
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

# F-32: this was a set difference — surfaces edited, minus surfaces
# executed — and a set difference has no order in it. An agent that ran
# the check and THEN edited the file was recorded as covered, which is
# precisely the case this floor exists to catch: the state that shipped
# was never run. The ledger already carried what the test needs, in
# parts[0]. A surface is unrun when it has no exec at all, or when its
# last edit is later than its last exec.
#
# Position in the file breaks ties, because two events in the same
# second are ordered by the order they were appended, not by their
# equal timestamps. The per-agent filter below is untouched: it was
# verified correct.
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
