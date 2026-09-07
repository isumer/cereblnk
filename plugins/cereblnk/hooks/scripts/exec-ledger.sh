#!/usr/bin/env bash
# ExecLedgerHook records per-surface edit/exec evidence for ExecFloorHook (CB-113).
# Observation only; it never blocks.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0

LIBDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib"

INPUT="$(cat 2>/dev/null || true)"
printf '%s' "$INPUT" | CB_RUN="$RUN" CB_LIB="$LIBDIR" CB_CFG="$CB_DIR/config" $PYBIN -c '
import json, os, pathlib, re, shlex, sys, time

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

agent = d.get("agent_type") or d.get("agent_id") or "main"
tool = (d.get("tool_name") or "").strip()
ti = d.get("tool_input") or {}
run = pathlib.Path(os.environ["CB_RUN"])


def record(kind, surface):
    try:
        with (run / "exec.log").open("a", encoding="utf-8") as fh:
            fh.write("%d\t%s\t%s\t%s\n" % (int(time.time()), agent, kind, surface))
    except OSError:
        pass


def record_path(path):
    """Paths go to their own ledger. exec.log carries surfaces and
    ReachFloorHook needs files; two readers, two shapes, no field that
    means different things to each."""
    try:
        with (run / "edited-files.log").open("a", encoding="utf-8") as fh:
            fh.write("%d\t%s\t%s\n" % (int(time.time()), agent, path))
    except OSError:
        pass


sys.path.insert(0, os.environ["CB_LIB"])
try:
    import surfaces as _surfaces
except Exception:
    _surfaces = None

_SMAP = _surfaces.load() if _surfaces else {}
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
OPERATORS = re.compile(r"^[|&;()\n]+$")
TRANSPARENT = {"sudo", "env", "nohup", "timeout", "nice", "command", "exec"}
OPTION_VALUES = {
    "sudo": {"-C", "--close-from", "-g", "--group", "-h", "--host", "-p",
             "--prompt", "-r", "--role", "-t", "--type", "-T",
             "--command-timeout", "-u", "--user"},
    "env": {"-C", "--chdir", "-S", "--split-string", "-u", "--unset"},
    "timeout": {"-k", "--kill-after", "-s", "--signal"},
    "nice": {"-n", "--adjustment"},
    "exec": {"-a"},
}


def surface_of(path):
    return _surfaces.surface_of(path, _SMAP) if _surfaces else ""


def command_segments(command):
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars="|&;()\n")
        lexer.whitespace = " \t\r"
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return []
    result, current = [], []
    for token in tokens:
        if OPERATORS.fullmatch(token):
            if current:
                result.append(current)
                current = []
        else:
            current.append(token)
    if current:
        result.append(current)
    return result


def executable_segment(words):
    words = list(words)
    while words:
        if ASSIGNMENT.match(words[0]):
            words.pop(0)
            continue
        wrapper = os.path.basename(words[0])
        if wrapper not in TRANSPARENT:
            break
        words.pop(0)
        while words and words[0].startswith("-"):
            option = words.pop(0)
            name = option.split("=", 1)[0]
            if name in OPTION_VALUES.get(wrapper, set()) and "=" not in option and words:
                words.pop(0)
        if wrapper == "timeout" and words:
            words.pop(0)
    return " ".join(words)


def failed_result(payload):
    # Claude PostToolUse puts the Bash result in tool_response; absent status stays fail-open.
    if "tool_response" not in payload:
        return False
    response = payload["tool_response"]
    if isinstance(response, str):
        match = re.match(r"\s*(?:Error:\s*)?Exit code\s+(-?\d+)\b", response, re.I)
        if match:
            return int(match.group(1)) != 0
        return response.lstrip().lower().startswith("error:")
    if not isinstance(response, dict):
        return False
    if response.get("is_error") is True or response.get("success") is False:
        return True
    if response.get("interrupted") is True or response.get("error"):
        return True
    for key in ("exit_code", "exitCode", "status", "code"):
        value = response.get(key)
        if isinstance(value, bool) or value is None:
            continue
        try:
            if int(value) != 0:
                return True
        except (TypeError, ValueError):
            if str(value).lower() in {"error", "failed", "failure"}:
                return True
    return False


if tool == "Bash":
    cmd = ti.get("command")
    if not isinstance(cmd, str) or not cmd.strip():
        sys.exit(0)
    if failed_result(d):
        sys.exit(0)
    cfg = pathlib.Path(os.environ["CB_CFG"])
    if not cfg.is_dir():
        sys.exit(0)
    segments = [executable_segment(s) for s in command_segments(cmd)]
    for f in sorted(cfg.glob("check-command.*")):
        surface = f.name.split(".", 1)[1]
        try:
            configured = f.read_text(encoding="utf-8").splitlines()[0]
            want = " ".join(shlex.split(configured))
        except (OSError, IndexError, ValueError):
            continue
        if want and any(seg == want or seg.startswith(want + " ") for seg in segments):
            record("exec", surface)
    sys.exit(0)

paths = []
for k in ("file_path", "notebook_path", "path"):
    v = ti.get(k)
    if isinstance(v, str) and v.strip():
        paths.append(v.strip())
for e in ti.get("edits") or []:
    if isinstance(e, dict):
        v = e.get("file_path")
        if isinstance(v, str) and v.strip():
            paths.append(v.strip())
if not paths:
    sys.exit(0)

seen = set()
for p in paths:
    record_path(p)
    s = surface_of(p)
    if s and s not in seen:
        seen.add(s)
        record("edit", s)
' 2>/dev/null || true
exit 0
