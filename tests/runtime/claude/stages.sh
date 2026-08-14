#!/usr/bin/env bash
# Claude Code runtime stages (CB-156).
#
# The reference host: the only one whose bindings are M rather than
# declared:. That makes it the profile the others are compared against,
# and it makes an unmeasured stage here more expensive than an unmeasured
# stage elsewhere — a capability this host is published as having, that
# nobody has watched work, is the strongest claim in the matrix resting
# on the least evidence.
#
# Contract: see tests/runtime/README.md.
set -uo pipefail

STAGE="${1:?stage required}"
ROOT="${CB_ROOT:?}"
WORK="${CB_WORKDIR:?}"
PLUGIN="$ROOT/plugins/cereblnk"

say() { printf '%s\n' "$*"; }

. "$(dirname "${BASH_SOURCE[0]}")/../lib/authprobe.sh"

# Which service answers this host, and which variable holds its
# credential. Claude Code speaks its native protocol to whatever
# ANTHROPIC_BASE_URL names, so the CLI alone does not identify the
# provider — and a run backed by a gateway has not established anything
# about direct provider billing.
PROVIDER="$(cb_claude_provider)"
CRED_VAR="$(cb_provider_credential_var "$PROVIDER")"

# Was: "is ANTHROPIC_API_KEY set?". On the gateway path that variable
# must be explicitly empty, so the old test read a correct configuration
# as a missing credential. The provider decides which variable to read.
needs_auth() {
  if [ "$PROVIDER" = "none" ]; then
    say "CB_STATUS=BLOCKED"
    say "CB_REASON=no inference provider is configured for this host"
    return 0
  fi
  _r="$(cb_auth_probe claude "$CRED_VAR" "$WORK")"
  cb_auth_recall "$WORK" claude
  cb_auth_report "$_r" "$CRED_VAR"
}

case "$STAGE" in

install)
  if ! command -v claude >/dev/null 2>&1; then
    say "CB_STATUS=BLOCKED"
    say "CB_REASON=the claude CLI is not on PATH; the workflow installs it before this runs, so this means the install step did not complete"
    exit 0
  fi
  say "CB_STATUS=PASS"
  say "CB_EVIDENCE=host_version=$(claude --version 2>&1 | head -1)"
  ;;

context)
  # The marketplace entry points at a plugin directory; whether that
  # directory is where it says is checkable offline, and a registry
  # pointing at nothing installs cleanly and delivers nothing.
  MP="$ROOT/.claude-plugin/marketplace.json"
  if [ ! -f "$MP" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=.claude-plugin/marketplace.json is missing"
    exit 0
  fi
  SRC="$(python3 -c "import json;p=json.load(open('$MP'))['plugins'][0];print(p.get('source',''))" 2>/dev/null)"
  if [ -n "$SRC" ] && [ -d "$ROOT/${SRC#./}" ]; then
    say "CB_STATUS=PASS"
    say "CB_EVIDENCE=marketplace source ${SRC} resolves to a directory"
  else
    say "CB_STATUS=FAIL"
    say "CB_REASON=the marketplace declares source ${SRC:-<none>}, which is not a directory in this tree"
  fi
  ;;

plugin)
  # Installation is the gate every session driver sits behind. A hook
  # cannot fire from a plugin that never loaded, so measuring this before
  # writing drivers is the difference between finding out now and finding
  # out after the work.
  #
  # The subcommand is discovered, not assumed. A CLI that does not offer
  # one tells us something; a guess that fails tells us nothing.
  if command -v claude >/dev/null 2>&1; then
    HELP="$WORK/claude-plugin-help.log"
    if timeout 60 claude plugin --help >"$HELP" 2>&1; then
      SUB=""
      for cand in install add; do
        grep -qE "^[[:space:]]*${cand}\\b" "$HELP" && SUB="$cand" && break
      done
      if [ -z "$SUB" ]; then
        say "CB_EVIDENCE=install_attempt=no_install_subcommand"
      else
        INS="$WORK/claude-install.log"
        if timeout 180 claude plugin "$SUB" "$ROOT/plugins/cereblnk" >"$INS" 2>&1; then
          say "CB_EVIDENCE=install_result=ACCEPTED"
        else
          say "CB_EVIDENCE=install_result=REFUSED"
          say "CB_EVIDENCE=claude-install.log"
        fi
      fi
    else
      say "CB_EVIDENCE=plugin_subcommand=absent"
    fi
  else
    say "CB_EVIDENCE=install_attempt=no_cli"
  fi

  # The binding this host loads is generated. If the committed file has
  # drifted from its generator, what installs here is not what the policy
  # says — and that is measurable without the host.
  if python3 "$ROOT/scripts/check-generated" >/dev/null 2>&1; then
    COUNT="$(python3 -c "
import json
d=json.load(open('$PLUGIN/hooks/hooks.json'))
print(sum(len(h['hooks']) for e in d['hooks'].values() for h in e))" 2>/dev/null)"
    say "CB_STATUS=PASS"
    say "CB_EVIDENCE=hooks.json matches its generator and binds ${COUNT} hook(s)"
  else
    say "CB_STATUS=FAIL"
    say "CB_REASON=the committed Claude binding differs from what gen-bindings produces, so the plugin would install something the policy does not describe"
  fi
  ;;

auth)
  # Its own row rather than a prerequisite inferred from six downstream
  # BLOCKEDs. "skill = BLOCKED, the provider refused" is readable and
  # structurally ambiguous: the evidence could not answer whether
  # authentication succeeded, so a later runtime failure kept reopening
  # a question that had already been settled.
  cb_auth_stage claude "$PROVIDER" "$CRED_VAR" "$WORK"
  ;;

skill)
  COUNT="$(find "$PLUGIN/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$COUNT" -eq 0 ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=no SKILL.md under the plugin's skills/ directory"
    exit 0
  fi
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=${COUNT} skills are discoverable, but no session driver exists to observe one being invoked (CB-155)"
  ;;

agent|subagent)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=no session driver for specialist delegation (CB-155)"
  ;;

hook)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=no session driver; the binding is verified structurally by the plugin stage, which is not the same as watching a hook fire (CB-155)"
  ;;

veto)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=no session driver; this stage must assert the target file was not written, never that a refusal was printed (CB-155)"
  ;;

finish)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=no session driver for the five finish floors (CB-155)"
  ;;

*)
  say "CB_STATUS=UNSUPPORTED"
  say "CB_REASON=stage ${STAGE} is not part of the Claude Code sequence"
  ;;
esac
