#!/usr/bin/env bash
# DestructiveCommandHook — opt-in via $CB_DIR/flags/careful
# Blocks (exit 2) irreversible shell ops so the user is asked first.
# Allowlisted: routine build-artifact cleanups, and the one delete that
# turns this hook off.
#
# F-18. The patterns below are matched against the COMMAND, never against
# the raw command string. The distinction is the same one
# delegation-guard.sh states in its own header — identity is read from
# parsed input, never by substring over the payload — arriving here as
# the mirror-image bug: a false POSITIVE instead of a bypass. Measured:
# a Bash call that only wrote a file,
#
#     cat >> notes.md <<'EOF'
#     ... prose about `rm -rf` and `git push --force` ...
#     EOF
#
# was BLOCKED, because the heredoc BODY — data the command writes, not
# a command the shell runs — contained the words. Consequence: with
# /cb-careful on, no documentation, test fixture, log or findings file
# that mentions a destructive operation can be written. A security
# project could not use this hook at all.
#
# So inert regions are removed before matching:
#   heredoc bodies  — data fed to the command, unless the command word
#                     consuming them is an interpreter (`bash <<EOF`),
#                     where the body IS code and is kept
#   quoted spans    — `git commit -m "rm -rf note"`, and only when the
#                     command contains no re-interpreting construct
#                     (eval, xargs, ssh, `sh -c`, `psql -c`, ...). Where
#                     a quoted span can become code or SQL, nothing is
#                     stripped and the raw text is scanned. Stripping
#                     there would have rebuilt the planted bypass.
# The command WORD and its flags are never quoted in practice, so
# blanking quoted CONTENT keeps `rm -rf "$HOME/x"` matching while
# `echo "rm -rf x"` stops matching.
#
# F-19. The block message used to prescribe an escape this same hook
# blocked: "remove <CB_DIR>/flags/careful" is a delete, and a forced
# delete matches the recursive/forced-delete pattern. A user who turned
# the protection on could not turn it off by the route they were given.
# Both halves are fixed: the message now names /cb-careful off and its
# mechanism, and a lone `rm` whose only operand is the careful flag is
# allowlisted, so the literal instruction also works.
#
# Honest limit, stated rather than implied: a command that WRITES a
# destructive script and a later command that RUNS it are two calls,
# and this hook sees one call at a time. Writing the file is now
# correctly allowed. `bash that-file` carries no pattern and has never
# been caught. This is accident prevention, not a sandbox — the same
# note hooks/README.md already makes about the edit boundary.
# shellcheck source=../../scripts/lib/cbenv.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh"
[ -n "$CB_DIR" ] || exit 0  # no project root resolved: never write outside the project
if [ -z "$PYBIN" ]; then
  echo "cereblnk hook: no usable Python 3 — check skipped (failing open, not blocking your edit). Install Python 3 to re-arm hooks." >&2
  exit 0
fi
[ -f "$CB_DIR/flags/careful" ] || exit 0
CEREBLNK_HOOK_INPUT="$(cat)"
CB_PLUGIN_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)"
export CEREBLNK_HOOK_INPUT CB_DIR CB_PLUGIN_SCRIPTS
$PYBIN << 'PY'
import json, os, re, sys
try:
    data = json.loads(os.environ.get("CEREBLNK_HOOK_INPUT") or "{}")
except json.JSONDecodeError:
    data = {}
cmd = (data.get("tool_input") or {}).get("command", "") or ""

INTERPRETERS = {
    "sh", "bash", "zsh", "ksh", "dash", "ash", "csh", "tcsh", "fish",
    "python", "python2", "python3", "perl", "ruby", "node", "php",
    "awk", "gawk", "sed", "psql", "mysql", "mariadb", "sqlite3",
    "mongo", "mongosh", "redis-cli", "clickhouse-client", "cockroach",
}
# Wrappers that pass the real command word through to their own tail.
TRANSPARENT = {"sudo", "env", "nohup", "timeout", "nice", "ionice", "doas", "command", "exec"}

# Words that hand their arguments back to a shell, an interpreter or a
# database. Their presence disables quote stripping entirely:
# conservative on purpose, because an over-eager strip is a bypass, and
# a bypass is worse than a false positive. `psql -c "DROP TABLE t"` must
# stay blocked even though the DROP sits inside quotes.
RUNNERS = INTERPRETERS | {"eval", "xargs", "ssh", "source", "watch", "find"}

