#!/usr/bin/env bash
# StaleRunHook (SessionStart) — CB-171 reports a stale pinned ledger without closed tasks.
# Never mutate/block; read the pin directly so fallback cannot advise cleanup for another run.

# CB-168 made run-active presence-only, so forgotten pins survive across sessions.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

HOURS="${CB_STALE_RUN_HOURS:-12}"
case "$HOURS" in
  "" | *[!0-9]*) exit 0 ;;
esac

MESSAGE="$(CB_STALE_RUN_DIR="$CB_DIR" CB_STALE_RUN_HOURS="$HOURS" \
  "$PYBIN" - <<'PY' 2>/dev/null || true
import datetime
import os
import pathlib
import re
import time

try:
    cb_dir = pathlib.Path(os.environ["CB_STALE_RUN_DIR"])
    hours = int(os.environ["CB_STALE_RUN_HOURS"])
    # Keep arithmetic and date conversion bounded on every platform.
    if hours < 0 or hours > 876000:
        raise ValueError("threshold out of range")

    flag = cb_dir / "flags" / "run-active"
    if not flag.is_file():
        raise SystemExit(0)
    first = flag.read_text(encoding="utf-8").splitlines()[0]
    run_id = first.translate({ord(c): None for c in " \t\r\n"})
    if not re.fullmatch(r"(?!\.)[A-Za-z0-9._-]+", run_id):
        raise SystemExit(0)

    run_dir = cb_dir / "context" / run_id
    if not run_dir.is_dir():
        raise SystemExit(0)
    plan = run_dir / "plan.md"
    has_plan = plan.is_file()
    evidence = plan if has_plan else run_dir

    mtime = evidence.stat().st_mtime
    if time.time() - mtime <= hours * 3600:
        raise SystemExit(0)
    if has_plan:
        body = plan.read_text(encoding="utf-8")
        if re.search(r"^[ \t]*-[ \t]+\[[xX]\](?:[ \t]|$)", body, re.MULTILINE):
            raise SystemExit(0)

    date = datetime.datetime.fromtimestamp(
        mtime, datetime.timezone.utc
    ).strftime("%Y-%m-%dT%H:%M:%SZ")
    print(
        f"cereblnk: run-active pins {run_id} from {date}, ledger cold and "
        "no task closed — use `/cb-resume` to continue it, or "
        f"`run-flag abandon \"\" {run_id}` to retire it without claiming completion."
    )
except SystemExit:
    pass
except Exception:
    pass
PY
)"

[ -z "$MESSAGE" ] || printf '%s\n' "$MESSAGE" >&2
exit 0
