#!/usr/bin/env bash
# ContextMonitorHook (UserPromptSubmit) — CB-102. Logs transcript usage every turn,
# injects context only past the checkpoint, and fails open silently.
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

# Transcripts are unbounded; only the latest assistant turn describes occupancy.
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
    # Compaction writes metadata and summary as separate records; requiring
    # both on one record previously matched nothing.
    cm = rec.get("compactMetadata")
    if isinstance(cm, dict) and isinstance(cm.get("postTokens"), int):
        compact_post = cm["postTokens"]
        compact_idx = idx

compacted = compact_post is not None and compact_idx > last_usage_idx
if compacted:
    occupancy = compact_post
elif usage:
    def n(key):
        v = usage.get(key)
        return v if isinstance(v, int) else 0

    # Cached tokens were sent too; omitting them makes cache-warm turns look empty.
    occupancy = n("input_tokens") + n("cache_read_input_tokens") + n("cache_creation_input_tokens")
else:
    sys.exit(0)
if occupancy <= 0:
    sys.exit(0)

capacity = checkpoint = 0
capacity_assumed = False
try:
    out = subprocess.run(
        [sys.executable, str(pathlib.Path(os.environ["CB_PLUGIN_ROOT"]) / "scripts/context-budget")],
        capture_output=True, text=True, timeout=20).stdout
    mc = re.search(r"input_capacity:\s*(\d+)", out)
    mk = re.search(r"checkpoint_at:\s*(\d+)", out)
    capacity = int(mc.group(1)) if mc else 0
    checkpoint = int(mk.group(1)) if mk else 0
    # F-13: guessed capacity once produced unqualified 101.8%/104.7% warnings
    # and unnecessary delegation; preserve the `assumed` label from context-budget.
    capacity_assumed = bool(re.search(r"^\s*labelled:\s*assumed", out, re.MULTILINE))
except Exception:
    pass
if not capacity:
    sys.exit(0)

pct = round(100.0 * occupancy / capacity, 1)

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
