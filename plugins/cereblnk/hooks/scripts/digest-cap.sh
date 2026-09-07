#!/usr/bin/env bash
# DigestCapHook (SubagentStop) — CB-094. Exit 2 retains oversized-return agents;
# context-budget owns the cap, re-entry is bounded, and errors fail open.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

REASON="$(printf '%s' "$INPUT" | CB_RUN="$RUN" CB_MAX="${CB_DIGEST_NUDGES:-2}" \
  CB_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" $PYBIN -c '
import json, os, pathlib, re, subprocess, sys, textwrap, time
from datetime import datetime, timezone

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

agent = d.get("agent_type") or d.get("agent_id") or ""
if not agent:
    sys.exit(0)

def existing_file(v):
    if not isinstance(v, str) or not v:
        return None
    if v.startswith("~/"):
        v = os.path.expanduser(v)
    p = pathlib.Path(v)
    return p if p.is_file() else None

# CB-147/F-31: transcript_path names the conductor, not the subagent.
# Prefer agent_transcript_path; otherwise derive by agent_id, never scan and guess.
tp = existing_file(d.get("agent_transcript_path"))
if tp is None:
    main_tp = d.get("transcript_path") or ""
    if main_tp.startswith("~/"):
        main_tp = os.path.expanduser(main_tp)
    agent_id = d.get("agent_id") or ""
    if main_tp and agent_id and re.fullmatch(r"[A-Za-z0-9_-]+", agent_id):
        main_path = pathlib.Path(main_tp)
        session_dir = main_path.with_name(main_path.stem)
        candidate = session_dir / "subagents" / f"agent-{agent_id}.jsonl"
        tp = existing_file(str(candidate))

# If the subagent transcript is unknown, allow rather than measure the conductor.
if tp is None:
    sys.exit(0)

cap = None
try:
    out = subprocess.run(
        [sys.executable, str(pathlib.Path(os.environ["CB_PLUGIN_ROOT"]) / "scripts/context-budget")],
        capture_output=True, text=True, timeout=20).stdout
    m = re.search(r"digest_lines_max:\s*(\d+)", out)
    if m:
        cap = int(m.group(1))
except Exception:
    pass
if not cap:
    sys.exit(0)

last = None
try:
    for raw in pathlib.Path(tp).read_text(encoding="utf-8", errors="replace").splitlines():
        raw = raw.strip()
        if not raw:
            continue
        try:
            rec = json.loads(raw)
        except Exception:
            continue
        msg = rec.get("message") or rec
        if msg.get("role") != "assistant":
            continue
        content = msg.get("content")
        if isinstance(content, str):
            last = content
        elif isinstance(content, list):
            parts = [c.get("text", "") for c in content
                     if isinstance(c, dict) and c.get("type") == "text"]
            if parts:
                last = "\n".join(parts)
except Exception:
    sys.exit(0)

if last is None:
    sys.exit(0)

run = pathlib.Path(os.environ["CB_RUN"])
safe = re.sub(r"[^A-Za-z0-9._-]", "_", agent)

# One file per digest prevents concurrent SubagentStop writes from interleaving.
# Archival is best-effort and cannot affect the stop decision.
try:
    digest_file = run / (
        "digest." + safe + "."
        + str(int(time.time() * 1_000_000)) + "." + str(os.getpid()) + ".txt"
    )
    digest_file.write_text(
        "agent: " + agent + "\n"
        "timestamp: " + datetime.now(timezone.utc).isoformat() + "\n"
        "---\n" + last + "\n",
        encoding="utf-8")
except Exception:
    pass

# CB-181 (F-A/F-B): persist an unrecorded ACP block conservatively; ambiguous
# fences or non-YAML tails skip ledger writes while the lossless digest remains.
def isolate_acp_block(text):
    anchor = re.compile(r"^[ \t]*(?:acp_version|kind|task_id)[ \t]*:")
    open_fence = re.compile(r"^[ \t]*```(?:ya?ml)?[ \t]*$", re.I)
    close_fence = re.compile(r"^[ \t]*```[ \t]*$")

    def candidate(lines):
        try:
            start = next(i for i, line in enumerate(lines)
                         if anchor.match(line))
        except StopIteration:
            return None
        body = textwrap.dedent("\n".join(lines[start:])).strip()
        if not body or "\x00" in body or "\t" in body:
            return None
        body_lines = body.splitlines()
        if any(line.lstrip().startswith("```") for line in body_lines):
            return None

        # Reject prose tails without duplicating ACP schema validation.
        key = re.compile(r"^[A-Za-z_][A-Za-z0-9_.-]*[ \t]*:")
        for line in body_lines:
            if not line or line[0].isspace() or line.startswith("#"):
                continue
            if line in ("---", "...") or key.match(line):
                continue
            return None

        kind_lines = re.findall(r"^kind[ \t]*:", body, re.M)
        task_lines = re.findall(r"^task_id[ \t]*:", body, re.M)
        kind = re.findall(
            r"^kind[ \t]*:[ \t]*(response|verification|challenge)"
            r"[ \t]*(?:#.*)?$", body, re.M)
        task_id = re.findall(
            r"^task_id[ \t]*:[ \t]*([A-Za-z0-9._-]+)"
            r"[ \t]*(?:#.*)?$", body, re.M)
        if (len(kind_lines) != 1 or len(task_lines) != 1
                or len(kind) != 1 or len(task_id) != 1):
            return None
        return body + "\n", task_id[0]

    lines = text.splitlines()
    fenced = []
    saw_fence = False
    i = 0
    while i < len(lines):
        if not open_fence.match(lines[i]):
            i += 1
            continue
        saw_fence = True
        start = i + 1
        i = start
        while i < len(lines) and not close_fence.match(lines[i]):
            i += 1
        if i >= len(lines):
            return None
        block = candidate(lines[start:i])
        if block is not None:
            fenced.append(block)
        i += 1
    if saw_fence:
        return fenced[0] if len(fenced) == 1 else None
    return candidate(lines)

# Exclusive creation makes specialist-authored blocks win races; persistence
# failures remain independent of cap enforcement.
try:
    isolated = isolate_acp_block(last)
    if isolated is not None:
        body, task_id = isolated
        with (run / (task_id + ".yaml")).open("x", encoding="utf-8") as f:
            f.write(body)
except Exception:
    pass

lines = [l for l in last.strip().splitlines() if l.strip()]
if len(lines) <= cap:
    sys.exit(0)

state = run / ("digest-cap." + safe + ".state")
try:
    seen = int(state.read_text(encoding="utf-8").strip() or 0)
except Exception:
    seen = 0
if seen >= int(os.environ.get("CB_MAX") or 2):
    sys.exit(0)
try:
    state.write_text(str(seen + 1), encoding="utf-8")
except Exception:
    sys.exit(0)

# F-25: `{run}<task_id>.yaml` concatenated into an unusable path; name the
# run directory and describe the task-id placeholder explicitly.
print(f"{agent} returned {len(lines)} lines; the cap is {cap} "
      f"(run-discipline \u00a71). Write the full Response Block to "
      f"{run}/<its task_id>.yaml — that directory holds this run, "
      f"one file per task id — if it is not there yet, "
      f"then return only: "
      f"task_id, role, status, a one-sentence decision, fact counts per "
      f"label, unknown and risk counts, confidence, and the block path.")
' 2>/dev/null || true)"

[ -n "$REASON" ] || exit 0
echo "cereblnk digest-cap: $REASON" >&2
exit 2
