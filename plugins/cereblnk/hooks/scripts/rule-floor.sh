#!/usr/bin/env bash
# RuleFloorHook (SessionStart) — CB-185 puts the technology-neutral constraint
# floor in context once per session, so the rules apply without a cereblnk
# command being invoked first.
#
# Only affordable because select-rules projects: the ten common/ files are
# 5,307 tokens read whole and 1,821 projected. Injecting the whole layer on
# every session could not be justified; injecting the constraints can.
#
# Never blocks and never mutates. A SessionStart hook that fails must cost the
# session nothing, so every path here exits 0.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"
. "$SCRIPTS/lib/cbenv.sh" 2>/dev/null || true
[ -n "${PYBIN:-}" ] || exit 0

# Opt out without uninstalling: some sessions want a bare model.
case "${CB_RULE_FLOOR:-1}" in
  0 | no | off | false) exit 0 ;;
esac

SELECT="$SCRIPTS/select-rules"
[ -x "$SELECT" ] || [ -f "$SELECT" ] || exit 0

FLOOR="$("$PYBIN" "$SELECT" --floor 2>/dev/null || true)"
[ -n "$FLOOR" ] || exit 0

# A runaway injection is worse than none: the floor is ~7,300 characters, so
# anything past four times that is a bug and must not reach the context.
if [ "${#FLOOR}" -gt 30000 ]; then
  exit 0
fi

INPUT="$(cat 2>/dev/null || true)"

CB_FLOOR_TEXT="$FLOOR" CB_FLOOR_INPUT="$INPUT" CB_FLOOR_DIR="${CB_DIR:-}" \
  "$PYBIN" - <<'PY' 2>/dev/null || true
import json
import os
import pathlib
import re

floor = os.environ.get("CB_FLOOR_TEXT") or ""
if not floor.strip():
    raise SystemExit(0)

# Record which session this was injected for, so select-rules can stop
# appending common/ on top of it. Evidence, not assumption: if this write
# fails the marker is absent, select-rules emits common/ as before, and the
# cost is a duplicate rather than a missing constraint.
try:
    session = re.search(r'"session_id"\s*:\s*"([^"]+)"',
                        os.environ.get("CB_FLOOR_INPUT") or "")
    cb_dir = os.environ.get("CB_FLOOR_DIR") or ""
    if session and cb_dir:
        flags = pathlib.Path(cb_dir) / "flags"
        flags.mkdir(parents=True, exist_ok=True)
        (flags / "rule-floor").write_text(session.group(1), encoding="utf-8")
except Exception:
    pass

note = (
    "Cereblnk constraint floor — the technology-neutral rules, in context "
    "because the plugin is installed, not because a command ran. These are "
    "constraints on code you write or review, not instructions for this "
    "reply, and they are the floor every language and framework rule "
    "extends. Per-path rules are not here: run "
    "`scripts/select-rules --constraints <path>` for those when you touch a "
    "file. Examples and the failure shapes outside security were projected "
    "away; the source files carry them if one is needed.\n\n" + floor
)
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "SessionStart", "additionalContext": note}}))
PY
exit 0
