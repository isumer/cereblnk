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
  # This stage is named for what the host does with the package, so its
  # status has to come from that. It did not: the install was attempted,
  # its outcome was written down as an evidence line, and then the status
  # was set from check-generated — a local, host-free comparison that
  # scripts/verify already runs. A reader of a runtime table saw PASS and
  # read "the plugin works on this host", while the log beside it
  # recorded a refusal. The same concept already meant the stricter thing
  # on another host, so the vocabulary disagreed with itself too.
  #
  # Drift is still checked, and still first: a binding that no longer
  # matches its generator would install something the policy does not
  # describe, and that is a defect here rather than a question about the
  # host.
  if ! python3 "$ROOT/scripts/check-generated" >/dev/null 2>&1; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=the committed Claude binding differs from what gen-bindings produces, so the plugin would install something the policy does not describe"
    exit 0
  fi

  COUNT="$(python3 -c "
import json
d=json.load(open('$PLUGIN/hooks/hooks.json'))
print(sum(len(h['hooks']) for e in d['hooks'].values() for h in e))" 2>/dev/null)"
  say "CB_EVIDENCE=hooks.json matches its generator and binds ${COUNT:-?} hook(s)"

  if ! command -v claude >/dev/null 2>&1; then
    say "CB_STATUS=BLOCKED"
    say "CB_REASON=no CLI on PATH, so nothing could be installed. The binding is intact; whether this host accepts it is unmeasured"
    exit 0
  fi

  # The subcommand is discovered, not assumed. A CLI that does not offer
  # one tells us something; a guess that fails tells us nothing.
  HELP="$WORK/claude-plugin-help.log"
  if ! timeout 60 claude plugin --help >"$HELP" 2>&1; then
    say "CB_STATUS=UNSUPPORTED"
    say "CB_REASON=this CLI offers no plugin subcommand, so there is no host-native installation to measure"
    exit 0
  fi

  SUB=""
  for cand in install add; do
    grep -qE "^[[:space:]]*${cand}\\b" "$HELP" && SUB="$cand" && break
  done
  if [ -z "$SUB" ]; then
    say "CB_STATUS=UNSUPPORTED"
    say "CB_REASON=the plugin subcommand exists but offers neither install nor add, so there is no host-native installation to measure"
    exit 0
  fi

  # What the subcommand says it wants, quoted rather than pattern-matched.
  #
  # The previous attempt grepped for a usage line shaped the way this
  # probe imagined it, found nothing, and published an empty field —
  # which is the same mistake as guessing an invocation and reporting the
  # failure as the host's. The help output is already on disk; the honest
  # move is to carry a bounded excerpt of it and let a reader see the
  # contract, because a refusal cannot say whether the package or the
  # invocation is wrong and the host already wrote down which argument it
  # expects.
  USAGE="$(python3 - "$HELP" <<'EOF' 2>/dev/null
import re, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
lines = [l.strip() for l in raw.splitlines() if l.strip()]
# The lines that mention the subcommand, or failing that the opening of
# the help, so something true is recorded either way.
told = [l for l in lines if re.search(r"\b(install|add|marketplace|usage)\b",
                                      l, re.I)]
text = " / ".join((told or lines)[:6])
text = re.sub(r"[\x00-\x1f\x7f]", " ", text)
print(re.sub(r"\s+", " ", text).strip()[:400])
EOF
)"
  [ -n "$USAGE" ] && say "CB_EVIDENCE=install_contract=${USAGE}"

  # Identity comes from the marketplace, not from this script. The host
  # installs by name — `<plugin>` in its own usage, with `plugin@market`
  # for a specific one — and hard-coding either name here would make the
  # probe pass while the registry said something else.
  MPJSON="$ROOT/.claude-plugin/marketplace.json"
  MPNAME="$(python3 -c "import json;print(json.load(open('$MPJSON'))['name'])" 2>/dev/null)"
  PNAME="$(python3 -c "import json;print(json.load(open('$MPJSON'))['plugins'][0]['name'])" 2>/dev/null)"
  if [ -z "$MPNAME" ] || [ -z "$PNAME" ]; then
    say "CB_STATUS=FAIL"
    say "CB_REASON=the marketplace does not name itself and its first plugin, so there is no identity to install by"
    exit 0
  fi

  # The previous invocation handed a filesystem path where the host
  # documents a name, so it searched the marketplaces for a plugin called
  # /home/runner/... and truthfully reported not finding one. That was
  # recorded as FAIL — this package rejected — when nothing about the
  # package had been tested. Registration first, because a name can only
  # resolve through a marketplace the host knows about.
  MKT="$WORK/claude-marketplace.log"
  if grep -qE '^[[:space:]]*marketplace\b' "$HELP"; then
    if timeout 120 claude plugin marketplace add "$ROOT" >"$MKT" 2>&1; then
      say "CB_EVIDENCE=marketplace_add=ACCEPTED"
    else
      # Not fatal on its own: the host may already know this source, and
      # the install below is the measurement that matters.
      say "CB_EVIDENCE=marketplace_add=REFUSED: $(cb_detail "$MKT")"
    fi
  else
    say "CB_EVIDENCE=marketplace_add=UNSUPPORTED (no marketplace subcommand in this CLI)"
  fi

  INS="$WORK/claude-install.log"
  REF="${PNAME}@${MPNAME}"
  if timeout 180 claude plugin "$SUB" "$REF" >"$INS" 2>&1; then
    say "CB_STATUS=PASS"
    say "CB_EVIDENCE=install_result=ACCEPTED"
    say "CB_EVIDENCE=the host accepted ${REF} through its own plugin mechanism"
  else
    # The host's own words, not ours. A refusal of a correctly shaped
    # reference is about this package or this registry; the earlier
    # path-shaped refusal was about neither, and calling it FAIL blamed
    # the tree for the probe.
    say "CB_STATUS=FAIL"
    say "CB_EVIDENCE=install_result=REFUSED"
    say "CB_REASON=invoked as 'claude plugin ${SUB} ${REF}', which is the shape the host documents, and it refused: $(cb_detail "$INS"). The reference resolved through the registry or it did not; either way this is about the package or the marketplace, not the invocation"
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
