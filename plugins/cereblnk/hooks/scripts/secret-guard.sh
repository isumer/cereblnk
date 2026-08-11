#!/usr/bin/env bash
# SecretGuardHook — ALWAYS ON, fail-closed on detection.
# Blocks Write/Edit content that contains likely credentials before the
# artifact is written.
# shellcheck source=../../scripts/lib/cbenv.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh"
# shellcheck source=../lib/hostio.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/hostio.sh" 2>/dev/null || true
[ -n "$CB_DIR" ] || exit 0  # no project root resolved: never write outside the project
CB_HOOK_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
export CB_HOOK_LIB
if [ -z "$PYBIN" ]; then
  echo "cereblnk hook: no usable Python 3 — check skipped (failing open, not blocking your edit). Install Python 3 to re-arm hooks." >&2
  exit 0
fi
CEREBLNK_HOOK_INPUT="$(cat)"
export CEREBLNK_HOOK_INPUT
$PYBIN << 'PY'
import json, os, re, sys
sys.path.insert(0, os.environ["CB_HOOK_LIB"])
from cbhost import block
try:
    data = json.loads(os.environ.get("CEREBLNK_HOOK_INPUT") or "{}")
except json.JSONDecodeError:
    data = {}
ti = data.get("tool_input") or {}
content = " ".join(str(ti.get(k, "")) for k in ("content", "new_string", "new_str", "new_source"))
if not content.strip():
    sys.exit(0)
patterns = [
    (r"github_pat_[A-Za-z0-9_]{20,}", "GitHub fine-grained PAT"),
    (r"gh[pousr]_[A-Za-z0-9]{30,}", "GitHub token"),
    (r"AKIA[0-9A-Z]{16}", "AWS access key ID"),
    (r"sk-[A-Za-z0-9_-]{20,}", "API secret key"),
    (r"xox[baprs]-[A-Za-z0-9-]{10,}", "Slack token"),
    (r"-----BEGIN\s+(RSA|EC|OPENSSH|DSA|PGP)?\s*PRIVATE KEY-----", "private key material"),
    (r"(?i)(password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*['\"][^'\"\s]{12,}['\"]", "hardcoded credential assignment"),
]
for pat, label in patterns:
    if re.search(pat, content):
        block(f"Cereblnk SecretGuardHook: blocked write containing a likely secret "
              f"({label}). Redact it or load it from the environment/secret store; "
              f"never commit credentials to artifacts.")
sys.exit(0)
PY
exit $?
