#!/usr/bin/env python3
"""svgkit — SVG emission primitives for the generated diagrams.

Determinism is a contract here, not a nicety. `check-diagram` decides
whether a committed asset is stale by regenerating it and comparing
bytes, so anything that varies between runs on identical input would
make the suite fail at random and be switched off within a week. That
means: no timestamps, no generated ids, no float repr, and no iteration
over an unsorted collection.

Text wrapping is by character count rather than measured width. Without
a font engine there is no way to measure a string, and shelling out to
one would make the build depend on which fonts a machine has installed
— which is the same non-determinism wearing a different hat.
"""
import html

MONO = ("ui-monospace,SFMono-Regular,Menlo,Consolas,"
        "'DejaVu Sans Mono',monospace")

# Palette: instrument panel. Graphite ground so the plate reads the same
# under either GitHub theme, signal colours borrowed from safety
# signage rather than from a product palette.
GROUND = "#15181B"
PLATE = "#1D2226"
PLATE2 = "#232A2F"
EDGE = "#2F373E"
EDGE_HI = "#3D4750"
TXT = "#E6EBEF"
MUTED = "#8C99A2"
DIM = "#66727A"
AMBER = "#E0A32E"
RED = "#D8412F"
GREEN = "#4E9E6A"
STEEL = "#6B93B5"


def num(v):
    """Fixed formatting. `str(float)` differs across platforms at the
    last digit, which is enough to make a byte comparison flap."""
    return f"{v:.2f}".rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


def esc(s):
    return html.escape(str(s), quote=False)


def text(x, y, s, size=11, fill=TXT, weight="400", ls=0, anchor="start"):
    return (f'<text x="{num(x)}" y="{num(y)}" font-family="{MONO}" '
            f'font-size="{num(size)}" fill="{fill}" font-weight="{weight}" '
            f'letter-spacing="{num(ls)}" text-anchor="{anchor}">'
            f'{esc(s)}</text>')


def rect(x, y, w, h, fill=PLATE, stroke=EDGE, sw=1, rx=3, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<rect x="{num(x)}" y="{num(y)}" width="{num(w)}" '
            f'height="{num(h)}" rx="{num(rx)}" fill="{fill}" '
            f'stroke="{stroke}" stroke-width="{num(sw)}"{d}/>')


def line(x1, y1, x2, y2, stroke=EDGE, sw=1, dash=None, marker=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    m = f' marker-end="url(#{marker})"' if marker else ""
    return (f'<line x1="{num(x1)}" y1="{num(y1)}" x2="{num(x2)}" '
            f'y2="{num(y2)}" stroke="{stroke}" stroke-width="{num(sw)}"{d}{m}/>')


def group(gid, elements, tx=0, ty=0):
    """A named group. `gid` is what makes structure readable back out of
    the file: the checker recovers which event a hook is filed under by
    reading the group it sits in, rather than inferring it from where the
    label happens to land. Layout accidents stop being load-bearing."""
    t = f' transform="translate({num(tx)},{num(ty)})"' if (tx or ty) else ""
    inner = "\n".join("  " + e for e in elements)
    return f'<g id="{esc(gid)}"{t}>\n{inner}\n</g>'


def wrap(s, width):
    out, cur = [], ""
    for word in s.split():
        if len(cur) + len(word) + 1 > width:
            out.append(cur)
            cur = word
        else:
            cur = (cur + " " + word).strip()
    if cur:
        out.append(cur)
    return out


def para(x, y, s, width, size=9.5, fill=MUTED, lh=12):
    els, yy = [], y
    for ln in wrap(s, width):
        els.append(text(x, yy, ln, size, fill))
        yy += lh
    return els, yy


def document(width, height, body, title, defs=""):
    """A standalone asset. `title` is not decoration: opened directly the
    file has no alt text to fall back on, so the accessible name has to
    live inside it."""
    d = f"<defs>\n{defs}\n</defs>\n" if defs else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{num(width)}" '
            f'height="{num(height)}" viewBox="0 0 {num(width)} {num(height)}" '
            f'role="img" aria-label="{esc(title)}">\n'
            f'<title>{esc(title)}</title>\n'
            f'{d}<rect width="{num(width)}" height="{num(height)}" '
            f'fill="{GROUND}"/>\n' + "\n".join(body) + "\n</svg>\n")