HEREDOC = re.compile(r"<<-?\s*(?P<q>['\"]?)(?P<tag>[A-Za-z_][A-Za-z0-9_]*)(?P=q)")
QUOTED = re.compile(r"'[^']*'|\"(?:\\.|[^\"\\])*\"")


def segments(text):
    return re.split(r"\|\||&&|[;|&()\n]", text)


def command_word(prefix):
    """The command word of the last pipeline segment in `prefix`."""
    seg = segments(prefix)[-1]
    for tok in seg.split():
        base = os.path.basename(tok.strip("'\"")).lower()
        if "=" in tok and not tok.startswith("-"):
            continue          # VAR=value prefix
        if base in TRANSPARENT:
            continue
        return base
    return ""


def strip_heredoc_bodies(text):
    """Drop heredoc bodies — they are DATA the command writes or reads.
    Kept when the consuming command word is an interpreter, because then
    the body is a script and every pattern below must still see it."""
    lines, out, i = text.split("\n"), [], 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        tags = [(m.group("tag"), line[:m.start()]) for m in HEREDOC.finditer(line)]
        i += 1
        for tag, prefix in tags:
            body = []
            while i < len(lines) and lines[i].strip() != tag:
                body.append(lines[i])
                i += 1
            if i < len(lines):
                i += 1  # the terminator line
            # Scope is the whole LINE, not the text before `<<`.
            # `cat <<EOF | bash` reads as a harmless `cat` up to the
            # redirection and executes the body one token later —
            # measured as a bypass while this looked only leftward.
            if any(command_word(s) in INTERPRETERS for s in segments(line)):
                out.extend(body)
    return "\n".join(out)


def executable_text(text):
    """The part of the command the shell will run as command words."""
    stripped = strip_heredoc_bodies(text)
    runs_text = any(command_word(seg) in RUNNERS for seg in segments(stripped))
    if not runs_text:
        # Blank quoted CONTENT, keep the quotes so tokens stay adjacent.
        stripped = QUOTED.sub("''", stripped)
    return stripped


scan = executable_text(cmd)

# The one delete this hook must never block: turning itself off (F-19).
# Deliberately anchored to the WHOLE command and a single operand, so a
# chain cannot launder anything else through it.
DISARM = re.compile(
    r"^\s*(?:sudo\s+)?rm\s+(?:-[a-zA-Z]+\s+)*(?:--\s+)?"
    r"['\"]?[^'\"\s;|&]*flags/careful['\"]?\s*$")
if DISARM.match(cmd):
    sys.exit(0)

allow = [r"rm\s+-rf?\s+(\./)?(node_modules|dist|build|target|\.next|coverage)(\s|$)"]
if any(re.search(a, scan) for a in allow):
    sys.exit(0)
patterns = [
    (r"rm\s+(-\w*\s+)*-\w*[rf]\w*[rf]?\w*\s", "recursive/forced delete"),
    (r"git\s+push\s+.*(--force|-f)(\s|$)", "force push"),
    (r"git\s+reset\s+--hard", "hard reset"),
    (r"git\s+clean\s+-\w*f", "git clean -f"),
    (r"\bdrop\s+(table|database|schema)\b", "SQL DROP"),
    (r"\btruncate\s+table\b", "SQL TRUNCATE"),
    (r"docker\s+(compose|-c)?.*\bdown\b.*(-v|--volumes)", "compose down with volume removal"),
    (r"docker\s+volume\s+(rm|prune)", "docker volume delete"),
    (r"docker\s+system\s+prune", "docker system prune"),
    (r"docker\s+(rm|rmi)\s+(-\w*\s+)*-\w*f", "forced docker remove"),
    (r"mkfs|dd\s+if=", "disk-level write"),
]
cb = os.environ.get("CB_DIR", ".claude/cereblnk")
runflag = os.path.join(os.environ.get("CB_PLUGIN_SCRIPTS", "<plugin>/scripts"), "run-flag")
for pat, label in patterns:
    if re.search(pat, scan, re.IGNORECASE):
        print(
            f"Cereblnk DestructiveCommandHook: blocked irreversible operation ({label}). "
            f"Ask the user for explicit confirmation before running it.\n"
            f"TO TURN THIS OFF: /cb-careful off — which runs "
            f"`{runflag} flag careful disarm`. "
            f"That command is not a delete and this hook never sees it.\n"
            f"By hand, `rm -f {cb}/flags/careful` on its own is allowlisted here and "
            f"also works; the same delete chained to anything else is not.",
            file=sys.stderr)
        sys.exit(2)
sys.exit(0)
PY
exit $?
