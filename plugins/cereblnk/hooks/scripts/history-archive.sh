#!/usr/bin/env bash
# HistoryArchiveHook (PreCompact) preserves the transcript before compaction.
# Archiving errors always fail open because PreCompact must not be delayed.
set -uo pipefail
# shellcheck source=../../scripts/lib/cbenv.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"
if [ -z "${CB_ROOT:-}" ]; then
  echo "cereblnk history-archive: no project root resolved; skipping (never writing to temp)." >&2
  exit 0
fi
# One release wrote outside CB_DIR to .claude/history, splitting data from config.
HIST_DIR="$CB_DIR/history"
# Move the legacy directory only when the destination is absent; failures leave it intact.
LEGACY="$CB_ROOT/.claude/history"
if [ -d "$LEGACY" ] && [ ! -d "$HIST_DIR" ]; then
  mkdir -p "$(dirname "$HIST_DIR")" 2>/dev/null &&
    mv "$LEGACY" "$HIST_DIR" 2>/dev/null &&
    echo "cereblnk history-archive: moved existing archives from $LEGACY to $HIST_DIR" >&2
fi

# Extract the PreCompact payload fields.
TRANSCRIPT=""; TRIGGER="unknown"; SESSION=""
if [ -n "${PYBIN:-}" ]; then
  eval "$(CEREBLNK_HOOK_INPUT="$INPUT" $PYBIN - << 'PY'
import json, os
try:
    d = json.loads(os.environ.get("CEREBLNK_HOOK_INPUT") or "{}")
except Exception:
    d = {}
def q(s): return str(s).replace("'", "")
print(f"TRANSCRIPT='{q(d.get('transcript_path') or '')}'")
print(f"TRIGGER='{q(d.get('trigger') or 'unknown')}'")
print(f"SESSION='{q((d.get('session_id') or '')[:8])}'")
PY
)" 2>/dev/null || true
else
  # Without Python, payload extraction is best-effort.
  TRANSCRIPT="$(printf '%s' "$INPUT" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  TRIGGER="$(printf '%s' "$INPUT" | sed -n 's/.*"trigger"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  SESSION="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  SESSION="${SESSION:0:8}"
  [ -n "$TRIGGER" ] || TRIGGER="unknown"
fi

# The host may send a home-relative transcript path.
case "$TRANSCRIPT" in "~/"*) TRANSCRIPT="$HOME/${TRANSCRIPT#\~/}";; esac

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  # Upstream issue anthropics/claude-code#13668 may leave transcript_path empty.
  echo "cereblnk history-archive: no transcript available to archive (path='$TRANSCRIPT'); compaction proceeds." >&2
  exit 0
fi

mkdir -p "$HIST_DIR" 2>/dev/null || exit 0
STAMP="$(date -u +%Y%m%d-%H%M%S 2>/dev/null || echo now)"
DEST="$HIST_DIR/${STAMP}-${TRIGGER}${SESSION:+-$SESSION}.jsonl"
cp -f "$TRANSCRIPT" "$DEST" 2>/dev/null || cat "$TRANSCRIPT" > "$DEST" 2>/dev/null || {
  echo "cereblnk history-archive: copy failed; compaction proceeds." >&2
  exit 0
}
echo "cereblnk history-archive: transcript archived to $DEST" >&2

# Keep the newest configured number of archives.
KEEP=20
CFG="$CB_DIR/config/history-keep"
[ -f "$CFG" ] && KEEP="$(head -1 "$CFG" | tr -cd '0-9')" && [ -n "$KEEP" ] || KEEP=20
ls -1t "$HIST_DIR"/*.jsonl 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
  rm -f "$old" 2>/dev/null || true
done
exit 0
