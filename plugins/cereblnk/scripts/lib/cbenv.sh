#!/usr/bin/env bash
# Runtime helpers for scripts and hooks. Hooks must fail open without Python; user commands exit 2.
# WindowsApps Python aliases open the Store, so skip them and prefer the real `py` launcher.

_cb_is_stub() {
  case "$(command -v "$1" 2>/dev/null)" in
    *WindowsApps*) return 0 ;;   # Store alias stub — do not run it
    *)             return 1 ;;
  esac
}

case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT) _cb_cands="py python python3" ;;
  *)                               _cb_cands="python3 python py" ;;
esac

PYBIN=""
for _cb_c in $_cb_cands; do
  command -v "$_cb_c" >/dev/null 2>&1 || continue
  _cb_is_stub "$_cb_c" && continue
  PYBIN="$_cb_c"
  break
done
[ "$PYBIN" = "py" ] && PYBIN="py -3"
unset _cb_c _cb_cands

cb_require_python() {
  if [ -z "$PYBIN" ]; then
    echo "cereblnk: no usable Python 3 found (Store aliases are skipped)." >&2
    echo "cereblnk: install Python 3 from https://www.python.org and ensure it is on PATH." >&2
    exit 2
  fi
}

# Resolve from the host project, nearest cwd marker, or a safe new-project cwd.
# Never treat $HOME/.claude or a temporary directory as a project marker.
_cb_under() { case "$1" in "$2"|"$2"/*) return 0;; *) return 1;; esac; }
_cb_is_forbidden_root() {
  [ -n "${HOME:-}" ] && [ "$1" = "$HOME" ] && return 0
  # The Claude config tree is never a project, and the plugin's own installed
  # payload lives inside it. Without this, running a script with the cwd in
  # that payload took the "no marker found, use $PWD" branch and created
  # .claude/cereblnk/ under the plugin cache — runtime state written into the
  # install directory, which then asked for permission to delete.
  for _c in "${CLAUDE_CONFIG_DIR:-}" "${HOME:+$HOME/.claude}"; do
    [ -n "$_c" ] && _cb_under "$1" "${_c%/}" && return 0
  done
  for _t in "${TMPDIR:-}" "${TMP:-}" "${TEMP:-}" /tmp /var/tmp; do
    [ -n "$_t" ] && _cb_under "$1" "${_t%/}" && return 0
  done
  return 1
}
_cb_find_root() {
  d="$PWD"
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    if [ -n "${HOME:-}" ] && [ "$d" = "$HOME" ]; then return 1; fi
    if [ -e "$d/.git" ] || [ -d "$d/.claude" ]; then printf '%s' "$d"; return 0; fi
    d="$(dirname "$d")"
  done
  return 1
}
# F-01: hook-only CLAUDE_PROJECT_DIR split scripts and hooks across trees, silencing every floor.
# Prefer a nested marker within the session boundary; CB_ROOT_HINT exposes cases still ambiguous.
CB_ROOT_HINT=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  CB_ROOT="$CLAUDE_PROJECT_DIR"
  _cb_nested="$(_cb_find_root || true)"
  if [ -n "$_cb_nested" ] && [ "$_cb_nested" != "$CLAUDE_PROJECT_DIR" ] \
     && _cb_under "$_cb_nested" "${CLAUDE_PROJECT_DIR%/}"; then
    CB_ROOT="$_cb_nested"
    CB_ROOT_HINT="$CLAUDE_PROJECT_DIR"
  fi
  unset _cb_nested
else
  CB_ROOT="$(_cb_find_root || true)"
  if [ -z "$CB_ROOT" ] && ! _cb_is_forbidden_root "$PWD"; then
    CB_ROOT="$PWD"
    mkdir -p "$CB_ROOT/.claude" 2>/dev/null || CB_ROOT=""
  fi
  # Last resort uses $HOME rather than dropping work or littering a temporary cwd.
  if [ -z "$CB_ROOT" ] && [ -n "${HOME:-}" ]; then
    CB_ROOT="$HOME"
    mkdir -p "$CB_ROOT/.claude" 2>/dev/null || CB_ROOT=""
  fi
fi
CB_DIR="${CB_ROOT:+$CB_ROOT/.claude/cereblnk}"

# Runtime state once landed in commits; self-ignore instead of rewriting the user's .gitignore.
if [ -n "${CB_DIR:-}" ] && [ -d "$CB_DIR" ] && [ ! -f "$CB_DIR/.gitignore" ]; then
  printf '*\n' > "$CB_DIR/.gitignore" 2>/dev/null || true
fi

# Prints ARMED, COMPLETED, or IDLE; always exits 0 so hooks fail open.
# run-active wins if both sentinels exist; completed is never active.
cb_run_state() {
  if [ -n "${CB_DIR:-}" ] && [ -f "$CB_DIR/flags/run-active" ]; then
    printf 'ARMED\n'
  elif [ -n "${CB_DIR:-}" ] && [ -f "$CB_DIR/flags/run-completed" ]; then
    printf 'COMPLETED\n'
  else
    printf 'IDLE\n'
  fi
  return 0
}

# Prints a trailing-slash run directory or nothing and always exits 0 for nine hook callers.
# CB-147: carry and validate the flag pin; mtime guessing lost runs created during agent work.
cb_run_dir() {
  [ -n "${CB_DIR:-}" ] || return 0
  _cb_rd_pin=""
  if [ -f "$CB_DIR/flags/run-active" ]; then
    # first line only, whitespace stripped — the flag is also touched
    # empty by callers that arm without an id
    _cb_rd_pin="$(head -n 1 "$CB_DIR/flags/run-active" 2>/dev/null | tr -d ' \t\r\n')"
  fi
  case "$_cb_rd_pin" in
    "")                    ;;                     # armed without an id
    .*)                    _cb_rd_pin="" ;;       # "..", and dotfiles
    *[!A-Za-z0-9._-]*)     _cb_rd_pin="" ;;       # "/" and everything else
    *) [ -d "$CB_DIR/context/$_cb_rd_pin" ] || _cb_rd_pin="" ;;   # dead pin
  esac
  if [ -n "$_cb_rd_pin" ]; then
    printf '%s/context/%s/\n' "$CB_DIR" "$_cb_rd_pin"
    unset _cb_rd_pin
    return 0
  fi
  unset _cb_rd_pin
  # Fall back to mtime; `head` closes the pipe, so neutralize pipefail.
  ls -1dt "$CB_DIR"/context/*/ 2>/dev/null | head -n 1 || true
  return 0
}

export PYBIN CB_ROOT CB_DIR CB_ROOT_HINT
