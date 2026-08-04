#!/usr/bin/env bash
# PostEditTestHook — policy-driven: active when gate level 3 work
# is flagged ($CB_DIR/flags/gate3) AND a test command is configured
# ($CB_DIR/config/test-command, single line). Runs the configured test
# subset after edits; a failure is reported back (exit 2 → stderr to Claude).
# shellcheck source=../../scripts/lib/cbenv.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh"
[ -n "$CB_DIR" ] || exit 0  # no project root resolved: never write outside the project
if [ -z "$PYBIN" ]; then
  echo "cereblnk hook: no usable Python 3 — check skipped (failing open, not blocking your edit). Install Python 3 to re-arm hooks." >&2
  exit 0
fi
[ -f "$CB_DIR/flags/gate3" ] || exit 0
CFG="$CB_DIR/config/test-command"
[ -f "$CFG" ] || exit 0
CMD=$(head -n1 "$CFG")
[ -n "$CMD" ] || exit 0
OUT=$(bash -c "$CMD" 2>&1)
STATUS=$?
if [ $STATUS -ne 0 ]; then
  echo "Cereblnk PostEditTestHook: test command failed after edit (exit $STATUS)." >&2
  echo "$OUT" | tail -n 30 >&2
  exit 2
fi
exit 0
