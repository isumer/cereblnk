#!/usr/bin/env bash
# authprobe.sh — which provider, does the credential reach it, and does
# it accept (CB-164, extended by CB-168).
#
# The smallest question that separates things a single BLOCKED was
# blurring: a credential that never arrived, a credential the provider
# refused, and a provider mapping this repository built wrong. The first
# two are account problems and the third is ours, and they are acted on
# differently.
#
# CB-168 added the provider dimension. A host is not the same thing as
# the service that answers it: Claude Code speaks its native protocol to
# whatever ANTHROPIC_BASE_URL names, so the same CLI can be backed by
# Anthropic directly or by a gateway. Evidence that says only "claude"
# cannot distinguish the two, and a run that proves a gateway works has
# not proven direct provider billing works.
#
# The earlier presence test was `[ -n "$ANTHROPIC_API_KEY" ]`. Under the
# gateway path that variable must be explicitly empty, so the test read a
# correct configuration as a missing credential — a repository problem
# reported where an account problem belongs.
#
# The invocation is discovered, not assumed. Each host's help output is
# read for a non-interactive flag, because guessing one and having it
# fail would be recorded as a host that cannot authenticate.
#
# Never prints the credential, never puts it on a command line, never
# writes it to the log it captures.

# Where a probe result is cached for the rest of the run. Each downstream
# stage asks whether authentication holds, and on a metered free tier
# every ask is a billable request against a daily request cap rather than
# a token budget. Six stages asking separately turned one question into
# six, so the answer is taken once and reused.
_cb_cache() { printf '%s/authprobe-%s.state' "$1" "$2"; }

# cb_claude_provider
#
# Echoes the inference provider behind Claude Code: openrouter, anthropic
# or none.
#
# Explicit configuration wins over inference. Reading the answer off
# whichever variable happens to be populated is how a job that set two
# things by accident gets described as the one it did not mean.
cb_claude_provider() {
  if [ -n "${CEREBLNK_CLAUDE_PROVIDER:-}" ]; then
    printf '%s' "$CEREBLNK_CLAUDE_PROVIDER"
    return 0
  fi
  if [ -n "${OPENROUTER_API_KEY:-}" ]; then printf 'openrouter'; return 0; fi
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then printf 'anthropic'; return 0; fi
  printf 'none'
}

# cb_provider_credential_var <provider>
#
# The environment variable that holds the credential for a provider. The
# variable Claude Code is handed is not always the variable the operator
# set: a gateway credential arrives as OPENROUTER_API_KEY and is mapped
# to ANTHROPIC_AUTH_TOKEN for the CLI. This names the source, because
# that is what an operator would go and fix.
cb_provider_credential_var() {
  case "$1" in
    openrouter) printf 'OPENROUTER_API_KEY' ;;
    anthropic)  printf 'ANTHROPIC_API_KEY' ;;
    *)          printf '' ;;
  esac
}

# cb_provider_misconfigured <provider>
#
# Exits 0 when this repository built the provider mapping wrong, and
# echoes what is wrong with it. This is the one authentication outcome
# that is a defect here rather than an account problem, so it is
# separated before any request is made — asking a misconfigured endpoint
# produces a rejection that reads like a bad key.
cb_provider_misconfigured() {
  case "$1" in
    openrouter)
      if [ -z "${ANTHROPIC_BASE_URL:-}" ]; then
        printf 'the gateway provider was selected but ANTHROPIC_BASE_URL is unset, so the CLI would call the direct provider'
        return 0
      fi
      case "${ANTHROPIC_BASE_URL}" in
        https://openrouter.ai/api*) ;;
        *)
          printf 'the gateway provider was selected but ANTHROPIC_BASE_URL does not name the gateway endpoint'
          return 0 ;;
      esac
      if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]; then
        printf 'the gateway credential was not mapped to ANTHROPIC_AUTH_TOKEN, which is the variable the CLI sends as a bearer token'
        return 0
      fi
      if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        printf 'ANTHROPIC_API_KEY is non-empty on the gateway path, so the CLI may authenticate against the direct provider while this run reports the gateway'
        return 0
      fi
      ;;
    anthropic)
      if [ -n "${ANTHROPIC_BASE_URL:-}" ]; then
        case "${ANTHROPIC_BASE_URL}" in
          https://api.anthropic.com*) ;;
          *)
            printf 'the direct provider was selected but ANTHROPIC_BASE_URL redirects the CLI elsewhere'
            return 0 ;;
        esac
      fi
      ;;
  esac
  return 1
}

