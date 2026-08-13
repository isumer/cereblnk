#!/usr/bin/env bash
# Cursor runtime stages (CB-156).
#
# The host most likely to stay BLOCKED past the credential question.
# Cursor is an editor first, and whether its plugin surface can be driven
# headlessly in CI at all is itself unmeasured — so the stages here
# distinguish two things a single BLOCKED would blur: no credentials, and
# no way to reach the surface from a runner. The second is a finding
# about the host; the first is a finding about the runner.
#
# Contract: see tests/runtime/README.md.
set -uo pipefail

STAGE="${1:?stage required}"
ROOT="${CB_ROOT:?}"
PLUGIN="$ROOT/plugins/cereblnk"

say() { printf '%s\n' "$*"; }

no_headless() {
  say "CB_STATUS=BLOCKED"
  say "CB_REASON=no headless driver for this host; whether its plugin surface can be exercised from a runner at all is itself unmeasured, and that is a question about the host rather than about credentials (CB-155)"
}

case "$STAGE" in

install)
  for bin in cursor-agent cursor; do
    if command -v "$bin" >/dev/null 2>&1; then
      say "CB_STATUS=PASS"
      say "CB_EVIDENCE=host_version=$("$bin" --version 2>&1 | head -1)"
      exit 0
    fi
  done
  say "CB_STATUS=BLOCKED"
  say "CB_REASON=no cursor CLI on PATH. Unlike the other three hosts this one has no published install this workflow attempts, so BLOCKED here means nobody has established there is one to attempt"
  ;;

marketplace)
  MP="$ROOT/.cursor-plugin/marketplace.json"
  if [ ! -f "$MP" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=.cursor-plugin/marketplace.json is missing"
    exit 0
  fi
  SRC="$(python3 -c "import json;p=json.load(open('$MP'))['plugins'][0];print(p.get('source',''))" 2>/dev/null)"
  if [ -n "$SRC" ] && [ -d "$ROOT/$SRC" ]; then
    say "CB_STATUS=PASS"
    say "CB_EVIDENCE=marketplace source ${SRC} resolves to a directory"
  else
    say "CB_STATUS=FAIL"
    say "CB_REASON=the marketplace declares source ${SRC:-<none>}, which is not a directory in this tree"
  fi
  ;;

plugin)
  # This host redirects its hooks by manifest, which is the escape the
  # other two do not have. Whether the redirect points at the generated
  # binding is checkable offline, and it is the whole reason Cursor is
  # not caught by the collision in CB-143.
  MF="$PLUGIN/.cursor-plugin/plugin.json"
  if [ ! -f "$MF" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=.cursor-plugin/plugin.json is missing"
    exit 0
  fi
  HOOKS="$(python3 -c "import json;print(json.load(open('$MF')).get('hooks',''))" 2>/dev/null)"
  if [ -z "$HOOKS" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=the manifest declares no hooks path, so this host falls back to hooks/hooks.json — which is Claude Code's binding"
  elif [ -f "$PLUGIN/${HOOKS#./}" ]; then
    say "CB_STATUS=PASS"
    say "CB_EVIDENCE=hooks redirect ${HOOKS} resolves, so the Claude binding is not what loads here"
  else
    say "CB_STATUS=FAIL"
    say "CB_REASON=the manifest redirects hooks to ${HOOKS}, which is not in the plugin root"
  fi
  ;;

skill)
  COUNT="$(find "$PLUGIN/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$COUNT" -eq 0 ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=no SKILL.md under the plugin's skills/ directory"
    exit 0
  fi
  no_headless
  ;;

agent|subagent|hook|veto|finish)
  no_headless
  ;;

*)
  say "CB_STATUS=UNSUPPORTED"
  say "CB_REASON=stage ${STAGE} is not part of the Cursor sequence"
  ;;
esac
