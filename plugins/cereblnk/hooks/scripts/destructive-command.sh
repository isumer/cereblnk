#!/usr/bin/env bash
# DestructiveCommandHook — opt-in via $CB_DIR/flags/careful
# Blocks (exit 2) irreversible shell ops so the user is asked first.
# Allowlisted: routine build-artifact cleanups.
# shellcheck source=../../scripts/lib/cbenv.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh"
[ -n "$CB_DIR" ] || exit 0  # no project root resolved: never write outside the project
if [ -z "$PYBIN" ]; then
  echo "cereblnk hook: no usable Python 3 — check skipped (failing open, not blocking your edit). Install Python 3 to re-arm hooks." >&2
  exit 0
fi
[ -f "$CB_DIR/flags/careful" ] || exit 0
CEREBLNK_HOOK_INPUT="$(cat)"
export CEREBLNK_HOOK_INPUT CB_DIR
$PYBIN << 'PY'
import json, os, re, sys
try:
    data = json.loads(os.environ.get("CEREBLNK_HOOK_INPUT") or "{}")
except json.JSONDecodeError:
    data = {}
cmd = (data.get("tool_input") or {}).get("command", "") or ""
allow = [r"rm\s+-rf?\s+(\./)?(node_modules|dist|build|target|\.next|coverage)(\s|$)"]
if any(re.search(a, cmd) for a in allow):
    sys.exit(0)
patterns = [
    (r"rm\s+(-\w*\s+)*-\w*[rf]\w*[rf]?\w*\s", "recursive/forced delete"),
    (r"git\s+push\s+.*(--force|-f)(\s|$)", "force push"),
    (r"git\s+reset\s+--hard", "hard reset"),
    (r"git\s+clean\s+-\w*f", "git clean -f"),
    (r"\bdrop\s+(table|database|schema)\b", "SQL DROP"),
    (r"\btruncate\s+table\b", "SQL TRUNCATE"),
    (r"docker\s+(compose|-c)?.*\bdown\b.*(-v|--volumes)", "compose down with volume removal"),
    (r"docker\s+volume\s+(rm|prune)", "docker volume delete"),
    (r"docker\s+system\s+prune", "docker system prune"),
    (r"docker\s+(rm|rmi)\s+(-\w*\s+)*-\w*f", "forced docker remove"),
    (r"mkfs|dd\s+if=", "disk-level write"),
]
for pat, label in patterns:
    if re.search(pat, cmd, re.IGNORECASE):
        print(f"Cereblnk DestructiveCommandHook: blocked irreversible operation ({label}). "
              f"Ask the user for explicit confirmation, or have them disable /cb-careful "
              f"(remove {os.environ.get('CB_DIR','.claude/cereblnk')}/flags/careful) if intended.", file=sys.stderr)
        sys.exit(2)
sys.exit(0)
PY
exit $?
