#!/usr/bin/env bash
# ContextMonitorHook (UserPromptSubmit) — CB-102, measurement.
#
# scripts/context-budget prints `source: assumed` next to the window and
# the output reserve, and every figure below them inherits that word.
# The whole budget architecture — wave size, digest cap, checkpoint —
# rests on a guess about how much room there is.
#
# The real number is on disk. Claude Code writes each assistant turn to
# the session transcript with a `usage` object, and the input side of
# that object IS the occupancy of the window for that turn. Reading it
# turns `assumed` into `known` at the bottom of the chain.
#
# Two outputs, deliberately different in cost:
#   - Every turn: one line appended to telemetry. Disk is free; this is
#     the sample that lets context claims become numbers instead of
#     adjectives.
#   - Only past the checkpoint: one short line injected as context. A
#     monitor that narrates every turn spends the budget it is watching,
#     which would be a joke at its own expense.
#
# Never blocks. UserPromptSubmit CAN block a prompt; this must not.
# A measurement that can stop work is no longer a measurement.
#
# Fail-open on every path — no transcript, no interpreter, no usage
# field, unparseable input. The known upstream case where
# transcript_path arrives empty therefore yields silence, not a stall.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${PYBIN:-}" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"

OUT="$(printf '%s' "$INPUT" | CB_DIR="${CB_DIR:-}" \
  CB_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" $PYBIN -c '
import json, os, pathlib, re, subprocess, sys, time

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tp = d.get("transcript_path") or ""
if tp.startswith("~/"):
    tp = os.path.expanduser(tp)
if not tp or not pathlib.Path(tp).is_file():
    sys.exit(0)

# Transcripts grow without bound; read the tail, not the file. The most
# recent assistant turn is what describes the window right now.
try:
    size = os.path.getsize(tp)
    with open(tp, "rb") as fh:
        if size > 262144:
            fh.seek(size - 262144)
            fh.readline()          # discard the partial line
        tail = fh.read().decode("utf-8", errors="replace")
except Exception:
    sys.exit(0)

usage = None
last_usage_idx = -1
compact_post = None
compact_idx = -1
for idx, raw in enumerate(tail.splitlines()):
    raw = raw.strip()
    if not raw:
        continue
    try:
        rec = json.loads(raw)
    except Exception:
        continue
    msg = rec.get("message") or {}
    u = msg.get("usage")
    if isinstance(u, dict) and msg.get("role") == "assistant":
        usage = u
        last_usage_idx = idx
    # F-45: UserPromptSubmit fires before the next assistant turn is
    # written, so right after /compact the newest `usage` record still
    # describes the pre-compaction turn — measured in
    # telemetry/context.log: 706493 tokens (78.2%) reported at 15:58:43,
    # one prompt after a compaction whose own record already carried
    # postTokens: 31272. The true occupancy (22x smaller) was sitting in
    # the same tail read, unused. A compaction record has no `usage` of
    # its own, so track it separately and prefer it over a stale usage
    # record when it comes later in the transcript.
    cm = rec.get("compactMetadata")
    if rec.get("isCompactSummary") and isinstance(cm, dict) and isinstance(cm.get("postTokens"), int):
        compact_post = cm["postTokens"]
        compact_idx = idx

compacted = compact_post is not None and compact_idx > last_usage_idx
if compacted:
    occupancy = compact_post
elif usage:
    def n(key):
        v = usage.get(key)
        return v if isinstance(v, int) else 0

    # Occupancy is everything the model was sent, cached or not. Counting
    # only input_tokens reads a cache-warm turn as nearly empty, which is
    # the opposite of true.
    occupancy = n("input_tokens") + n("cache_read_input_tokens") + n("cache_creation_input_tokens")
else:
    sys.exit(0)
if occupancy <= 0:
    sys.exit(0)