# cb_detail <logfile>
#
# Echoes the most specific thing a host said, collapsed and bounded.
#
# Two probes needed this reading and only one had it. The auth probe
# learned to prefer a structured field and to skip a wrapper line like
# "Execution error"; the plugin stage still took the first line and cut
# it, so a refusal reached the reader as `Installing plugin ...Failed
# to` — the announcement, with the cause sliced off, in the one field
# a reader had to work from. Two implementations of one judgement
# drift, and the one that drifts is the one nobody is looking at.
cb_detail() {
  python3 - "$1" <<'EOF' 2>/dev/null
import json, re, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()

# Structured first: the field the host filled in beats any line of prose.
try:
    doc = json.loads(raw)
except ValueError:
    doc = None
best = ""
if isinstance(doc, dict):
    for key in ("error", "result", "message", "detail"):
        val = doc.get(key)
        if isinstance(val, dict):
            val = val.get("message") or val.get("type") or ""
        if isinstance(val, str) and val.strip():
            best = val.strip()
            break

if not best:
    lines = [l.strip() for l in raw.splitlines() if l.strip()]
    # A line that names a cause outranks a line that announces a failure.
    told = [l for l in lines
            if re.search(r"\b(model|not.?found|unsupport|invalid|refus|"
                         r"denied|expired|exceed|4\d\d|5\d\d)\b", l, re.I)]
    best = (told or lines or [""])[0]

# Collapsed and bounded. This is a provider's own words on their way to
# a public comment, and a control character or a table row would be
# carried straight through.
best = re.sub(r"[\x00-\x1f\x7f]", " ", best)
best = re.sub(r"[|`]", " ", best)
# 200 cut the first real refusal mid-filesystem-path, before the
# sentence that named the cause. The renderer bounds this again at
# its own limit, so the tighter number here was buying nothing and
# costing the finding.
print(re.sub(r"\s+", " ", best).strip()[:400])
EOF
}

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
  _state="$(_cb_cache "$_work" "$_bin")"

  # A cached answer carries the flag and detail with it. Returning the
  # verdict alone would leave a later stage reporting a refusal it could
  # not describe.
  if [ -f "$_state" ]; then
    # shellcheck disable=SC1090
    . "$_state"
    printf '%s' "${CB_AUTH_RESULT:-UNKNOWN}"
    return 0
  fi

  eval "_val=\${$_var:-}"
  [ -n "$_val" ] || { _cb_remember "$_state" ABSENT; printf 'ABSENT'; return 0; }
  command -v "$_bin" >/dev/null 2>&1 || {
    _cb_remember "$_state" NOFLAG; printf 'NOFLAG'; return 0; }

  _help="$_work/${_bin}-help.log"
  timeout 60 "$_bin" --help >"$_help" 2>&1 || true

  _flag=""
  for _cand in '--print' '-p' '--prompt' '--non-interactive'; do
    grep -qE -- "(^|[[:space:],])${_cand}([[:space:],=]|$)" "$_help" && _flag="$_cand" && break
  done
  [ -n "$_flag" ] || { _cb_remember "$_state" NOFLAG; printf 'NOFLAG'; return 0; }

  # Recorded so a later reader knows which invocation was tried. A probe
  # that says a host failed without saying how it was called has told
  # nobody anything.
  CB_AUTH_FLAG="$_flag"

  # Structured output where the host offers it. Claude Code collapses
  # every provider failure to "Execution error" on the human-readable
  # path, which is what two runs across two different models both
  # reported — the same six words for a model incompatibility, a
  # rejected key and a protocol mismatch alike. The machine-readable
  # form carries the cause. This is asked for rather than assumed, and
  # it costs no extra request: the same single call, told to answer in
  # a form that says more.
  #
  # A verbose or debug flag would say more still, and would also print
  # request headers into a log whose first lines are quoted into a
  # public comment. That trade is not taken.
  _fmt=""
  grep -qE -- '(^|[[:space:],])--output-format([[:space:],=]|$)' "$_help" \
    && grep -qi 'json' "$_help" && _fmt="--output-format json"

  _out="$_work/${_bin}-auth.log"
  _start="$(date +%s 2>/dev/null || echo 0)"
  # Captured from the command, not from the `if`. An `if` whose condition
  # fails and has no else exits 0, so reading $? after the block reports
  # success for the failure being handled — the same masking this
  # repository already refuses to accept from a pipe.
  # shellcheck disable=SC2086
  # A real host is given two minutes. The deterministic suite exercises
  # the timeout path against a stand-in that hangs on purpose, and would
  # otherwise wait out that whole budget on every run — a suite slow
  # enough to skip is a suite that stops being run.
  _limit="${CB_AUTH_TIMEOUT:-120}"
  timeout "$_limit" "$_bin" "$_flag" $_fmt 'Reply with the single word: ready' \
      >"$_out" 2>&1
  _code=$?
  if [ "$_code" -eq 0 ]; then
    _cb_remember "$_state" ACCEPTED
    printf 'ACCEPTED'
    return 0
  fi
  _elapsed=$(( $(date +%s 2>/dev/null || echo 0) - _start ))

  # A timeout and a refusal are different findings and exit 124 is the
  # only thing that separates them. Recorded before the log is read,
  # because a run that was killed at the wall has no message to quote.
  if [ "$_code" -eq 124 ]; then
    CB_AUTH_DETAIL="no response within ${_limit}s (killed at the timeout, exit 124)"
    _cb_remember "$_state" UNKNOWN
    printf 'UNKNOWN'
    return 0
  fi

  # First non-empty line, flattened and bounded. The credential is never
  # on the command line and never in this output, but a provider's words
  # are still untrusted text on its way to a public comment.
  # The most specific thing the host said, not merely the first thing.
  # A wrapper line like "Execution error" arrives before the cause and
  # was all that ever reached a reader.
  CB_AUTH_DETAIL="$(cb_detail "$_out")"
  [ -n "$CB_AUTH_DETAIL" ] || CB_AUTH_DETAIL="exit ${_code} after ${_elapsed}s with no output"

  # The provider's own words decide this, not the exit code. A refused
  # key, an exhausted quota and an unentitled account are all reasons to
  # stop, and none of them is a defect in this repository.
  if grep -qiE 'unauthor|authentic|invalid[_ -]?api|forbidden|401|403|quota|billing|rate.?limit|entitle|credit' "$_out" 2>/dev/null; then
    _cb_remember "$_state" REFUSED
    printf 'REFUSED'
  else
    _cb_remember "$_state" UNKNOWN
    printf 'UNKNOWN'
  fi
}

