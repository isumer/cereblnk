#!/usr/bin/env bash
# cereblnk shell runtime helpers. Sourced by scripts/ and hooks/scripts/.
#
#   PYBIN   — resolved Python 3 interpreter ("" if none usable).
#   CB_DIR  — this project's Cereblnk runtime state directory.
#   cb_require_python — call in USER-INVOKED scripts to hard-fail
#                       (exit 2) when PYBIN is empty. Hooks must NOT
#                       call it: a hook that exits non-zero BLOCKS the
#                       tool call, so a missing interpreter would brick
#                       every Write/Edit. Hooks fail OPEN with a
#                       warning instead.
#
# Windows notes:
# - Windows ships App Execution Aliases for python.exe/python3.exe that
#   are Store stubs: they ARE on PATH (so `command -v` finds them) and
#   running one opens the Microsoft Store instead of executing code.
#   Stubs live under ...\Microsoft\WindowsApps\ — we detect that path
#   and skip them WITHOUT running them.
# - Candidate order tries `py` (the real launcher) first on Windows.

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

# Runtime state is anchored to the project. Resolution order:
#   1. CLAUDE_PROJECT_DIR (set by Claude Code for hooks)
#   2. walk up from $PWD to the nearest dir containing .git or .claude —
#      but NEVER selecting $HOME or anything above it ($HOME/.claude is
#      Claude Code's own config dir, not a project marker)
#   3. fall back to $PWD itself and CREATE .claude/ there — so a brand
#      new project without .git just works — EXCEPT when $PWD is a temp
#      location or $HOME itself: there CB_ROOT stays empty and callers
#      skip writes (hooks spawned with a temp cwd must not litter).
_cb_under() { case "$1" in "$2"|"$2"/*) return 0;; *) return 1;; esac; }
_cb_is_forbidden_root() {
  [ -n "${HOME:-}" ] && [ "$1" = "$HOME" ] && return 0
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
# F-01: CLAUDE_PROJECT_DIR won unconditionally, and only hooks receive
# it. A script run by an agent walked up from $PWD instead, so in a
# session opened ABOVE the project the two answers differed:
#
#   scripts (cwd inside the project)  -> <workspace>/cb-testbed/.claude/cereblnk
#   hooks   (CLAUDE_PROJECT_DIR)      -> <workspace>/.claude/cereblnk
#
# select-agents writes the skill baseline under one; skill-floor looks
# for it under the other, does not find it, and exits 0. Every floor
# reads the run directory the same way, so the whole enforcement layer
# went quiet — not weakened, absent, with nothing saying so. The same
# split disabled /cb-careful and /cb-boundary, which reported
# themselves as enabled while writing to a tree no hook reads.
#
# Resolution: prefer the nearest project marker at or below
# CLAUDE_PROJECT_DIR. A nested project is more specific than the
# session directory and is what both sides mean by "this project";
# when the walk finds nothing under it, CLAUDE_PROJECT_DIR stands. A
# marker OUTSIDE it is ignored — the session boundary is still a
# boundary.
#
# It cannot converge every case: a hook whose cwd is the session root
# and a script whose cwd is the nested project will still disagree.
# CB_ROOT_HINT records the other candidate so callers can say so
# instead of failing open in silence.
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
  # Absolute last resort: cwd is temp (or $HOME itself) and no project
  # anywhere — better to function under $HOME than to drop work or
  # litter temp. Project locations always win when they exist.
  if [ -z "$CB_ROOT" ] && [ -n "${HOME:-}" ]; then
    CB_ROOT="$HOME"
    mkdir -p "$CB_ROOT/.claude" 2>/dev/null || CB_ROOT=""
  fi
fi
CB_DIR="${CB_ROOT:+$CB_ROOT/.claude/cereblnk}"

# Runtime state is not source. It was landing in commits because nothing
# ever said otherwise — the plugin creates this directory inside the
# user's repository and never asked git to leave it alone.
#
# A self-ignoring directory rather than an edit to the user's
# .gitignore: their file is theirs, and a plugin that rewrites it earns
# a merge conflict in someone else's repo. `*` also ignores this file,
# so the directory disappears from git entirely.
if [ -n "${CB_DIR:-}" ] && [ -d "$CB_DIR" ] && [ ! -f "$CB_DIR/.gitignore" ]; then
  printf '*\n' > "$CB_DIR/.gitignore" 2>/dev/null || true
fi
export PYBIN CB_ROOT CB_DIR CB_ROOT_HINT
