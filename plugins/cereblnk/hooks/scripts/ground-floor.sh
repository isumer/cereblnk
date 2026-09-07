#!/usr/bin/env bash
# GroundFloorHook (SubagentStop) — CB-167/G-2/G-3. Exit 2 retains agents with bad citations.
# Conductor tasks are excluded; re-entry is bounded and errors fail open.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0
[ -n "${CB_ROOT:-}" ] || exit 0

RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/ground-check"
[ -f "$CHECK" ] || exit 0

RESULT="$(printf '%s' "$INPUT" | CB_RUN="$RUN" CB_ROOT="$CB_ROOT" \
  CB_CHECK="$CHECK" CB_MAX="${CB_GROUND_NUDGES:-2}" $PYBIN -c '
import json, os, pathlib, re, subprocess, sys

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)

def norm(value):
    return re.sub(r"[^a-z0-9]", "", value.rsplit(":", 1)[-1].lower())

def top(text, key):
    m = re.search(r"^%s\s*:\s*(.*)$" % re.escape(key), text, re.M)
    if not m:
        return ""
    return m.group(1).split("#", 1)[0].strip().strip("\"" + chr(39))

run = pathlib.Path(os.environ["CB_RUN"])
blocks = []
try:
    for path in sorted(run.glob("*.yaml")):
        if not path.is_file():
            continue
        body = path.read_text(encoding="utf-8", errors="replace")
        if top(body, "kind") not in ("response", "verification", "challenge"):
            continue
        if norm(top(body, "role")) == norm(agent):
            blocks.append(path)
except Exception:
    sys.exit(0)
if not blocks:
    sys.exit(0)

failures = []
try:
    for block in blocks:
        r = subprocess.run(
            [os.environ["CB_CHECK"], str(block), os.environ["CB_ROOT"]],
            capture_output=True, text=True, timeout=60)
        if r.returncode not in (0, 1):
            sys.exit(0)
        if r.returncode == 1:
            failures.append(r.stderr.rstrip("\n"))
except Exception:
    sys.exit(0)
if not failures:
    sys.exit(0)

state = run / ("ground-floor.%s.state" % agent)
count = 0
if state.exists():
    try:
        count = int(state.read_text(encoding="utf-8").strip() or 0)
    except ValueError:
        count = 0
if count >= int(os.environ["CB_MAX"]):
    sys.exit(0)
try:
    state.write_text(str(count + 1), encoding="utf-8")
except Exception:
    sys.exit(0)

print("BLOCK")
print("\n".join(failures))
' 2>/dev/null || true)"

case "$RESULT" in
  BLOCK$'\n'*) printf '%s\n' "${RESULT#*$'\n'}" >&2; exit 2 ;;
esac
exit 0
