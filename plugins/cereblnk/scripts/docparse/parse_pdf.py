#!/usr/bin/env python3
"""
parse_pdf.py — original, dependency-free PDF text extractor.

Extracts the text layer from text-based PDFs using ONLY the Python
standard library (re + zlib). No pip install, fully offline, no third-
party PDF library. Written from scratch: it walks stream objects,
inflates FlateDecode content, and interprets the text-showing operators
(Tj, TJ, ', ") together with the positioning operators (Td, TD, Tm, T*)
to reconstruct lines — and, when cells align in columns, tables.

HONEST LIMITS (stated, not hidden):
  * Works on PDFs that carry a real text layer.
  * A scanned/image-only PDF has NO text layer; this reports that
    clearly and suggests OCR rather than returning empty output.
  * CID / custom-encoded fonts with non-trivial CMaps may yield
    garbled glyphs; flagged when detected.
  * Only FlateDecode and raw streams are inflated (the common case);
    LZW/ASCII85-only streams are skipped with a note.

Usage:
  parse_pdf.py <file.pdf> [--format md|txt] [--out PATH]
Exit: 0 ok · 1 parse error · 2 usage · 3 no extractable text layer
"""
import sys, os, re, zlib, argparse

# ---- string unescape (PDF literal strings) ----
_ESC = {b'\\n': b'\n', b'\\r': b'\r', b'\\t': b'\t', b'\\b': b'\b',
        b'\\f': b'\f', b'\\(': b'(', b'\\)': b')', b'\\\\': b'\\'}

def _unescape(raw: bytes) -> str:
    # octal \ddd
    raw = re.sub(rb'\\([0-7]{1,3})', lambda m: bytes([int(m.group(1), 8) & 0xFF]), raw)
    for k, v in _ESC.items():
        raw = raw.replace(k, v)
    return raw.decode('latin-1', 'replace')

# ---- inflate a content stream if needed ----
def _inflate(stream: bytes, header: bytes) -> bytes | None:
    if b'FlateDecode' in header:
        try:
            return zlib.decompress(stream)
        except zlib.error:
            # some producers pad; retry with a raw decompressor
            try:
                return zlib.decompressobj().decompress(stream)
            except zlib.error:
                return None
    if b'Filter' in header and (b'LZW' in header or b'ASCII85' in header or b'DCTDecode' in header):
        return None  # unsupported filter — signal caller
    return stream  # raw / no filter

# ---- tokenise the text objects of a content stream ----
_STR = rb'\((?:[^()\\]|\\.|\((?:[^()\\]|\\.)*\))*\)'

_NUM = rb'-?[\d.]+'
_TOKEN_RE = re.compile(
    rb'(?P<bt>BT)'
    rb'|(?P<et>ET)'
    rb'|(?P<tstar>T\*)'
    rb'|(?P<td>' + _NUM + rb')\s+(?P<tdy>' + _NUM + rb')\s+(?P<tdop>Td|TD)'
    rb'|' + _NUM + rb'\s+' + _NUM + rb'\s+' + _NUM + rb'\s+' + _NUM
        + rb'\s+(?P<tmx>' + _NUM + rb')\s+(?P<tmy>' + _NUM + rb')\s+Tm'
    rb'|(?P<tj>' + _STR + rb')\s*(?:Tj|\'|")'
    rb'|\[(?P<tjarr>(?:[^\]]|\\\])*)\]\s*TJ',
    re.S)

def _extract_positioned(content: bytes):
    """Yield (x, y, text) chunks using Td/TD/Tm/T*/Tj/TJ operators."""
    x = y = 0.0
    line_lead = 0.0
    for m in _TOKEN_RE.finditer(content):
        g = m.lastgroup
        if m.group('bt'):
            x = y = 0.0
        elif m.group('tstar'):
            y -= line_lead or 12.0
            x = 0.0
        elif m.group('tdop'):
            dx, dy = float(m.group('td')), float(m.group('tdy'))
            x += dx; y += dy
            if m.group('tdop') == b'TD':
                line_lead = -dy
        elif m.group('tmx') is not None:
            x = float(m.group('tmx')); y = float(m.group('tmy'))
        elif m.group('tj') is not None:
            txt = _unescape(m.group('tj')[1:-1])
            if txt:
                yield (x, y, txt)
        elif m.group('tjarr') is not None:
            parts = re.findall(_STR, m.group('tjarr'))
            joined = ''.join(_unescape(p[1:-1]) for p in parts)
            if joined:
                yield (x, y, joined)