capacity = checkpoint = 0
# Initialised here, not only inside the try: since F-47 this is read on
# EVERY turn by the telemetry block, not just past the checkpoint, so a
# partial failure inside the try would now reach a NameError on the
# common path rather than the rare one.
capacity_assumed = False
try:
    out = subprocess.run(
        [sys.executable, str(pathlib.Path(os.environ["CB_PLUGIN_ROOT"]) / "scripts/context-budget")],
        capture_output=True, text=True, timeout=20).stdout
    mc = re.search(r"input_capacity:\s*(\d+)", out)
    mk = re.search(r"checkpoint_at:\s*(\d+)", out)
    capacity = int(mc.group(1)) if mc else 0
    checkpoint = int(mk.group(1)) if mk else 0
    # F-13: context-budget labels the window `source: assumed` when
    # nothing measured it, and this hook printed the derived percentage
    # with no hedge at all. Observed: a session warned at 101.8% and
    # 104.7% of a guessed denominator while the real window was several
    # times larger, and the conductor split work into subagents it did
    # not need to. A percentage above 100 is the tell that the
    # denominator was never real; the warning must carry the same label
    # its own source does.
    #
    # F-46: checking `window:.*source: assumed` alone missed the other
    # half of the denominator. input_capacity = window - output_reserve,
    # and context-budget resolves each independently — a settings.json
    # with only CLAUDE_CODE_AUTO_COMPACT_WINDOW set measures the window
    # but leaves the reserve on FALLBACK_RESERVE (32000, `source:
    # assumed`), which the old regex never looked at. context-budget
    # already emits one aggregate line for exactly this — `labelled:
    # assumed — set ... to measure instead of guessing` — printed iff
    # either figure is unmeasured. Match that line instead of re-deriving
    # its logic here.
    capacity_assumed = bool(re.search(r"^\s*labelled:\s*assumed", out, re.MULTILINE))
except Exception:
    pass
if not capacity:
    sys.exit(0)

pct = round(100.0 * occupancy / capacity, 1)

# Sample every turn. This is the file that makes a context claim a
# number; without it the monitor only ever warns and measures nothing.
#
# F-47: this line used to record occupancy/capacity/pct and nothing
# about how either was obtained. F-45 (occupancy read 706493 instead of
# the true 31272, right after a compaction) was invisible in this log —
# diagnosing it took hand-reading compactMetadata out of the raw
# transcript, because the log gave no way to tell a post-compaction
# reading from an ordinary one. Append `compacted` and `capacity_source`
# so both F-45 and F-46 leave a trace a grep can find; fields are added
# at the end so `occupancy=`/`capacity=`/`pct=` still parse unchanged
# for any reader that only looked at those three.
cb = os.environ.get("CB_DIR") or ""
if cb:
    try:
        tel = pathlib.Path(cb) / "telemetry"
        tel.mkdir(parents=True, exist_ok=True)
        line = "%s session=%s occupancy=%d capacity=%d pct=%s compacted=%s capacity_source=%s\n" % (
            time.strftime("%Y-%m-%dT%H:%M:%S"), d.get("session_id") or "-",
            occupancy, capacity, pct,
            "yes" if compacted else "no",
            "assumed" if capacity_assumed else "measured")
        with open(tel / "context.log", "a", encoding="utf-8") as fh:
            fh.write(line)
    except Exception:
        pass

if not checkpoint or occupancy < checkpoint:
    sys.exit(0)

if capacity_assumed:
    # The condition broadened in F-46 and this sentence had to broaden
    # with it. It used to say "the window was never measured", which is
    # now wrong in the case F-46 added: settings can name the window
    # while the reserve falls back, and capacity is the difference of the
    # two. Naming the wrong half sends the reader to set a variable that
    # is already set.
    note = ("Context monitor: %d input tokens used — about %s%% of an ASSUMED "
            "capacity of %d, past the %d checkpoint. Capacity is the window "
            "minus the output reserve and at least one of those was never "
            "measured, so treat the percentage as a guess and do not reshape "
            "the work around it; run scripts/context-budget to see which half "
            "is missing, then set CLAUDE_CODE_AUTO_COMPACT_WINDOW or "
            "CLAUDE_CODE_MAX_OUTPUT_TOKENS. Prefer digests over re-reading "
            "files." % (
                occupancy, pct, capacity, checkpoint))
else:
    note = ("Context monitor: %d of %d input tokens used (%s%% of capacity), past the "
            "%d checkpoint. Prefer digests over re-reading files, and finish or "
            "checkpoint the current task before starting new work." % (
                occupancy, capacity, pct, checkpoint))
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit", "additionalContext": note}}))
' 2>/dev/null || true)"

[ -n "$OUT" ] || exit 0
printf '%s\n' "$OUT"
exit 0
