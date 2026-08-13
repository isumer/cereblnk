#!/usr/bin/env bash
# authprobe.sh — does the credential reach the host, and does the host
# accept it (CB-164).
#
# The smallest question that separates two things a single BLOCKED was
# blurring: a credential that never arrived, and a credential the
# provider refused. One is a repository configuration problem and the
# other is an account problem, and downstream stages are BLOCKED either
# way — but for reasons somebody would act on differently.
#
# It is also the prerequisite the session drivers sit behind. A driver
# that opens a session against an unauthenticated CLI produces a failure
# that looks like a capability finding and is not one.
#
# The invocation is discovered, not assumed. Each host's help output is
# read for a non-interactive flag, because guessing one and having it
# fail would be recorded as a host that cannot authenticate.
#
# Never prints the credential, never puts it on a command line, never
# writes it to the log it captures.

# cb_auth_probe <binary> <env-var-name> <workdir>
#
# Echoes one of:
#   ABSENT     no credential in the environment
#   NOFLAG     no non-interactive invocation found in the host's help
#   ACCEPTED   the host ran a trivial prompt without an auth error
#   REFUSED    the host reported an authentication or entitlement problem
#   UNKNOWN    it failed for a reason that is not about authentication
cb_auth_probe() {
  _bin="$1"; _var="$2"; _work="$3"
  eval "_val=\${$_var:-}"
  [ -n "$_val" ] || { printf 'ABSENT'; return 0; }
  command -v "$_bin" >/dev/null 2>&1 || { printf 'NOFLAG'; return 0; }

  _help="$_work/${_bin}-help.log"
  timeout 60 "$_bin" --help >"$_help" 2>&1 || true

  _flag=""
  for _cand in '--print' '-p' '--prompt' '--non-interactive'; do
    grep -qE -- "(^|[[:space:],])${_cand}([[:space:],=]|$)" "$_help" && _flag="$_cand" && break
  done
  [ -n "$_flag" ] || { printf 'NOFLAG'; return 0; }

  # Recorded so a later reader knows which invocation was tried. A probe
  # that says a host failed without saying how it was called has told
  # nobody anything.
  CB_AUTH_FLAG="$_flag"

  _out="$_work/${_bin}-auth.log"
  if timeout 120 "$_bin" "$_flag" 'Reply with the single word: ready' \
      >"$_out" 2>&1; then
    printf 'ACCEPTED'
    return 0
  fi

  # First non-empty line, flattened and bounded. The credential is never
  # on the command line and never in this output, but a provider's words
  # are still untrusted text on its way to a public comment.
  CB_AUTH_DETAIL="$(grep -v '^[[:space:]]*$' "$_out" 2>/dev/null | head -1 | tr -d '\r' | cut -c1-120)"

  # The provider's own words decide this, not the exit code. A refused
  # key, an exhausted quota and an unentitled account are all reasons to
  # stop, and none of them is a defect in this repository.
  if grep -qiE 'unauthor|authentic|invalid[_ -]?api|forbidden|401|403|quota|billing|rate.?limit|entitle|credit' "$_out" 2>/dev/null; then
    printf 'REFUSED'
  else
    printf 'UNKNOWN'
  fi
}

# cb_auth_report <result> <env-var-name>
#
# Turns a probe result into the stage vocabulary. Every path is BLOCKED
# or worse — authentication is a prerequisite, never a capability — but
# the reason is what somebody acts on.
cb_auth_report() {
  case "$1" in
    ACCEPTED) return 1 ;;  # caller continues to the real measurement
    ABSENT)
      say "CB_STATUS=BLOCKED"
      say "CB_REASON=no credential in the environment; set $2 as a repository secret" ;;
    NOFLAG)
      say "CB_STATUS=BLOCKED"
      say "CB_REASON=the host offers no non-interactive invocation this probe recognises (tried --print, -p, --prompt, --non-interactive), so a credential cannot be exercised from a runner" ;;
    REFUSED)
      say "CB_STATUS=BLOCKED"
      say "CB_REASON=the provider refused the credential or the account cannot run this — rejected key, exhausted quota, billing or entitlement. Not a defect in this package: ${CB_AUTH_DETAIL:-no detail}" ;;
    *)
      # The old message said only that it was not about authentication,
      # which is the one thing a reader already knew from the status. What
      # they need is which invocation was tried and what came back.
      say "CB_STATUS=UNMEASURED"
      say "CB_REASON=invoked with '${CB_AUTH_FLAG:-?}' and it failed for a reason that is not about authentication: ${CB_AUTH_DETAIL:-no output}. Nothing is established about the credential" ;;
  esac
  return 0
}
