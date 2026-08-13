#!/usr/bin/env bash
# Gemini CLI runtime stages (CB-156).
#
# The interesting stage here is `hook`, and it needs no session. Gemini
# reads hooks from hooks/hooks.json inside the extension root, with no
# manifest field to point elsewhere. That file is Claude Code's binding.
# Whether the collision exists is a fact about this tree, so it is
# measured rather than waited on — and it is measured as FAIL, because
# surfacing it is the whole point. A runtime test that hid it would be
# worse than no runtime test.
#
# Contract: see tests/runtime/README.md.
set -uo pipefail

STAGE="${1:?stage required}"
ROOT="${CB_ROOT:?}"
EXT="$ROOT/plugins/cereblnk"

say() { printf '%s\n' "$*"; }

needs_auth() {
  if [ -z "${GEMINI_API_KEY:-}${GOOGLE_API_KEY:-}" ]; then
    say "CB_STATUS=BLOCKED"
    say "CB_REASON=no Gemini credentials on this runner; authenticated stages need GEMINI_API_KEY as a repository secret and run wherever it is present"
    return 0
  fi
  return 1
}

case "$STAGE" in

install)
  if ! command -v gemini >/dev/null 2>&1; then
    say "CB_STATUS=BLOCKED"
    say "CB_REASON=the gemini CLI is not on PATH; the workflow installs it before this runs, so this means the install step did not complete"
    exit 0
  fi
  say "CB_STATUS=PASS"
  say "CB_EVIDENCE=host_version=$(gemini --version 2>&1 | head -1)"
  ;;

context)
  MF="$EXT/gemini-extension.json"
  if [ ! -f "$MF" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=gemini-extension.json is missing from the extension root"
    exit 0
  fi
  NAME="$(python3 -c "import json;print(json.load(open('$MF')).get('contextFileName',''))" 2>/dev/null)"
  if [ -z "$NAME" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=the manifest declares no contextFileName, so no instruction file is loaded"
  elif [ -f "$EXT/$NAME" ]; then
    say "CB_STATUS=PASS"
    say "CB_EVIDENCE=contextFileName=${NAME} resolves inside the extension root"
  else
    say "CB_STATUS=FAIL"
    say "CB_REASON=the manifest names ${NAME}, which is not in the extension root"
  fi
  ;;

skill)
  COUNT="$(find "$EXT/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$COUNT" -eq 0 ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=no SKILL.md under the extension root's skills/ directory"
    exit 0
  fi
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=${COUNT} skills are discoverable by folder, but no session driver exists to observe one being activated (CB-155)"
  ;;

subagent)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=sub-agents are a preview feature on this host and no session driver exists (CB-155)"
  ;;

hook)
  DEFAULT="$EXT/hooks/hooks.json"
  MINE="$EXT/hooks/gemini-hooks.json"
  if [ ! -f "$DEFAULT" ]; then
    say "CB_STATUS=UNMEASURED"
    say "CB_REASON=no hooks/hooks.json in the extension root to inspect"
    exit 0
  fi
  if grep -q 'CLAUDE_PLUGIN_ROOT' "$DEFAULT" 2>/dev/null; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=hooks/hooks.json in the extension root is Claude Code's binding — Claude's root variable, Claude's tool names. This host reads that path and offers no manifest field to redirect it, so the generated Gemini binding beside it is never loaded. CB-143 holds the decision."
    say "CB_EVIDENCE=default_hooks_owner=claude"
    [ -f "$MINE" ] && say "CB_EVIDENCE=generated_binding_present_but_unread=hooks/gemini-hooks.json"
    exit 0
  fi
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=the default hooks file is not Claude's, but no session driver exists to observe a hook firing (CB-155)"
  ;;

veto)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=no session driver; this stage must assert the target file was not written, never that a refusal was printed (CB-155)"
  ;;

finish)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=no session driver for the turn-end guard (CB-155)"
  ;;

*)
  say "CB_STATUS=UNSUPPORTED"
  say "CB_REASON=stage ${STAGE} is not part of the Gemini sequence"
  ;;
esac