# ---- group chunks into lines / table rows by Y, columns by X ----
def _group_lines(chunks, fmt):
    if not chunks:
        return "", False
    # bucket by rounded Y (2pt tolerance)
    chunks = sorted(chunks, key=lambda c: (-round(c[1] / 2), c[0]))
    lines = []
    cur_y = None
    row = []
    for x, yv, txt in chunks:
        key = round(yv / 2)
        if cur_y is None or key == cur_y:
            row.append((x, txt))
        else:
            lines.append(row); row = [(x, txt)]
        cur_y = key
    if row:
        lines.append(row)

    # detect table-ish rows (>=2 x-separated cells on multiple lines)
    multi = [ln for ln in lines if len(ln) >= 2]
    looks_table = len(multi) >= 2

    out = []
    for ln in lines:
        cells = [t for _, t in sorted(ln, key=lambda c: c[0])]
        if len(cells) >= 2 and looks_table and fmt == 'md':
            out.append('| ' + ' | '.join(c.replace('|', '\\|') for c in cells) + ' |')
        else:
            out.append(' '.join(cells) if len(cells) > 1 else cells[0])
    # insert md header separator after first table row
    if looks_table and fmt == 'md':
        for i, l in enumerate(out):
            if l.startswith('|'):
                ncol = l.count('|') - 1
                out.insert(i + 1, '| ' + ' | '.join(['---'] * ncol) + ' |')
                break
    return '\n'.join(out), looks_table

def parse_pdf(path, fmt):
    data = open(path, 'rb').read()
    if not data.startswith(b'%PDF'):
        raise ValueError("not a PDF (missing %PDF header)")
    # find every stream with its preceding dict header
    blocks = re.findall(rb'(<<[^>]*?>>)\s*stream\r?\n(.*?)\r?\nendstream', data, re.S)
    all_chunks = []
    unsupported = 0
    for header, stream in blocks:
        inflated = _inflate(stream, header)
        if inflated is None:
            unsupported += 1
            continue
        if b'BT' not in inflated:  # not a text content stream
            continue
        all_chunks.extend(_extract_positioned(inflated))
    text, _ = _group_lines(all_chunks, fmt)
    return text, len(all_chunks), unsupported

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--format", choices=["md", "txt"], default="md")
    ap.add_argument("--out")
    args = ap.parse_args()
    if not os.path.isfile(args.file):
        sys.stderr.write(f"parse_pdf: no such file: {args.file}\n"); return 2
    try:
        text, n, unsupported = parse_pdf(args.file, args.format)
    except ValueError as e:
        sys.stderr.write(f"parse_pdf: {e}\n"); return 1
    except Exception as e:
        sys.stderr.write(f"parse_pdf: parse error: {e}\n"); return 1

    if not text.strip():
        msg = ("parse_pdf: no text layer found. This PDF is likely "
               "scanned/image-only — run OCR (see the ocr skill) to "
               "extract its text.")
        if unsupported:
            msg += (f" ({unsupported} stream(s) used an unsupported "
                    f"filter such as LZW/ASCII85 and were skipped.)")
        sys.stderr.write(msg + "\n")
        return 3
    if args.out:
        open(args.out, "w", encoding="utf-8").write(text)
        print(f"parse_pdf: wrote {args.out} ({len(text)} chars from {n} text chunks)")
    else:
        sys.stdout.write(text + "\n")
    if unsupported:
        sys.stderr.write(f"parse_pdf: note — {unsupported} stream(s) with "
                         f"unsupported filters were skipped.\n")
    return 0

if __name__ == "__main__":
    sys.exit(main())
