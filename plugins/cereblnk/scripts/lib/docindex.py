#!/usr/bin/env python3
"""docindex.py — build a navigable index over one document (CB-112).

Segmentation labels structural evidence known, keyword matches derived, and windows assumed.

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

# Keyword headings are policy data because hardcoding privileges the author's languages.
# They can match prose, so their segmentation label is `derived`, never `known`.
POLICY = HERE.parent.parent / "policies" / "document-sections.yaml"

# An unreadable policy degrades navigation; it must not prevent indexing.
FALLBACK_KEYWORDS = ["Chapter", "Section", "Part", "Article"]
NUMBERED_HEAD = re.compile(r"^\s*[0-9]+(?:\.[0-9]+){0,3}\.?\s+\S.{0,80}$")


def load_patterns(policy=POLICY):
    """Compile the flat policy schema without adding a YAML dependency."""
    keywords, numbered = None, True
    try:
        for line in policy.read_text(encoding="utf-8").splitlines():
            line = line.split("#", 1)[0].strip() if not line.startswith("#") else ""
            m = re.match(r"^keywords\s*:\s*\[(.*)\]\s*$", line)
            if m:
                keywords = [k.strip().strip("'\"") for k in m.group(1).split(",")
                            if k.strip()]
            m = re.match(r"^numbered\s*:\s*(true|false)\s*$", line)
            if m:
                numbered = m.group(1) == "true"
    except Exception:
        keywords = None
    if keywords is None:
        keywords = FALLBACK_KEYWORDS
    pats = []
    if keywords:
        alt = "|".join(sorted({re.escape(k) for k in keywords} |
                              {re.escape(k.upper()) for k in keywords},
                              key=len, reverse=True))
        pats.append(re.compile(r"^\s*(?:%s)\s+(?:[0-9]+|[IVXLCDM]+)\b.*$" % alt))
    if numbered:
        pats.append(NUMBERED_HEAD)
    return pats


PATTERNS = load_patterns()

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
    """Create non-overlapping fallback windows so each line has one section."""
    sections = []
    start = 1
    while start <= total:
        end = min(start + size - 1, total)
    # Windows have no title; inventing one would imply the document declared the cut.
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
    """Copy text verbatim; delegate containers and preserve docparse's OCR exit code."""
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
