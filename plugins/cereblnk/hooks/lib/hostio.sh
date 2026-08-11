#!/usr/bin/env bash
# hostio.sh — the refusal, expressed once (CB-128).
#
# A hook decides whether to refuse. How that refusal is *spoken* belongs
# to the host, not to the hook, and until now it was spelled out at every
# site: Claude Code reads a refused tool call as exit 2 with the reason on
# stderr, and a refused turn as a decision object on stdout. A second host
# reads neither. Thirteen copies of that difference would be thirteen
# places to get a port wrong.
#
# Nothing here decides anything. If this file starts growing conditions
# about paths, agents or run state, the decision has leaked out of the
# hook and into the adapter, and that is the bug to look for.
#
#   cb_block <message>      refuse a tool call or a subagent stop
#   cb_block_turn <reason>  refuse the end of a turn
#
# Both exit. Neither returns.
#
# CB_HOST selects the form and defaults to claude. An unknown value takes
# the Claude form rather than failing: a hook that cannot speak is a hook
# that cannot refuse, and silently dropping a refusal is worse than
# speaking it in the wrong dialect.

# JSON string escaping, enough for the reasons hooks actually emit:
# backslash and double quote escaped, newlines folded.
cb__json_escape() {
  printf '%s' "$1" \
    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
    | tr '\n' ' '
}

cb_block() {
  case "${CB_HOST:-claude}" in
    cursor)
      printf '{"continue":false,"permission":"deny","agentMessage":"%s"}\n' \
        "$(cb__json_escape "$1")"
      exit 0
      ;;
    codex)
      printf '{"decision":"block","reason":"%s"}\n' \
        "$(cb__json_escape "$1")"
      exit 0
      ;;
    *)
      printf '%s\n' "$1" >&2
      exit 2
      ;;
  esac
}

cb_block_turn() {
  case "${CB_HOST:-claude}" in
    cursor)
      printf '{"continue":false,"permission":"deny","agentMessage":"%s"}\n' \
        "$(cb__json_escape "$1")"
      exit 0
      ;;
    *)
      # Claude Code refuses a turn on stdout, not through the exit code.
      printf '{"decision":"block","reason":"%s"}\n' "$1"
      exit 0
      ;;
  esac
}
