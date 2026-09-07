"""Renders strokes-only and glyphs-only layers to catch a stroke drawn
through a glyph. Needs rsvg-convert and Pillow; callers degrade to a skip.
"""
import os
import re
import subprocess
import tempfile
from collections import defaultdict

BG = (13, 13, 16)          # the sheet's page colour, #0d0d10
INK_DELTA = 26             # per-channel distance that counts as ink
MIN_CLUSTER = 12           # ignore specks: antialiasing, stroke tips
CLEARANCE = 2.0            # user units of air a stroke owes a glyph


class RendererUnavailable(Exception):
    pass


def available():
    try:
        from PIL import Image  # noqa: F401
    except ImportError:
        return False
    from shutil import which
    return which("rsvg-convert") is not None


def standalone_svg(page_html):
    """Lift the <svg> out, splicing in the <head> rules it depends on."""
    src = page_html
    head = src[:src.index("<svg")]
    svg = src[src.index("<svg"):src.index("</svg>") + 6]
    outer = re.findall(r"<style[^>]*>(.*?)</style>", head, re.S)
    if outer:
        css = "\n".join(outer)
        css = re.sub(r"(?m)^\s*(html\s*,\s*body|body|html)\s*\{[^}]*\}\s*",
                     "", css)
        m = re.search(r"<svg[^>]*>", svg)
        svg = (svg[:m.end()] + "\n<style><![CDATA[\n" + css + "\n]]></style>"
               + svg[m.end():])
    m = re.search(r'viewBox="([\d.\s-]+)"', svg)
    if m and not re.search(r"<svg[^>]*\swidth=", svg):
        vb = m.group(1).split()
        svg = svg.replace("<svg", '<svg width="%s" height="%s"'
                          % (vb[2], vb[3]), 1)
    return svg


def _unclip(svg):
    """Drop clips: they hide overflow, and hiding the clipPath's own rect
    by CSS would blank every clipped group."""
    return re.sub(r'\s*clip-path="[^"]*"', "", svg)


def _strokes_only(svg):
    out = re.sub(r"<text\b.*?</text>", "", _unclip(svg), flags=re.S)
    m = re.search(r"<svg[^>]*>", out)
    return (out[:m.end()]
            + "<style><![CDATA[ * { fill: none !important; } ]]></style>"
            + out[m.end():])


def _glyphs_only(svg):
    out = _unclip(svg)
    m = re.search(r"<svg[^>]*>", out)
    return (out[:m.end()]
            + "<style><![CDATA[ rect, ellipse, circle, line, polygon,"
              " polyline, path { display: none !important; } ]]></style>"
            + out[m.end():])


def _render(svg_text, scale):
    from PIL import Image
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False,
                                     encoding="utf-8") as fh:
        fh.write(svg_text)
        path = fh.name
    png = path + ".png"
    try:
        subprocess.run(["rsvg-convert", "-z", str(scale), "-b", "#0d0d10",
                        "-o", png, path], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return Image.open(png).convert("RGB").copy()
    finally:
        for p in (path, png):
            try:
                os.unlink(p)
            except OSError:
                pass


def _ink(img):
    from PIL import Image, ImageChops
    diff = ImageChops.difference(img, Image.new("RGB", img.size, BG))
    r, g, b = diff.split()
    m = ImageChops.lighter(ImageChops.lighter(r, g), b)
    return m.point(lambda v: 255 if v > INK_DELTA else 0)


def ink_findings(page_html, scale=2.0):
    """[(kind, line, message)] — line is always '-', this pass sees pixels."""
    if not available():
        raise RendererUnavailable("needs rsvg-convert and Pillow")
    from PIL import ImageChops, ImageFilter

    svg = standalone_svg(page_html)
    strokes = _ink(_render(_strokes_only(svg), scale))
    glyphs = _ink(_render(_glyphs_only(svg), scale))
    if strokes.size != glyphs.size:
        raise RendererUnavailable("the two layers rendered at different sizes")

    grow = max(1, int(round(CLEARANCE * scale)))
    halo = glyphs.filter(ImageFilter.MaxFilter(2 * grow + 1))
    both = ImageChops.darker(strokes, halo)

    box = both.getbbox()
    if not box:
        return []
    data = both.load()
    hits = defaultdict(int)
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            if data[x, y]:
                hits[(x // 16, y // 16)] += 1
    cells = {k: v for k, v in hits.items() if v >= MIN_CLUSTER}

    seen, out = set(), []
    for cell in sorted(cells):
        if cell in seen:
            continue
        stack, group = [cell], []
        seen.add(cell)
        while stack:
            cx, cy = stack.pop()
            group.append((cx, cy))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (cx + dx, cy + dy)
                    if n in cells and n not in seen:
                        seen.add(n)
                        stack.append(n)
        xs = [c[0] for c in group]
        ys = [c[1] for c in group]
        out.append((sum(cells[c] for c in group),
                    min(xs) * 16 / scale, min(ys) * 16 / scale,
                    (max(xs) + 1) * 16 / scale, (max(ys) + 1) * 16 / scale))
    out.sort(reverse=True)
    return [("INKOVER", "-",
             "stroke sitting on glyphs at x %.0f..%.0f y %.0f..%.0f "
             "(%d px)" % (x0, x1, y0, y1, w))
            for w, x0, y0, x1, y1 in out]
