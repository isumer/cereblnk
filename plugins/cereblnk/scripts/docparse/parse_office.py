#!/usr/bin/env python3
"""
parse_office.py — extract text and tables from docx / xlsx / pptx to
Markdown or plain text, using ONLY the Python standard library
(zipfile + xml.etree). No pip install, works fully offline.

Office Open XML files are ZIP archives of XML parts; this reads those
parts directly. It does NOT import python-docx/openpyxl/python-pptx —
by design, so it runs in dependency-free offline environments.

Usage:
  parse_office.py <file.docx|xlsx|pptx> [--format md|txt] [--out PATH]

Exit codes: 0 ok · 1 parse error · 2 usage/unsupported
"""
import sys, os, re, zipfile, argparse
import xml.etree.ElementTree as ET

W  = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
S  = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
A  = "http://schemas.openxmlformats.org/drawingml/2006/main"
PR = "http://schemas.openxmlformats.org/presentationml/2006/main"

def _text_of(el, ns_t):
    """Concatenate all <t> descendant text under an element."""
    return "".join(t.text or "" for t in el.iter(ns_t))

# ---------- DOCX ----------
_HEADING_STYLE = re.compile(r"^heading[ _-]?([1-9])$", re.I)

def _heading_level(el):
    """Outline level of a <w:p> from its paragraph style, else 0.

    Word records document structure in `w:pStyle`, not in the run text.
    Dropping it loses the only structural signal a .docx carries, so
    `docindex` would have to guess at section boundaries that the file
    already states. Recognises the OOXML style ids `Heading1`..`Heading9`
    and `Title`; a localized style id (Word writes e.g. `berschrift1`
    under a German UI) is NOT matched and degrades to body text — a
    missed heading, never a wrong one.
    """
    pPr = el.find(f"{{{W}}}pPr")
    if pPr is None:
        return 0
    style = pPr.find(f"{{{W}}}pStyle")
    if style is None:
        return 0
    val = (style.get(f"{{{W}}}val") or "").strip()
    if val.lower() == "title":
        return 1
    m = _HEADING_STYLE.match(val)
    return int(m.group(1)) if m else 0

def parse_docx(zf, fmt):
    xml = ET.fromstring(zf.read("word/document.xml"))
    body = xml.find(f"{{{W}}}body")
    wt = f"{{{W}}}t"
    out = []
    if body is None:
        return ""
    for el in body:
        tag = el.tag.split("}")[-1]
        if tag == "p":
            txt = _text_of(el, wt).strip()
            if txt:
                level = _heading_level(el) if fmt == "md" else 0
                out.append(("#" * min(level, 6) + " " + txt) if level else txt)
        elif tag == "tbl":
            rows = []
            for tr in el.findall(f"{{{W}}}tr"):
                cells = [_text_of(tc, wt).strip() for tc in tr.findall(f"{{{W}}}tc")]
                rows.append(cells)
            out.append(_render_table(rows, fmt))
    return "\n\n".join(out)

# ---------- XLSX ----------
def _col_num(ref):
    # "B3" -> column index 1 (0-based); ignores digits
    n = 0
    for ch in ref:
        if ch.isalpha():
            n = n * 26 + (ord(ch.upper()) - 64)
        else:
            break
    return n - 1

def parse_xlsx(zf, fmt):
    names = zf.namelist()
    shared = []
    if "xl/sharedStrings.xml" in names:
        sst = ET.fromstring(zf.read("xl/sharedStrings.xml"))
        for si in sst.findall(f"{{{S}}}si"):
            shared.append(_text_of(si, f"{{{S}}}t"))
    sheets = sorted(n for n in names if n.startswith("xl/worksheets/") and n.endswith(".xml"))
    blocks = []
    for sn in sheets:
        ws = ET.fromstring(zf.read(sn))
        rows = []
        for row in ws.iter(f"{{{S}}}row"):
            cells_by_col = {}
            maxc = -1
            for c in row.findall(f"{{{S}}}c"):
                ref = c.get("r", "")
                col = _col_num(ref) if ref else len(cells_by_col)
                v = c.find(f"{{{S}}}v")
                is_inline = c.get("t") == "inlineStr"
                if c.get("t") == "s" and v is not None:
                    val = shared[int(v.text)] if v.text and v.text.isdigit() else ""
                elif is_inline:
                    val = _text_of(c, f"{{{S}}}t")
                else:
                    val = v.text if v is not None else ""
                cells_by_col[col] = val or ""
                maxc = max(maxc, col)
            rows.append([cells_by_col.get(i, "") for i in range(maxc + 1)] if maxc >= 0 else [])
        # normalize width
        width = max((len(r) for r in rows), default=0)
        rows = [r + [""] * (width - len(r)) for r in rows]
        sheet_label = os.path.basename(sn).replace(".xml", "")
        header = f"## {sheet_label}" if fmt == "md" else f"[{sheet_label}]"
        blocks.append(header + "\n\n" + _render_table(rows, fmt) if rows else header)
    return "\n\n".join(blocks)

# ---------- PPTX ----------
def parse_pptx(zf, fmt):
    slides = sorted(
        (n for n in zf.namelist()
         if n.startswith("ppt/slides/slide") and n.endswith(".xml")),
        key=lambda x: int("".join(ch for ch in os.path.basename(x) if ch.isdigit()) or 0),
    )
    at = f"{{{A}}}t"
    out = []
    for i, sn in enumerate(slides, 1):
        sx = ET.fromstring(zf.read(sn))
        lines = [t.text.strip() for t in sx.iter(at) if t.text and t.text.strip()]
        head = f"## Slide {i}" if fmt == "md" else f"--- Slide {i} ---"
        out.append(head + "\n\n" + "\n".join(lines) if lines else head)
    return "\n\n".join(out)

# ---------- table rendering ----------
def _render_table(rows, fmt):
    rows = [r for r in rows if r]
    if not rows:
        return ""
    if fmt == "txt":
        return "\n".join(" | ".join(c.replace("\n", " ") for c in r) for r in rows)
    # markdown: first row as header
    def esc(c): return c.replace("|", "\\|").replace("\n", " ")
    width = max(len(r) for r in rows)
    rows = [r + [""] * (width - len(r)) for r in rows]
    md = ["| " + " | ".join(esc(c) for c in rows[0]) + " |",
          "| " + " | ".join("---" for _ in rows[0]) + " |"]
    for r in rows[1:]:
        md.append("| " + " | ".join(esc(c) for c in r) + " |")
    return "\n".join(md)

DISPATCH = {".docx": parse_docx, ".xlsx": parse_xlsx, ".pptx": parse_pptx}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--format", choices=["md", "txt"], default="md")
    ap.add_argument("--out")
    args = ap.parse_args()
    ext = os.path.splitext(args.file)[1].lower()
    if ext not in DISPATCH:
        sys.stderr.write(f"parse_office: unsupported extension {ext} "
                         f"(supported: {', '.join(DISPATCH)})\n")
        return 2
    if not os.path.isfile(args.file):
        sys.stderr.write(f"parse_office: no such file: {args.file}\n")
        return 2
    try:
        with zipfile.ZipFile(args.file) as zf:
            text = DISPATCH[ext](zf, args.format)
    except zipfile.BadZipFile:
        sys.stderr.write("parse_office: not a valid Office Open XML (zip) file\n")
        return 1
    except (ET.ParseError, KeyError) as e:
        sys.stderr.write(f"parse_office: parse error: {e}\n")
        return 1
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"parse_office: wrote {args.out} ({len(text)} chars)")
    else:
        sys.stdout.write(text + "\n")
    return 0

if __name__ == "__main__":
    sys.exit(main())
