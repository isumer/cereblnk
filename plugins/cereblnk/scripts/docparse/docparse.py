#!/usr/bin/env python3
"""
docparse.py — unified entry: route a document to the right extractor.

  .docx/.xlsx/.pptx → parse_office.py   (stdlib-only, offline)
  .pdf              → parse_pdf.py      (original, stdlib-only, offline)
                       └ on no-text-layer, suggests OCR
  images/.pdf scan  → ocr_image.py      (system tesseract, if present)

All extraction of text-based Office and PDF files is fully offline and
dependency-free. OCR is the only path that needs a system engine.

Usage: docparse.py <file> [--format md|txt] [--out PATH] [--ocr]
"""
import sys, os, subprocess, argparse

HERE = os.path.dirname(os.path.abspath(__file__))
OFFICE = {".docx", ".xlsx", ".pptx"}
IMAGES = {".png", ".jpg", ".jpeg", ".tif", ".tiff", ".bmp"}

def run(script, argv):
    return subprocess.run([sys.executable, os.path.join(HERE, script)] + argv).returncode

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--format", choices=["md", "txt"], default="md")
    ap.add_argument("--out")
    ap.add_argument("--ocr", action="store_true",
                    help="force OCR (scanned docs / images)")
    args = ap.parse_args()
    ext = os.path.splitext(args.file)[1].lower()
    passthru = ["--format", args.format] + (["--out", args.out] if args.out else [])

    if args.ocr or ext in IMAGES:
        rc = run("ocr_image.py", [args.file] + (["--out", args.out] if args.out else []))
        return rc
    if ext in OFFICE:
        return run("parse_office.py", [args.file] + passthru)
    if ext == ".pdf":
        rc = run("parse_pdf.py", [args.file] + passthru)
        if rc == 3:  # no text layer → hint OCR
            sys.stderr.write("docparse: retry with --ocr for scanned PDFs.\n")
        return rc
    sys.stderr.write(f"docparse: unsupported type {ext} "
                     f"(supported: docx, xlsx, pptx, pdf, images via --ocr)\n")
    return 2

if __name__ == "__main__":
    sys.exit(main())