# Writes the verdict and its context where the next stage can read it.
# Quoting is deliberate: the detail is a provider's own words and will be
# sourced back as shell.
_cb_remember() {
  _f="$1"; _r="$2"
  {
    printf 'CB_AUTH_RESULT=%s\n' "$_r"
    printf "CB_AUTH_FLAG='%s'\n" "$(printf '%s' "${CB_AUTH_FLAG:-}" | sed "s/'/'\\\\''/g")"
    printf "CB_AUTH_DETAIL='%s'\n" "$(printf '%s' "${CB_AUTH_DETAIL:-}" | sed "s/'/'\\\\''/g")"
  } >"$_f" 2>/dev/null || true
}

# cb_auth_recall <workdir> <binary>
#
# Loads the flag and the detail the probe recorded into the caller's
# shell.
#
# The probe is called as `$(cb_auth_probe ...)` because it echoes its
# verdict, and a command substitution is a subshell: every variable it
# set died with it. The verdict survived — it was the thing being echoed
# — so the callers looked correct and reported `invoked with '?'` and
# `no output` on every run, for months, including in the evidence that
# was supposed to explain a failure. Only the sentence was wrong, which
# is why nothing caught it.
#
# The state file is what crosses the boundary. Reading it back in the
# caller is what makes the reason true.
cb_auth_recall() {
  _rstate="$(_cb_cache "$1" "$2")"
  if [ -f "$_rstate" ]; then
    # shellcheck disable=SC1090
    . "$_rstate"
  fi
}

