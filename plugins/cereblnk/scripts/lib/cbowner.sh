#!/usr/bin/env bash
# CB-122: shared conductor-ownership table; duplicate edit/shell copies drifted.
# Control state is conductor-owned, except specialist blocks/memory and the human override.
cb_is_repo_source() {
  [ -n "${1:-}" ] && [ -n "${CB_ROOT:-}" ] && [ -n "${PYBIN:-}" ] || return 1
  CB_CANDIDATE_PATH="$1" CB_SOURCE_ROOT="$CB_ROOT" $PYBIN -c '
import os, pathlib, sys
try:
    root = pathlib.Path(os.environ["CB_SOURCE_ROOT"]).resolve()
    raw = pathlib.Path(os.environ["CB_CANDIDATE_PATH"])
    target = (raw if raw.is_absolute() else pathlib.Path.cwd() / raw).resolve()
    target.relative_to(root)
    target.relative_to(root / ".claude")
except ValueError:
    try:
        target.relative_to(root)
    except (ValueError, UnboundLocalError):
        sys.exit(1)
    sys.exit(0)
except Exception:
    sys.exit(1)
sys.exit(1)
' >/dev/null 2>&1
}

cb_is_conductor_owned() {
  [ -n "${1:-}" ] || return 1
  _n="$(printf '%s' "$1" | tr '\\' '/')"
  case "$_n" in
    # Refuse the human override before the broader flags grant.
    .claude/cereblnk/flags/conductor-override*|*/cereblnk/flags/conductor-override*) return 1 ;;
    .claude/cereblnk/context/*/skills-required.yaml|*/cereblnk/context/*/skills-required.yaml) return 0 ;;
    # Response Blocks and authored memory remain specialist-owned under .claude/.
    .claude/cereblnk/context/*/*.yaml|*/cereblnk/context/*/*.yaml) return 1 ;;
    .claude/cereblnk/memory/*|*/cereblnk/memory/*) return 1 ;;
    # Specialist refusals precede the broad control-surface grant.
    .claude/*|*/.claude/*)                return 0 ;;
    */cereblnk/context/*/[Pp]lan.md)      return 0 ;;
    */cereblnk/state.md)                  return 0 ;;
    # F-06: run journals are conductor-held verdicts with no specialist owner.
    # Limit this grant to run context; authored memory remains specialist-owned.
    */cereblnk/context/*/*.md)            return 0 ;;
    */cereblnk/flags/*)                   return 0 ;;
    */cereblnk/telemetry/*)               return 0 ;;
  esac
  return 1
}
