#!/usr/bin/env bash
# DocFloorHook (PreToolUse:Read) — CB-112.
#
# `docindex` writes the extracted text next to a map of it. The map only
# helps if something stops the agent walking past it: an unbounded Read
# of a 200-page contract spends the window on the way to the one clause
# that was asked about, and every later turn re-processes it.
#
# So: an indexed document may be read in slices, not whole. The block
# message carries the computed handoff — doc_id, section count, and the
# largest sections with their line ranges — so the next call is a
# bounded Read rather than a search for one. It does NOT name the way
# around itself. A guard that prints its own bypass has taught the agent
# to take it (CB-099).
#
# Two nudges per document, then allow — the digest-cap idiom. Reading a
# short indexed document whole is sometimes right, and a guard that can
# never be satisfied stops being a guard.
#
# Fail-open everywhere: no root, no interpreter, no manifest,
# unparseable input, unindexed path. A large read is expensive; a
# blocked legitimate read is worse.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/lib/cbenv.sh" 2>/dev/null || true
[ -n "${CB_DIR:-}" ] || exit 0
[ -n "${PYBIN:-}" ] || exit 0
[ -d "$CB_DIR/docs" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"

REASON="$(printf '%s' "$INPUT" | CB_DIR="$CB_DIR" \
  CB_MAX="${CB_DOC_NUDGES:-2}" CB_FLOOR="${CB_DOC_FLOOR_TOKENS:-4000}" \
  $PYBIN -c '
import json, os, pathlib, sys

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if d.get("tool_name") not in (None, "", "Read"):
    sys.exit(0)

ti = d.get("tool_input") or {}
raw = ti.get("file_path") or ""
if not raw:
    sys.exit(0)

# A bounded read is the behaviour this hook exists to produce. Never
# interfere with one.
if ti.get("offset") or ti.get("limit"):
    sys.exit(0)

docs = (pathlib.Path(os.environ["CB_DIR"]) / "docs").resolve()
try:
    target = pathlib.Path(raw.replace("\\\\", "/")).resolve()
except Exception:
    sys.exit(0)
try:
    target.relative_to(docs)
except Exception:
    sys.exit(0)          # not an indexed document
if target.name != "text.md":
    sys.exit(0)

home = target.parent
try:
    man = json.loads((home / "manifest.json").read_text(encoding="utf-8"))
    outline = json.loads((home / "outline.json").read_text(encoding="utf-8"))
except Exception:
    sys.exit(0)

est = int(man.get("tokens_estimated") or 0)
if est < int(os.environ["CB_FLOOR"]):
    sys.exit(0)          # small enough that reading it whole is fine

state = home / "doc-floor.state"
try:
    seen = int(state.read_text(encoding="utf-8").strip() or 0)
except Exception:
    seen = 0
if seen >= int(os.environ["CB_MAX"]):
    sys.exit(0)
try:
    state.write_text(str(seen + 1), encoding="utf-8")
except Exception:
    sys.exit(0)

secs = outline.get("sections") or []
top = sorted(secs, key=lambda s: -(s.get("tokens_estimated") or 0))[:5]
listing = "; ".join(
    "%s lines %s-%s%s (~%s tok)"
    % (s.get("id"), s.get("line_start"), s.get("line_end"),
       (" " + s["title"][:40]) if s.get("title") else "",
       s.get("tokens_estimated"))
    for s in top)
seg = man.get("segmentation") or {}

print(
    "%s is an indexed document of ~%d estimated tokens in %d sections; "
    "reading it whole spends the window before the question is answered. "
    "The map is %s. Largest sections: %s. Section boundaries here are %s "
    "(%s) — anchor any claim to the lines you actually read, and widen "
    "the range when a slice cuts mid-argument."
    % (man.get("source_name") or target.name, est, len(secs),
       home / "outline.json", listing or "(none recorded)",
       seg.get("label") or "unlabelled", seg.get("layer") or "unknown"))
' 2>/dev/null || true)"

[ -n "$REASON" ] || exit 0
echo "cereblnk doc-floor: $REASON" >&2
exit 2
