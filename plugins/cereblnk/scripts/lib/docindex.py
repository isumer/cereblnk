#!/usr/bin/env python3
"""docindex.py — build a navigable index over one document (CB-112).

Invoked through `scripts/docindex`, which resolves CB_DIR. Extraction is
delegated to docparse; nothing here re-implements a parser.

The only real decision this makes is how the document was segmented,
and it refuses to pretend that decision is better than it was. Three
layers, tried in order, each recorded in the manifest with the epistemic
label it earns:

  structural  ATX headings present in the extracted text        known
              (docx heading styles, pptx slides, xlsx sheets)
  pattern     a section-heading regex matched the line starts   derived
              (Chapter/Bölüm/Madde/Section/Part, numbered heads)
  window      fixed line windows — no structure was found       assumed

A caller that reads `segmentation.label` learns whether the section
boundaries came from the file or from this script guessing. That
distinction is the point: a `window` outline still makes the document
navigable, but a claim anchored to one of its sections is anchored to an
arbitrary line, and the manifest says so rather than letting the shape
of the JSON imply otherwise.

Token figures are `chars / 4`. They are estimates, named
`tokens_estimated` everywhere, and exist to order sections by weight —
not to be spent as a budget.

Exit: 0 indexed or reused · 1 extraction failed · 2 usage/unsupported
      · 3 no text layer (the source needs OCR)
"""
import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
DOCPARSE = HERE.parent / "docparse" / "docparse.py"

# Layer 1 — structure the extracted text actually carries.
ATX = re.compile(r"^(#{1,6})\s+(\S.*?)\s*$")

# Layer 2 — section headings by shape. Multilingual on purpose: the
# documents this exists for are contracts, regulations and specs, and
# "Madde 7" is as much a section boundary as "Section 7". A match here
# is `derived`, never `known` — these patterns also match ordinary
# prose, and the manifest carries that caveat to the caller.
PATTERNS = [
    re.compile(
        r"^\s*(?:CHAPTER|Chapter|BÖLÜM|Bölüm|KISIM|Kısım|SECTION|Section"
        r"|PART|Part|ANNEX|Annex|APPENDIX|Appendix|EK)\s+"
        r"(?:[0-9]+|[IVXLCDM]+)\b.*$"),
    re.compile(r"^\s*(?:MADDE|Madde)\s+[0-9]+\b.*$"),
    re.compile(r"^\s*[0-9]+(?:\.[0-9]+){0,3}\.?\s+\S.{0,80}$"),
]

# Sources that are already text: no container to open, so no parser.
TEXT_EXT = {".md", ".markdown", ".txt", ".rst", ".adoc", ".text"}

MIN_SECTIONS = 2          # one "section" is not a segmentation
DEFAULT_WINDOW_LINES = 400


def estimate_tokens(chars):
    return max(1, round(chars / 4))


def _headings_structural(lines):
    found = []
    for i, line in enumerate(lines, 1):
        m = ATX.match(line)
        if m:
            found.append((i, len(m.group(1)), m.group(2)[:120]))
    return found


def _headings_pattern(lines):
    found = []
    for i, line in enumerate(lines, 1):
        if len(line) > 120 or not line.strip():
            continue
        for p in PATTERNS:
            if p.match(line):
                found.append((i, 1, line.strip()[:120]))
                break
    return found


def _sections_from_headings(heads, total):
    """Heading anchors -> closed, non-overlapping line ranges."""
    sections = []
    if heads and heads[0][0] > 1:
        sections.append((1, heads[0][0] - 1, 1, "(front matter)"))
    for idx, (start, level, title) in enumerate(heads):
        end = heads[idx + 1][0] - 1 if idx + 1 < len(heads) else total
        if end >= start:
            sections.append((start, end, level, title))
    return sections


def _sections_windowed(total, size):
    """No structure found. Windows do not overlap: an overlapping range
    makes 'which section is this line in' ambiguous, and the caller
    widens the range itself when a slice cuts a paragraph."""
    sections = []
    start = 1
    while start <= total:
        end = min(start + size - 1, total)
        # No title: a window has no name, and inventing "lines 401-800"
        # as one would let a reader mistake an arbitrary cut for a
        # heading the document declared.
        sections.append((start, end, 1, None))
        start = end + 1
    return sections or [(1, max(total, 1), 1, None)]


def segment(lines, window_lines):
    total = len(lines)
    heads = _headings_structural(lines)
    if len(heads) >= MIN_SECTIONS:
        return _sections_from_headings(heads, total), {
            "layer": "structural",
            "label": "known",
            "detail": f"{len(heads)} headings present in the extracted text",
        }
    heads = _headings_pattern(lines)
    if len(heads) >= MIN_SECTIONS:
        return _sections_from_headings(heads, total), {
            "layer": "pattern",
            "label": "derived",
            "detail": (f"{len(heads)} lines matched a section-heading pattern; "
                       f"the source declares no headings"),
        }
    return _sections_windowed(total, window_lines), {
        "layer": "window",
        "label": "assumed",
        "detail": (f"no headings and no section pattern found; split into "
                   f"{window_lines}-line windows — boundaries are arbitrary"),
    }


