# docparse — dependency-free document extraction

Extracts text and tables from documents to Markdown or plain text with
**zero third-party dependencies** — no `pip install`, no `npm install`,
fully offline. Nothing is vendored: Office formats and PDF are parsed
from scratch using only the language standard libraries.

| Format | Python | Node | Offline | Mechanism |
|---|---|---|---|---|
| .docx / .xlsx / .pptx | `parse_office.py` | `parse_office.mjs` | yes | Office Open XML = ZIP+XML, read with stdlib (`zipfile`+`xml.etree` / built-in `zlib` + a minimal original ZIP reader). Tables included. |
| .pdf (text layer) | `parse_pdf.py` | — | yes | Original PDF text extractor: walks stream objects, inflates FlateDecode (`zlib`), interprets the text operators (Tj/TJ/Td/TD/Tm/T*) and reconstructs lines and coordinate-aligned tables. No PDF library. |
| .pdf (scanned) / images | `ocr_image.py` | — | **no** | OCR needs a system engine; uses `tesseract` **if installed**, else reports clearly how to enable it. Never returns silent empty output. |

`docparse.py` is the unified entry that routes by extension.

## Honesty boundary (F-class)

- docx/xlsx/pptx and text-layer PDFs: fully offline, dependency-free. ✔
- Scanned/image-only PDFs and images: require OCR, which cannot be
  shipped dependency-free. The tools detect a missing text layer and
  say so — they do not pretend to have read an image.
- CID/custom-encoded PDF fonts may yield imperfect glyphs; flagged.

## Usage

```
$PYBIN docparse.py report.docx --format md --out report.md
$PYBIN docparse.py data.xlsx  --format md
$PYBIN parse_pdf.py paper.pdf --format txt
node    parse_office.mjs deck.pptx --format md
```

> `$PYBIN` is the interpreter resolved by `scripts/lib/cbenv.sh` — `python3` on POSIX, `python`/`py -3`
> on Windows (where a bare `python3` hits the Microsoft Store
> alias instead of an interpreter).
