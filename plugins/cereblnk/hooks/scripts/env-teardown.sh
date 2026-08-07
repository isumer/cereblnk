#!/usr/bin/env bash
# EnvTeardownHook (SessionEnd) — CB-115.
#
# An environment started for a run outlives the run when nothing reaps
# it. The cost is not abstract: a compose project left up holds ports and
# volumes, and the next run's preflight then reads "something already
# answers the health URL" and skips — one forgotten teardown silently
# disables the stage for every run after it.
#
# SessionEnd is the right event. Stop fires at the end of every turn and
# the environment must survive across turns within a run.
#
# Only ever takes down what this project started: scripts/env down reads
# the recorded down command from flags/env-active, not from config, so a
# config edited mid-run cannot redirect teardown at somebody else's
# stack.
#
# Fail open and silent. SessionEnd cannot block anything, and a teardown
# that errors must not be the last thing a user sees.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0
[ -f "$CB_DIR/flags/env-active" ] || exit 0

ENV_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/env"
[ -f "$ENV_SCRIPT" ] || exit 0

$PYBIN "$ENV_SCRIPT" down >/dev/null 2>&1 || true
exit 0
