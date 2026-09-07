#!/usr/bin/env bash
# DestructiveCommandHook: careful mode blocks irreversible ops; F-18 excludes inert data/quotes.
# F-19 allows its own flag delete. Limit: write-then-run across calls is not detected.

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
TRANSPARENT = {"sudo", "env", "nohup", "timeout", "nice", "ionice", "doas", "command", "exec"}

# Reinterpreters disable quote stripping; otherwise `psql -c "DROP TABLE"` bypasses.
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
            # Inspect the whole line: looking only left of `<<` let
            # `cat <<EOF | bash` bypass interpreter detection.
            if any(command_word(s) in INTERPRETERS for s in segments(line)):
                out.extend(body)
    return "\n".join(out)


def executable_text(text):
    """The part of the command the shell will run as command words."""
    stripped = strip_heredoc_bodies(text)
    runs_text = any(command_word(seg) in RUNNERS for seg in segments(stripped))
    if not runs_text:
        stripped = QUOTED.sub("''", stripped)
    return stripped


scan = executable_text(cmd)

# F-19: allow only a whole-command, single-operand delete of this hook's flag.
DISARM = re.compile(
    r"^\s*(?:sudo\s+)?rm\s+(?:-[a-zA-Z]+\s+)*(?:--\s+)?"
    r"['\"]?[^'\"\s;|&]*flags/careful['\"]?\s*$")
if DISARM.match(cmd):
    sys.exit(0)

operand = r"(?:\./)?(?:node_modules|dist|build|target|\.next|coverage)"
allow = [rf"rm\s+-rf?\s+{operand}(?:\s+{operand})*"]
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
for segment in (s.strip() for s in segments(scan)):
    if not segment or any(re.fullmatch(a, segment) for a in allow):
        continue
    for pat, label in patterns:
        if re.search(pat, segment, re.IGNORECASE):
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