# cb_auth_report <r> <env-var-name>
#
# Turns a probe result into the stage vocabulary for a stage that needed
# authentication and did not get it. Every path is BLOCKED or worse —
# authentication is a prerequisite, never a capability — but the reason
# is what somebody acts on.
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
      say "CB_STATUS=UNMEASURED"
      say "CB_REASON=invoked with '${CB_AUTH_FLAG:-?}' and it failed for a reason that is not about authentication: ${CB_AUTH_DETAIL:-no output}. Nothing is established about the credential" ;;
  esac
  return 0
}

# cb_auth_stage <binary> <provider> <credential-var> <workdir>
#
# The auth stage itself (CB-168). Downstream stages ask whether
# authentication holds; this one reports what authentication did, as its
# own row, using the same five statuses as every other stage.
#
# PASS means a real request completed. A credential that is merely
# present is not a PASS — that was the ambiguity this stage exists to
# remove.
cb_auth_stage() {
  _sbin="$1"; _sprov="$2"; _svar="$3"; _swork="$4"

  if [ "$_sprov" = "none" ]; then
    say "CB_STATUS=BLOCKED"
    say "CB_REASON=no inference provider is configured for this host, so no authenticated stage can run"
    return 0
  fi

  say "CB_EVIDENCE=inference_provider=${_sprov}"
  [ -n "${CEREBLNK_CLAUDE_RUNTIME_MODEL:-}" ] && \
    say "CB_EVIDENCE=configured_model=${CEREBLNK_CLAUDE_RUNTIME_MODEL}"

  # Ours before theirs. A mapping this repository built wrong produces a
  # provider rejection that is indistinguishable from a bad key, and
  # would be filed against the account rather than against the code.
  if _why="$(cb_provider_misconfigured "$_sprov")"; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=provider configuration built by this repository is wrong: ${_why}"
    return 0
  fi

  _r="$(cb_auth_probe "$_sbin" "$_svar" "$_swork")"
  cb_auth_recall "$_swork" "$_sbin"
  case "$_r" in
    ACCEPTED)
      say "CB_STATUS=PASS"
      say "CB_EVIDENCE=minimal non-interactive inference completed through ${_sprov}" ;;
    ABSENT)
      say "CB_STATUS=BLOCKED"
      say "CB_REASON=no credential in the environment; set ${_svar} as a repository secret" ;;
    NOFLAG)
      say "CB_STATUS=BLOCKED"
      say "CB_REASON=the host offers no non-interactive invocation this probe recognises, so a credential cannot be exercised from a runner" ;;
    REFUSED)
      say "CB_STATUS=BLOCKED"
      say "CB_REASON=${_sprov} refused the credential or the account cannot run this — rejected key, exhausted quota, rate limit, billing or entitlement. Not a defect in this package: ${CB_AUTH_DETAIL:-no detail}" ;;
    *)
      say "CB_STATUS=UNMEASURED"
      say "CB_REASON=invoked with '${CB_AUTH_FLAG:-?}' and it failed for a reason that is not about authentication: ${CB_AUTH_DETAIL:-no output}. Nothing is established about the credential" ;;
  esac
}
