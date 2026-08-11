#!/usr/bin/env bash
# ScratchGuardHook (PreToolUse:Write) — CB-107.
#
# A run left debug.txt, debug2.txt and medium.txt at the repository root.
# None were deliverables; all three were working notes that outlived the
# thought. Nothing swept them, so they became someone's diff.
#
# The signal is not the filename. `medium.txt` looks like a document and
# `debug2.txt` looks like scratch, but both are the same mistake, and a
# pattern list would have caught one of them. What they share is shape:
# a NEW file, at the repository ROOT, created mid-run. Real work lands
# in a subdirectory the project already has; root-level files are added
# rarely and deliberately, almost never while a run is executing.
#
# So: block a new untracked file at the root during an active run, and
# name the place scratch actually belongs.
#
# Two nudges, then allow — the digest-cap idiom. Adding a genuine
# root-level file mid-run is rare but not impossible, and a guard that
# can never be satisfied stops being a guard and becomes an obstacle.
#
# Fail-open everywhere: no run, no interpreter, no root, unreadable
# input. A scratch file is untidy; a blocked legitimate write is worse.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
# shellcheck source=../lib/hostio.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/hostio.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${CB_ROOT:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

# Only while a run is executing, and only while its flag is fresh — the
# same TTL discipline the delegation guard uses, for the same reason.
[ -f "$CB_DIR/flags/run-active" ] || exit 0
[ -n "$(find "$CB_DIR/flags" -name run-active -mmin "-${CB_RUN_TTL_MIN:-240}" 2>/dev/null)" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"

REASON="$(printf '%s' "$INPUT" | CB_ROOT="$CB_ROOT" CB_DIR="$CB_DIR" \
  CB_MAX="${CB_SCRATCH_NUDGES:-2}" $PYBIN -c '
import json, os, pathlib, re, subprocess, sys

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if d.get("tool_name") != "Write":
    sys.exit(0)

raw = (d.get("tool_input") or {}).get("file_path") or ""
if not raw:
    sys.exit(0)

root = pathlib.Path(os.environ["CB_ROOT"])
norm = raw.replace("\\\\", "/")

# Root-level means: a bare name, or a path whose parent is the root.
if "/" in norm:
    try:
        parent = pathlib.Path(norm).parent.resolve()
    except Exception:
        sys.exit(0)
    try:
        if parent != root.resolve():
            sys.exit(0)
    except Exception:
        sys.exit(0)
    name = pathlib.Path(norm).name
else:
    name = norm

target = root / name
if target.exists():
    sys.exit(0)          # editing something that already lives here

# Tracked files are the project deciding, not the run inventing.
try:
    r = subprocess.run(["git", "ls-files", "--error-unmatch", "--", name],
                       cwd=str(root), capture_output=True, text=True, timeout=10)
    if r.returncode == 0:
        sys.exit(0)
except Exception:
    pass

run_dir = sorted((root / ".claude/cereblnk/context").glob("*/"),
                 key=lambda p: p.stat().st_mtime, reverse=True)
scratch = (run_dir[0] / "scratch") if run_dir else pathlib.Path(os.environ["CB_DIR"]) / "scratch"

state = pathlib.Path(os.environ["CB_DIR"]) / "flags" / "scratch-guard.state"
try:
    seen = int(state.read_text(encoding="utf-8").strip() or 0)
except Exception:
    seen = 0
if seen >= int(os.environ.get("CB_MAX") or 2):
    sys.exit(0)
try:
    state.write_text(str(seen + 1), encoding="utf-8")
except Exception:
    sys.exit(0)

print("%s is a new file at the repository root, created during a run. "
      "Working notes belong in %s, which is ignored by git and swept with "
      "the run. If this really is a deliverable, put it in the directory "
      "that owns it, or say so and write it again." % (name, scratch))
' 2>/dev/null || true)"

[ -n "$REASON" ] || exit 0
cb_block "cereblnk scratch-guard: $REASON"
