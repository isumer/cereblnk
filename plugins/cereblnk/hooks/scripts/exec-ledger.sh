#!/usr/bin/env bash
# ExecLedgerHook (PostToolUse: Write|Edit|MultiEdit|NotebookEdit|Bash)
# — CB-113, observation only.
#
# Two facts, one ledger:
#   edit <surface>   a specialist changed code on that surface
#   exec <surface>   a specialist ran that surface's configured check
#
# This is the evidence ExecFloorHook checks at SubagentStop. Without it
# "the code works" is a claim about a program nobody ran — unfalsifiable
# rather than verified, which is the failure this task exists to close.
#
# Never blocks. A recording hook that can fail a tool call would trade a
# verification record for a broken session — skill-ledger.sh's rule, and
# for the same reason.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

RUN="$(ls -1dt "$CB_DIR"/context/*/ 2>/dev/null | head -1)"
[ -n "$RUN" ] || exit 0

MAP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/../policies/surface-map.yaml"

INPUT="$(cat 2>/dev/null || true)"
printf '%s' "$INPUT" | CB_RUN="$RUN" CB_MAP="$MAP" CB_CFG="$CB_DIR/config" $PYBIN -c '
import json, os, pathlib, re, sys, time

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


def load_map():
    """Minimal reader for surface-map.yaml. Two nested list keys per
    surface; no dependency on a yaml module, which hooks cannot assume."""
    out, surface, key = {}, None, None
    p = pathlib.Path(os.environ["CB_MAP"])
    try:
        lines = p.read_text(encoding="utf-8").splitlines()
    except OSError:
        return out
    for line in lines:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^  ([\w-]+):\s*$", line)
        if m:
            surface, key = m.group(1), None
            out.setdefault(surface, {"path_contains": [], "extensions": []})
            continue
        m = re.match(r"^    (path_contains|extensions):\s*$", line)
        if m and surface:
            key = m.group(1)
            continue
        m = re.match(r"^      -\s*(\S+)\s*$", line)
        if m and surface and key:
            out[surface][key].append(m.group(1).lower())
    return out


def surface_of(path):
    p = path.replace("\\", "/").lower()
    if not p.startswith("/"):
        p = "/" + p
    smap = load_map()
    for surface, rules in smap.items():
        for seg in rules["path_contains"]:
            if seg in p:
                return surface
    for surface, rules in smap.items():
        for ext in rules["extensions"]:
            if p.endswith(ext):
                return surface
    return ""


if tool == "Bash":
    cmd = ti.get("command")
    if not isinstance(cmd, str) or not cmd.strip():
        sys.exit(0)
    cfg = pathlib.Path(os.environ["CB_CFG"])
    if not cfg.is_dir():
        sys.exit(0)
    norm = " ".join(cmd.split())
    for f in sorted(cfg.glob("check-command.*")):
        surface = f.name.split(".", 1)[1]
        try:
            want = " ".join(f.read_text(encoding="utf-8").splitlines()[0].split())
        except (OSError, IndexError):
            continue
        if want and want in norm:
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
