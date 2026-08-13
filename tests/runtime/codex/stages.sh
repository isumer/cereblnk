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

# A stage that needs an authenticated session, on a runner with no
# credentials, is BLOCKED — not FAIL. A missing credential is a fact
# about the environment, and calling it a failure would blame this
# repository for the runner's configuration.
needs_auth() {
  if [ -z "${CODEX_API_KEY:-}${OPENAI_API_KEY:-}" ]; then
    say "CB_STATUS=BLOCKED"
    say "CB_REASON=no Codex credentials on this runner; authenticated stages need CODEX_API_KEY as a repository secret and run wherever it is present"
    return 0
  fi
  return 1
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
  # CB-151 measured this against the vendor's own validator and recorded
  # the result: the manifest carries a `hooks` field the validator's
  # allowlist does not include, while the same vendor's build guide
  # documents it. This stage re-runs that measurement when the validator
  # is available, and reports the standing finding when it is not. It
  # does not resolve the contradiction — CB-143 does.
  if [ -n "${CODEX_VALIDATOR:-}" ] && [ -f "${CODEX_VALIDATOR}" ]; then
    OUT="$WORK/validator.log"
    if python3 "$CODEX_VALIDATOR" "$ROOT/plugins/cereblnk" >"$OUT" 2>&1; then
      say "CB_STATUS=PASS"
      say "CB_EVIDENCE=validator.log"
    elif grep -q "Plugin validation" "$OUT" 2>/dev/null; then
      # The validator ran and reached a verdict. This is a fact about the
      # manifest.
      say "CB_STATUS=FAIL"
      say "CB_REASON=$(head -3 "$OUT" | tr '\n' ' ')"
      say "CB_EVIDENCE=validator.log"
    else
      # The validator did not reach a verdict — a missing import, a
      # Python it cannot run under, a file that is not what it claimed.
      # Both cases exit 1, and reading that as a rejected manifest would
      # blame this repository for the runner's environment. The whole
      # evidence layer rests on not doing that.
      say "CB_STATUS=UNMEASURED"
      say "CB_REASON=the vendor validator did not reach a verdict: $(head -1 "$OUT" | cut -c1-90). Nothing here is established about the manifest."
      say "CB_EVIDENCE=validator.log"
    fi
  else
    say "CB_STATUS=UNMEASURED"
    say "CB_REASON=CODEX_VALIDATOR not set; CB-151 measured this manifest as rejected for its hooks field, and that finding stands until re-measured"
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