def build_outline(lines, window_lines):
    ranges, seg = segment(lines, window_lines)
    sections = []
    for n, (start, end, level, title) in enumerate(ranges, 1):
        chars = sum(len(x) + 1 for x in lines[start - 1:end])
        sections.append({
            "id": "s%03d" % n,
            "title": title,
            "level": level,
            "line_start": start,
            "line_end": end,
            "chars": chars,
            "tokens_estimated": estimate_tokens(chars),
        })
    return sections, seg


def extract(src, dest):
    """Produce the canonical text. Plain-text sources are copied
    verbatim — docparse exists to open binary containers, and routing a
    .md file through it would only reject it. Everything else is
    delegated, and docparse's exit codes are propagated unchanged: a
    caller that knows docparse knows these already, and remapping them
    would hide the OCR path behind a generic failure."""
    if src.suffix.lower() in TEXT_EXT:
        dest.write_text(src.read_text(encoding="utf-8", errors="replace"),
                        encoding="utf-8")
        return 0, "verbatim (text source)"
    r = subprocess.run(
        [sys.executable, str(DOCPARSE), str(src), "--format", "md",
         "--out", str(dest)],
        capture_output=True, text=True)
    return r.returncode, (r.stderr or r.stdout).strip()


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("file")
    ap.add_argument("--cb-dir", required=True)
    ap.add_argument("--refresh", action="store_true",
                    help="re-extract even if this exact file is indexed")
    ap.add_argument("--json", action="store_true",
                    help="print the manifest instead of a human summary")
    ap.add_argument("--window-lines", type=int, default=DEFAULT_WINDOW_LINES)
    args = ap.parse_args()

    src = pathlib.Path(args.file)
    if not src.is_file():
        print(f"docindex: no such file: {src}", file=sys.stderr)
        return 2
    if args.window_lines < 1:
        print("docindex: --window-lines must be positive", file=sys.stderr)
        return 2

    raw = src.read_bytes()
    sha = hashlib.sha256(raw).hexdigest()
    root = pathlib.Path(args.cb_dir) / "docs" / sha[:12]
    manifest_path = root / "manifest.json"
    text_path = root / "text.md"
    outline_path = root / "outline.json"

    # The source's own hash is the identity, so a hit is proof the bytes
    # are the same bytes — not a guess from mtime or path.
    if manifest_path.is_file() and text_path.is_file() and not args.refresh:
        try:
            prev = json.loads(manifest_path.read_text(encoding="utf-8"))
        except Exception:
            prev = None
        if prev and prev.get("sha256") == sha:
            if args.json:
                print(json.dumps(prev, indent=2, ensure_ascii=False))
            else:
                print(f"docindex: reused {prev['doc_id']} "
                      f"({prev['sections']} sections, "
                      f"~{prev['tokens_estimated']} tokens est) {root}")
            return 0

    root.mkdir(parents=True, exist_ok=True)
    rc, err = extract(src, text_path)
    if rc != 0:
        # rc 3 is docparse's no-text-layer signal; passing it through
        # keeps "needs OCR" distinguishable from "failed to parse".
        print(f"docindex: extraction failed (docparse rc={rc}): {err[:200]}",
              file=sys.stderr)
        return rc

    text = text_path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    sections, seg = build_outline(lines, args.window_lines)

    manifest = {
        "doc_id": sha[:12],
        "source": str(src.resolve()),
        "source_name": src.name,
        "sha256": sha,
        "bytes": len(raw),
        "format": src.suffix.lower(),
        "extractor": ("verbatim (text source)" if src.suffix.lower() in TEXT_EXT
                      else "docparse/docparse.py --format md"),
        "indexed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "lines": len(lines),
        "chars": len(text),
        "tokens_estimated": estimate_tokens(len(text)),
        "segmentation": seg,
        "sections": len(sections),
        "text": str(text_path),
        "outline": str(outline_path),
    }
    outline_path.write_text(json.dumps(
        {"doc_id": sha[:12], "segmentation": seg, "sections": sections},
        indent=2, ensure_ascii=False), encoding="utf-8")
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False),
                             encoding="utf-8")

    if args.json:
        print(json.dumps(manifest, indent=2, ensure_ascii=False))
    else:
        print(f"docindex: {manifest['doc_id']} {src.name} — "
              f"{len(sections)} sections, {len(lines)} lines, "
              f"~{manifest['tokens_estimated']} tokens est, "
              f"segmentation {seg['layer']} ({seg['label']})")
        print(f"docindex: {root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
