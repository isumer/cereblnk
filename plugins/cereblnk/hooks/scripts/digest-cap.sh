#!/usr/bin/env bash
# DigestCapHook (SubagentStop) — CB-094, hard enforcement.
#
# run-discipline §1 caps a subagent's return at ten lines. Until now
# that cap was a sentence. Nothing measured what came back, so an
# oversized return cost the conducting conversation its headroom and
# the violation was invisible until the run died — which is the
# failure budget-policy rule 4 was written after, twice.
#
# The measurement exists: the subagent's OWN transcript holds its
# final assistant message, which IS what the conductor receives. That
# transcript is a sibling of the main session transcript, named by
# this agent's id: <dir of transcript_path>/subagents/agent-<id>.jsonl.
# The payload may also hand that path back directly as
# agent_transcript_path; either way it is read, counted, and the stop
# is blocked when the count exceeds the cap. SubagentStop blocks on
# exit 2 — the subagent does not stop, it reads stderr and returns a
# digest instead.
#
# The cap comes from scripts/context-budget (digest_lines_max), never
# from a number written here. CB-094's whole point is that figures are
# computed; a literal ten in this file would be the same mistake in a
# new place.
#
# Loop safety, in skill-floor.sh's shape and for the same reason:
#   1. stop_hook_active in stdin -> always allow the stop.
#   2. Nudge state keyed to run dir + agent; a stale file from an
#      older run never insta-disarms a fresh one.
#   3. Hard cap MAX_NUDGES per agent per run, then allow — an agent
#      that will not shorten is a question for the user, not a loop.
#   4. Fail open on every error path: no project root, no interpreter,
#      no transcript, unparseable input -> exit 0. A guard that blocks
#      when it cannot measure is worse than one that does not run.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0

# Only inside a Cereblnk run. No ledger, no contract to enforce.
RUN="$(cb_run_dir)"   # CB-147: the pinned run, not the newest directory
[ -n "$RUN" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in *'"stop_hook_active"'*true*) exit 0 ;; esac

REASON="$(printf '%s' "$INPUT" | CB_RUN="$RUN" CB_MAX="${CB_DIGEST_NUDGES:-2}" \
  CB_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" $PYBIN -c '
import json, os, pathlib, re, subprocess, sys, time
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

# transcript_path on this payload is the CONDUCTING session, not this
# subagent — reading it measures the wrong author. The subagent has
# its own transcript, a sibling file named by its id:
# <dir of transcript_path>/subagents/agent-<agent_id>.jsonl. Prefer
# agent_transcript_path when the payload supplies it directly; fall
# back to building the sibling path from agent_id, never from a
# directory scan (CB-147, F-31 — identity must be carried, not
# guessed). Either candidate is trusted only once confirmed to exist.
tp = existing_file(d.get("agent_transcript_path"))
if tp is None:
    main_tp = d.get("transcript_path") or ""
    if main_tp.startswith("~/"):
        main_tp = os.path.expanduser(main_tp)
    agent_id = d.get("agent_id") or ""
    if main_tp and agent_id and re.fullmatch(r"[A-Za-z0-9_-]+", agent_id):
        candidate = pathlib.Path(main_tp).parent / "subagents" / f"agent-{agent_id}.jsonl"
        tp = existing_file(str(candidate))

# Its own transcript cannot be identified: measuring the conductor
# instead is the defect this hook exists to fix, so silence beats a
# wrong measurement. Count nothing, write nothing, allow the
# stop.
if tp is None:
    sys.exit(0)

# The cap is computed, never written here (CB-094).
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

# The final assistant text block is what the conductor receives.
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

# Retain a copy of the digest regardless of cap outcome, one file per
# digest rather than an appended log: a concurrent SubagentStop from a
# different agent can never interleave mid-write, and a later scan for
# a citation opens a file named for its agent and moment instead of
# locating an offset inside a shared log. Best-effort and silent: a
# failure here must never affect the stop decision below.
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

# Say what to return, not merely that the return was wrong. A block
# message that only names the violation makes shortening a guess.
# F-25: this line printed a path an agent could not act on —
# `{run}<task_id>.yaml`. `<task_id>` is literal text, not a
# placeholder, and pathlib had already dropped the trailing separator,
# so the two ran together into one filename outside any run directory.
# Both specialists who received it declined to follow it and reported
# the deviation instead; correct behaviour, but from judgement rather
# than from the protocol. The block belongs beside the others in the
# run directory, and the id is the one in the block being returned.
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
