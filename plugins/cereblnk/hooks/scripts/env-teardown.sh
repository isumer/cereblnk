#!/usr/bin/env bash
# EnvTeardownHook (SessionEnd) — CB-115. Stop would end environments between turns.
# Use the recorded down command so config edits cannot redirect teardown; fail open.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0
[ -f "$CB_DIR/flags/env-active" ] || exit 0

ENV_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/env"
[ -f "$ENV_SCRIPT" ] || exit 0

$PYBIN "$ENV_SCRIPT" down >/dev/null 2>&1 || true
exit 0
