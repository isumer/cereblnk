#!/usr/bin/env bash
# EditBoundaryHook — opt-in via $CB_DIR/flags/boundary
# The flag file contains one allowed path prefix per line (relative to cwd).
# Blocks Write/Edit outside the declared boundary. This blocks TOOLS, not
# shell side-effects — accident prevention, not a sandbox (documented).
# shellcheck source=../../scripts/lib/cbenv.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh"
[ -n "$CB_DIR" ] || exit 0  # no project root resolved: never write outside the project
if [ -z "$PYBIN" ]; then
  echo "cereblnk hook: no usable Python 3 — check skipped (failing open, not blocking your edit). Install Python 3 to re-arm hooks." >&2
  exit 0
fi
FLAG="$CB_DIR/flags/boundary"
[ -f "$FLAG" ] || exit 0
CEREBLNK_HOOK_INPUT="$(cat)"
export CEREBLNK_HOOK_INPUT
$PYBIN - "$FLAG" << 'PY'
import json, os, sys
flag = sys.argv[1]
try:
    data = json.loads(os.environ.get("CEREBLNK_HOOK_INPUT") or "{}")
except json.JSONDecodeError:
    data = {}
ti = data.get("tool_input") or {}
fp = ti.get("file_path") or ti.get("notebook_path") or ""
if not fp:
    sys.exit(0)
cwd = os.getcwd()
target = os.path.realpath(fp if os.path.isabs(fp) else os.path.join(cwd, fp))
prefixes = [l.strip() for l in open(flag) if l.strip()]
for p in prefixes:
    allowed = os.path.realpath(p if os.path.isabs(p) else os.path.join(cwd, p))
    if target == allowed or target.startswith(allowed + os.sep):
        sys.exit(0)
print(f"Cereblnk EditBoundaryHook: write to '{fp}' is outside the declared "
      f"boundary ({', '.join(prefixes)}). Adjust the plan or update the "
      f"boundary with /cb-boundary.", file=sys.stderr)
sys.exit(2)
PY
exit $?
