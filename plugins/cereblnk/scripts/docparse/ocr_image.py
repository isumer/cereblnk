#!/usr/bin/env python3
"""
ocr_image.py — OCR fallback for scanned documents.

OCR requires a system OCR engine or a large ML model, neither of which
can be vendored dependency-free. This script therefore uses the system
`tesseract` binary IF it is installed, and otherwise reports clearly
that OCR is unavailable and how to enable it — it never returns silent
empty output.

Usage: ocr_image.py <image-or-pdf> [--lang eng] [--out PATH]
Exit: 0 ok · 2 usage · 4 OCR engine unavailable
"""
import sys, os, shutil, subprocess, argparse

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--lang", default="eng")
    ap.add_argument("--out")
    args = ap.parse_args()
    if not os.path.isfile(args.file):
        sys.stderr.write(f"ocr_image: no such file: {args.file}\n"); return 2

    tess = shutil.which("tesseract")
    if not tess:
        sys.stderr.write(
            "ocr_image: OCR engine unavailable. No `tesseract` binary on "
            "PATH. OCR cannot be shipped dependency-free/offline, so this "
            "step needs a system install:\n"
            "  Debian/Ubuntu: apt-get install tesseract-ocr\n"
            "  macOS:         brew install tesseract\n"
            "Then re-run. (Document text extraction for docx/xlsx/pptx/pdf "
            "does NOT need this — only scanned/image documents do.)\n")
        return 4
    try:
        # tesseract writes to <out>.txt; use stdout via 'stdout' target
        res = subprocess.run(
            [tess, args.file, "stdout", "-l", args.lang],
            capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        sys.stderr.write("ocr_image: tesseract timed out (120s)\n"); return 1
    if res.returncode != 0:
        sys.stderr.write(f"ocr_image: tesseract failed: {res.stderr.strip()}\n")
        return 1
    text = res.stdout
    if args.out:
        open(args.out, "w", encoding="utf-8").write(text)
        print(f"ocr_image: wrote {args.out} ({len(text)} chars)")
    else:
        sys.stdout.write(text)
    return 0

if __name__ == "__main__":
    sys.exit(main())
