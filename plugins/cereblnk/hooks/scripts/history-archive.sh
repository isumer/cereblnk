#!/usr/bin/env bash
# HistoryArchiveHook (PreCompact) — archives the session transcript to
# <project>/.claude/cereblnk/history/ BEFORE compaction discards detail.
# Compaction is irreversible information loss; this hook exists to make
# it reversible. ALWAYS fails open (exit 0): an archiving problem must
# never block or delay compaction itself.
set -uo pipefail
# shellcheck source=../../scripts/lib/cbenv.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"
if [ -z "${CB_ROOT:-}" ]; then
  echo "cereblnk history-archive: no project root resolved; skipping (never writing to temp)." >&2
  exit 0
fi
# Runtime state belongs under CB_DIR with everything else. This wrote to
# .claude/history for one release, which split the data from the very
# config that governs it ($CB_DIR/config/history-keep, below) and put
# Cereblnk files directly in Claude Code's own config directory.
HIST_DIR="$CB_DIR/history"
# One-time move of the old location. Only when the legacy directory
# exists and the new one does not, so it cannot run twice or overwrite.
# Fails open like everything else here: a failed move loses nothing,
# the archives simply stay where they are.
LEGACY="$CB_ROOT/.claude/history"
if [ -d "$LEGACY" ] && [ ! -d "$HIST_DIR" ]; then
  mkdir -p "$(dirname "$HIST_DIR")" 2>/dev/null &&
    mv "$LEGACY" "$HIST_DIR" 2>/dev/null &&
    echo "cereblnk history-archive: moved existing archives from $LEGACY to $HIST_DIR" >&2
fi

# --- extract transcript_path + trigger + session_id from stdin JSON ---
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
  # no Python: best-effort sed extraction (paths are plain in practice)
  TRANSCRIPT="$(printf '%s' "$INPUT" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  TRIGGER="$(printf '%s' "$INPUT" | sed -n 's/.*"trigger"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  SESSION="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  SESSION="${SESSION:0:8}"
  [ -n "$TRIGGER" ] || TRIGGER="unknown"
fi

# expand a leading ~ if the harness sent one
case "$TRANSCRIPT" in "~/"*) TRANSCRIPT="$HOME/${TRANSCRIPT#\~/}";; esac

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  # Known upstream caveat: transcript_path can arrive empty
  # (anthropics/claude-code#13668). Nothing to archive — do not block.
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

# retention: keep the newest N (default 20; override via config file)
KEEP=20
CFG="$CB_DIR/config/history-keep"
[ -f "$CFG" ] && KEEP="$(head -1 "$CFG" | tr -cd '0-9')" && [ -n "$KEEP" ] || KEEP=20
ls -1t "$HIST_DIR"/*.jsonl 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
  rm -f "$old" 2>/dev/null || true
done
exit 0
