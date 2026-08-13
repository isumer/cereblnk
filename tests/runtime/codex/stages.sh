#!/usr/bin/env bash
# Codex runtime stages (CB-154).
#
# Each stage prints CB_STATUS and, where the status does not speak for
# itself, CB_REASON. tests/runtime/run-host reads those and writes the
# evidence artifact; nothing here writes the artifact itself, so a stage
# cannot quietly award itself a result the runner did not see.
#
# Contract, one line each:
#
#   CB_STATUS=PASS|FAIL|BLOCKED|UNMEASURED|UNSUPPORTED
#   CB_REASON=<why>            required for BLOCKED and UNSUPPORTED
#   CB_CAPABILITY=<id>         must exist in policies/capabilities.yaml
#   CB_EVIDENCE=<observation>  a path inside the artifact, or a short note
#
# Never print a credential. Never print a whole host config directory.
# The evidence is uploaded and kept; credentials are neither.
set -uo pipefail

STAGE="${1:?stage required}"
ROOT="${CB_ROOT:?}"
WORK="${CB_WORKDIR:?}"

say() { printf '%s\n' "$*"; }

. "$(dirname "${BASH_SOURCE[0]}")/../lib/authprobe.sh"

# A stage that needs an authenticated session, on a runner with no
# credentials, is BLOCKED — not FAIL. A missing credential is a fact
# about the environment, and calling it a failure would blame this
# repository for the runner's configuration.
# Was: "is the variable set?". A set variable proves a repository
# secret exists, not that the provider accepted it — and the two failed
# in ways somebody would act on differently while reporting the same
# thing. The probe runs once per stage, which is a trivial call, and
# says which of the two it was.
needs_auth() {
  _r="$(cb_auth_probe codex CODEX_API_KEY "$WORK")"
  cb_auth_report "$_r" CODEX_API_KEY
}

case "$STAGE" in

install)
  if ! command -v codex >/dev/null 2>&1; then
    say "CB_STATUS=BLOCKED"
    say "CB_REASON=the codex CLI is not on PATH; the workflow installs it before this runs, so this means the install step did not complete"
    exit 0
  fi
  VERSION="$(codex --version 2>&1 | head -1)"
  say "CB_STATUS=PASS"
  say "CB_EVIDENCE=host_version=${VERSION}"
  ;;

marketplace)
  # The repo-local registry is a file this repository owns, so its shape
  # is checkable without the host. Whether Codex ingests it is a separate
  # observation and belongs to the plugin stage.
  MF="$ROOT/.agents/plugins/marketplace.json"
  if [ ! -f "$MF" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=.agents/plugins/marketplace.json is missing"
    exit 0
  fi
  if python3 -c "import json,sys; d=json.load(open('$MF')); sys.exit(0 if d.get('plugins') else 1)"; then
    say "CB_STATUS=PASS"
    say "CB_EVIDENCE=.agents/plugins/marketplace.json parses and declares a plugin"
  else
    say "CB_STATUS=FAIL"
    say "CB_REASON=the marketplace file declares no plugins"
  fi
  ;;

plugin)
  # A/B, because two questions were being answered with one result. The
  # shipped manifest carries a `hooks` field; the vendor's validator does
  # not accept it. Whether that field is the *only* thing standing
  # between this package and a valid one is a separate question, and
  # removing it to find out would be changing production configuration to
  # learn something a copy could teach.
  #
  # So: A is the tree as it ships. B is a copy with `hooks` removed. B is
  # built in the work directory and never merged; the difference between
  # the two verdicts is the finding.
  if [ -z "${CODEX_VALIDATOR:-}" ] || [ ! -f "${CODEX_VALIDATOR}" ]; then
    say "CB_STATUS=UNMEASURED"
    say "CB_REASON=CODEX_VALIDATOR not set; nothing about this manifest is established from this run"
    exit 0
  fi

  verdict() {
    # PASS, REJECTED, or CRASHED. A validator that never reached a
    # verdict tells us about the runner, not about the manifest, and both
    # exit 1.
    if python3 "$CODEX_VALIDATOR" "$1" >"$2" 2>&1; then
      printf 'PASS'
    elif grep -q "Plugin validation" "$2" 2>/dev/null; then
      printf 'REJECTED'
    else
      printf 'CRASHED'
    fi
  }

  A_LOG="$WORK/validator-a.log"
  A="$(verdict "$ROOT/plugins/cereblnk" "$A_LOG")"

  B_DIR="$WORK/variant-b"
  rm -rf "$B_DIR"
  mkdir -p "$B_DIR/.codex-plugin"
  cp -r "$ROOT/plugins/cereblnk/skills" "$B_DIR/" 2>/dev/null || true
  python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
