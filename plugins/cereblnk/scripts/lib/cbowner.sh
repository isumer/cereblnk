#!/usr/bin/env bash
# cbowner — the conductor-ownership table, in one place.
#
# Which runtime files the conducting conversation may write is a policy
# question, answered by run-discipline §1/§2 and agent-selection-policy
# §3. It is asked from more than one place now: the edit tools reach
# these paths through Write/Edit, and the shell reaches them through a
# redirection. Two copies of a policy table drift, and CB-122 was
# exactly that drift — the table disagreed with the policy in both
# directions at once. So there is one table, and both callers source it.
#
# Exempt, because the conductor writes these BY DEFINITION:
#   $CB_DIR/state.md                  run state
#   $CB_DIR/context/<run>/plan.md     the plan
#   $CB_DIR/context/<run>/skills-required.yaml
#                                     the selector's output, copied
#                                     verbatim by the orchestrator
#                                     (agent-selection-policy §3)
#   $CB_DIR/flags/*                   run lifecycle flags
#   $CB_DIR/telemetry/*               run summaries
#
# NOT exempt, and deliberately so:
#   $CB_DIR/context/<run>/<task>.yaml a subagent's Response Block — a
#                                     conductor writing one is
#                                     fabricating a specialist's output
#   $CB_DIR/memory/**                 promoted knowledge and authored
#                                     deliverables have their own owners
#   $CB_DIR/flags/conductor-override  the human escape hatch — the one
#                                     flag the conductor does not own
#
# conductor-override is carved out of the flags exemption, and the
# carve-out is the whole point. The hatch was designed to cost "an
# explicit act by the person": its name is kept out of every
# model-facing message on purpose, because a blocked model reads the
# last sentence of a block as an instruction. But secrecy is not a
# mechanism. Blocked from writing a Response Block, a run reached for
# the hatch itself and the flags exemption granted it; only
# ScratchGuard happened to be in the way, and ScratchGuard nudges
# twice and then allows. A guard that permits arming its own bypass
# enforces nothing it claims to. The person writes this file, or it
# does not exist.
#
# Separators are normalised: the path arrives as the platform wrote it,
# and on Windows that means backslashes.
cb_is_conductor_owned() {
  [ -n "${1:-}" ] || return 1
  _n="$(printf '%s' "$1" | tr '\\' '/')"
  case "$_n" in
    # first match wins: the hatch is refused before flags/* grants it
    */cereblnk/flags/conductor-override*) return 1 ;;
    */cereblnk/context/*/[Pp]lan.md)      return 0 ;;
    */cereblnk/context/*/skills-required.yaml) return 0 ;;
    */cereblnk/state.md)                  return 0 ;;
    */cereblnk/flags/*)                   return 0 ;;
    */cereblnk/telemetry/*)               return 0 ;;
  esac
  return 1
}