d.pop('hooks', None)
json.dump(d, open(sys.argv[2], 'w'), indent=2)
" "$ROOT/plugins/cereblnk/.codex-plugin/plugin.json" "$B_DIR/.codex-plugin/plugin.json"
  B_LOG="$WORK/validator-b.log"
  B="$(verdict "$B_DIR" "$B_LOG")"

  say "CB_EVIDENCE=variant_a_shipped=${A}"
  say "CB_EVIDENCE=variant_b_without_hooks=${B}"
  say "CB_EVIDENCE=validator-a.log"
  say "CB_EVIDENCE=validator-b.log"

  # The validator's verdict and the runtime's are two contracts, and
  # CB-148 is the question of whether they agree. Validation is what the
  # marketplace asks; installation is what a user does. Measuring only
  # the first would leave every downstream stage waiting on a driver that
  # may have nothing to attach to — a hook cannot fire from a plugin that
  # never loaded.
  #
  # The subcommand is discovered rather than assumed. A CLI that does not
  # offer it tells us something; a guess that fails tells us nothing.
  if command -v codex >/dev/null 2>&1; then
    HELP="$WORK/codex-plugin-help.log"
    if timeout 60 codex plugin --help >"$HELP" 2>&1; then
      say "CB_EVIDENCE=codex_plugin_subcommand=present"
      SUB=""
      for cand in add install; do
        grep -qE "^[[:space:]]*${cand}\b" "$HELP" && SUB="$cand" && break
      done
      if [ -z "$SUB" ]; then
        say "CB_EVIDENCE=install_attempt=no_add_or_install_subcommand"
      else
        INS="$WORK/codex-install.log"
        if timeout 180 codex plugin "$SUB" "$ROOT/plugins/cereblnk" >"$INS" 2>&1; then
          # The runtime accepted what the validator refused. That is the
          # CB-148 contradiction, measured rather than argued about.
          say "CB_EVIDENCE=install_result=ACCEPTED"
        else
          say "CB_EVIDENCE=install_result=REFUSED"
          say "CB_EVIDENCE=codex-install.log"
        fi
      fi
    else
      say "CB_EVIDENCE=codex_plugin_subcommand=absent"
    fi
  else
    say "CB_EVIDENCE=install_attempt=no_cli"
  fi

  if [ "$A" = "CRASHED" ]; then
    say "CB_STATUS=UNMEASURED"
    say "CB_REASON=the vendor validator did not reach a verdict: $(head -1 "$A_LOG" | cut -c1-80). Nothing here is established about the manifest."
  elif [ "$A" = "PASS" ]; then
    say "CB_STATUS=PASS"
  elif [ "$B" = "PASS" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=the shipped manifest is rejected and a copy without the hooks field is accepted, so that field is the only thing between this package and a valid one. Whether the runtime reads it is a separate question and is not answered here (CB-155)."
  else
    say "CB_STATUS=FAIL"
    say "CB_REASON=rejected with and without the hooks field, so that field is not the only problem: $(grep -c '^-' "$B_LOG" 2>/dev/null || echo '?') error(s) remain in the copy. $(sed -n '2p' "$B_LOG" | cut -c1-80)"
  fi
  ;;

skill|agent)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=credentials present but no session driver is implemented for this stage yet"
  ;;

hook)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=credentials present but no session driver is implemented for this stage yet"
  ;;

veto)
  needs_auth && exit 0
  # The stage that must never be faked. A refusal printed into a stream
  # nobody reads, while the tool call goes through underneath, would look
  # identical to a working guard from stderr alone. Whoever implements
  # the session driver: assert on the absence of the target file, not on
  # the presence of the message.
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=credentials present but no session driver is implemented; this stage must assert the target file was not written, never that a refusal was printed"
  ;;

finish)
  needs_auth && exit 0
  say "CB_STATUS=UNMEASURED"
  say "CB_REASON=credentials present but no session driver is implemented for this stage yet"
  ;;

*)
  say "CB_STATUS=UNSUPPORTED"
  say "CB_REASON=stage ${STAGE} is not part of the Codex sequence"
  ;;
esac
