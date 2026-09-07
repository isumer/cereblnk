"""Layout rules for the systems-note sheet: geometry, spacing consistency,
and ink. Widths come from the real DejaVu metrics, not an estimate.
"""
import re
import xml.etree.ElementTree as ET
from collections import defaultdict, Counter

from sheetfont import Font

FONT_DIR = "/usr/share/fonts/truetype/dejavu/"
FONT_FILES = {
    ("mono", False): "DejaVuSansMono.ttf",
    ("mono", True): "DejaVuSansMono-Bold.ttf",
    ("sans", False): "DejaVuSans.ttf",
    ("sans", True): "DejaVuSans-Bold.ttf",
}

# --- geometry thresholds
TIGHT_PAD = 5.0      # horizontal air a text owes its box edge
MIN_GAP = 10.0       # air between two runs sharing a baseline
VPAD = 4.0           # air above the cap line and below the descender
ASCENT = 0.76        # DejaVu ascender share of the em
DESCENT = 0.24       # DejaVu descender share of the em

# --- consistency thresholds
ALIGN_TOL = 0.75     # x values this close are the same column
ALIGN_WINDOW = 6.0   # a miss wider than this is a deliberate indent
LEAD_WINDOW = 3.0    # leading this close to an intended value is drift
SECTION_MIN = 60.0   # a gap at least this large separates sections
SECTION_MAX = 140.0  # ...and beyond this it is panel structure, not a list
VOID_MIN = 45        # empty band inside a panel that reads as a hole
FILL_MIN = 0.6       # least of a wide panel's width a block should occupy

SVG_NS = "{http://www.w3.org/2000/svg}"


class FontUnavailable(Exception):
    """The DejaVu faces are not installed, so nothing can be measured."""


def load_fonts(font_dir=FONT_DIR):
    import os
    fonts = {}
    for key, name in FONT_FILES.items():
        path = os.path.join(font_dir, name)
        if not os.path.exists(path):
            raise FontUnavailable(path)
        fonts[key] = Font(path)
    return fonts


# ---------------------------------------------------------------- CSS

def parse_css(text):
    styles = defaultdict(dict)
    body = "\n".join(re.findall(r"<style[^>]*>(.*?)</style>", text, re.S))
    body = re.sub(r"/\*.*?\*/", "", body, flags=re.S)
    body = body.replace("<![CDATA[", "").replace("]]>", "")
    for rule in re.finditer(r"([^{}]+)\{([^{}]*)\}", body):
        props = {}
        for d in rule.group(2).split(";"):
            if ":" in d:
                k, v = d.split(":", 1)
                props[k.strip()] = v.strip()
        for sel in rule.group(1).split(","):
            sel = sel.strip()
            if sel.startswith("."):
                styles[sel[1:]].update(props)
            elif sel == "text":
                styles["__text__"].update(props)
    return styles


def num(v, default=0.0):
    if v is None:
        return default
    m = re.match(r"^\s*(-?[\d.]+)", str(v))
    return float(m.group(1)) if m else default


class StyleState:
    __slots__ = ("size", "weight", "family", "spacing", "anchor")

    def __init__(self, size=10.0, weight=400, family="mono", spacing=0.0,
                 anchor="start"):
        self.size, self.weight, self.family = size, weight, family
        self.spacing, self.anchor = spacing, anchor

    def copy(self):
        return StyleState(self.size, self.weight, self.family, self.spacing,
                          self.anchor)


def _family_of(decl):
    return "mono" if "Mono" in decl else "sans"


def apply_classes(st, classes, styles):
    for cls in classes:
        p = styles.get(cls)
        if not p:
            continue
        if "font-size" in p:
            st.size = num(p["font-size"], st.size)
        if "font-weight" in p:
            st.weight = int(num(p["font-weight"], st.weight))
        if "letter-spacing" in p:
            st.spacing = num(p["letter-spacing"], st.spacing)
        if "font-family" in p:
            st.family = _family_of(p["font-family"])
    return st


def apply_attrs(st, el):
    if el.get("font-size"):
        st.size = num(el.get("font-size"), st.size)
    if el.get("font-weight"):
        st.weight = int(num(el.get("font-weight"), st.weight))
    if el.get("letter-spacing"):
        st.spacing = num(el.get("letter-spacing"), st.spacing)
    if el.get("text-anchor"):
        st.anchor = el.get("text-anchor")
    return st


# ---------------------------------------------------------------- model

class Text:
    def __init__(self, s, x0, x1, y, size, line, anchor_x, anchor):
        self.s, self.x0, self.x1, self.y = s, x0, x1, y
        self.size, self.line = size, line
        self.anchor_x, self.anchor = anchor_x, anchor


class Rect:
    def __init__(self, x, y, w, h, line):
        self.x0, self.y0, self.x1, self.y1 = x, y, x + w, y + h
        self.line = line
        self.area = w * h

    def __repr__(self):
        return "rect@%s [%.0f,%.0f %.0fx%.0f]" % (
            self.line, self.x0, self.y0, self.x1 - self.x0, self.y1 - self.y0)


class Sheet:
    def __init__(self, texts, rects, width, height, source):
        self.texts, self.rects = texts, rects
        self.width, self.height, self.source = width, height, source
        self.frame = max(rects, key=lambda r: r.area) if rects else None
        self.panels = self._panels()

    def _panels(self):
        cand = [r for r in self.rects if r is not self.frame and r.area > 18000]
        out = []
        for r in cand:
            nested = any(
                o is not r and o.area > r.area
                and r.x0 >= o.x0 - 1 and r.x1 <= o.x1 + 1
                and r.y0 >= o.y0 - 1 and r.y1 <= o.y1 + 1
                for o in cand)
            if not nested:
                out.append(r)
        out.sort(key=lambda r: (r.y0, r.x0))
        return out

    def subboxes(self, panel):
        return [r for r in self.rects
                if r is not panel and r is not self.frame
                and r.x0 >= panel.x0 - 1 and r.x1 <= panel.x1 + 1
                and r.y0 >= panel.y0 - 1 and r.y1 <= panel.y1 + 1]

    def texts_in(self, box):
        return [t for t in self.texts
                if box.x0 - 2 <= t.anchor_x <= box.x1 + 2
                and box.y0 - 2 <= t.y <= box.y1 + 2]

    def container_for(self, t):
        best = None
        for r in self.rects:
            if r is self.frame:
                continue
            if not (r.y0 - 1 <= t.y - t.size * 0.32 <= r.y1 + 1):
                continue
            if not (r.x0 - 2 <= t.x0 <= r.x1 + 2):
                continue
            if best is None or r.area < best.area:
                best = r
        return best or self.frame


def parse(path, fonts=None):
    """Read a page and return its measured Sheet."""
    fonts = fonts or load_fonts()
    src = open(path, encoding="utf-8").read()
    styles = parse_css(src)
    svg_txt = src[src.index("<svg"):src.index("</svg>") + 6]
    offset = src[:src.index("<svg")].count("\n")

    tree = ET.fromstring(svg_txt)
    line_index = {}
    positions = [svg_txt[:m.start()].count("\n") + offset + 1
                 for m in re.finditer(r"<([a-zA-Z]+)[\s/>]", svg_txt)]
    for el, ln in zip(list(tree.iter())[1:], positions[1:]):
        line_index[id(el)] = ln

    texts, rects = [], []
    base = StyleState()
    apply_classes(base, ["__text__"], styles)
    base.family = _family_of(styles.get("__text__", {}).get("font-family", "Mono"))

    def measure(s, st):
        return fonts[(st.family, st.weight >= 600)].width(s, st.size, st.spacing)

    def collect_text(el, tx, ty, st):
        y = num(el.get("y")) + ty
        segments, cur = [], []
        cur_x, cur_y = num(el.get("x")) + tx, y

        def push():
            if cur:
                segments.append((cur_x, list(cur), cur_y))

        if el.text and el.text.strip():
            cur.append((el.text, st))
        for child in el:
            cst = st.copy()
            apply_classes(cst, (child.get("class") or "").split(), styles)
            apply_attrs(cst, child)
            if child.tag.replace(SVG_NS, "") == "tspan":
                if child.get("x") is not None or child.get("y") is not None:
                    push()
                    cur = []
                    if child.get("x") is not None:
                        cur_x = num(child.get("x")) + tx
                    if child.get("y") is not None:
                        cur_y = num(child.get("y")) + ty
                if child.text:
                    cur.append((child.text, cst))
            if child.tail and child.tail.strip():
                cur.append((child.tail, st))
        push()

        for sx, run, sy in segments:
            disp = re.sub(r"\s+", " ", "".join(r[0] for r in run)).strip()
            if not disp:
                continue
            width = sum(measure(r[0], r[1]) for r in run)
            size = max(r[1].size for r in run)
            if st.anchor == "middle":
                x0 = sx - width / 2.0
            elif st.anchor == "end":
                x0 = sx - width
            else:
                x0 = sx
            texts.append(Text(disp, x0, x0 + width, sy, size,
                              line_index.get(id(el), "?"), sx, st.anchor))

    def recurse(el, tx, ty, st):
        tag = el.tag.replace(SVG_NS, "")
        m = re.search(r"translate\(\s*(-?[\d.]+)[ ,]+(-?[\d.]+)?",
                      el.get("transform") or "")
        if m:
            tx += float(m.group(1))
            ty += float(m.group(2) or 0)
        st = st.copy()
        apply_classes(st, (el.get("class") or "").split(), styles)
        apply_attrs(st, el)

        if tag == "rect":
            rects.append(Rect(num(el.get("x")) + tx, num(el.get("y")) + ty,
                              num(el.get("width")), num(el.get("height")),
                              line_index.get(id(el), "?")))
        elif tag == "text":
            collect_text(el, tx, ty, st)
            return
        for child in el:
            recurse(child, tx, ty, st)

    recurse(tree, 0.0, 0.0, base)
    vb = (tree.get("viewBox") or "0 0 0 0").split()
    return Sheet(texts, rects, float(vb[2]), float(vb[3]), src)


# ---------------------------------------------------------------- rules

def geometry_findings(sheet):
    """Every glyph inside its box, with air, and nothing colliding."""
    out = []
    for t in sheet.texts:
        c = sheet.container_for(t)
        right = c.x1 - t.x1
        if right < 0:
            out.append(("OVERFLOW", t.line,
                        "text runs %.0fpx past its box right edge "
                        "(ends x=%.0f, box ends x=%.0f): %r"
                        % (-right, t.x1, c.x1, t.s)))
        elif right < TIGHT_PAD:
            out.append(("TIGHT", t.line,
                        "only %.1fpx to the box right edge: %r" % (right, t.s)))
        if t.x0 - c.x0 < -1:
            out.append(("OVERFLOW", t.line,
                        "text starts %.0fpx left of its box: %r"
                        % (c.x0 - t.x0, t.s)))
        if t.x1 > sheet.width - 4:
            out.append(("OVERFLOW", t.line,
                        "text runs past the canvas (x=%.0f > %.0f): %r"
                        % (t.x1, sheet.width, t.s)))
        if c is not sheet.frame:
            below = c.y1 - (t.y + t.size * DESCENT)
            above = (t.y - t.size * ASCENT) - c.y0
            if below < 0:
                out.append(("OVERFLOW", t.line,
                            "descenders fall %.0fpx below the box bottom: %r"
                            % (-below, t.s)))
            elif below < VPAD:
                out.append(("TIGHT", t.line,
                            "only %.1fpx under the text to the box bottom: %r"
                            % (below, t.s)))
            if above < 0:
                out.append(("OVERFLOW", t.line,
                            "text rises %.0fpx above the box top: %r"
                            % (-above, t.s)))
            elif above < VPAD:
                out.append(("TIGHT", t.line,
                            "only %.1fpx over the text to the box top: %r"
                            % (above, t.s)))

    by_y = defaultdict(list)
    for t in sheet.texts:
        by_y[round(t.y / 2.0)].append(t)
    seen = set()
    for group in by_y.values():
        for i, a in enumerate(group):
            for b in group[i + 1:]:
                if abs(a.y - b.y) > max(a.size, b.size) * 0.6:
                    continue
                key = tuple(sorted([(str(a.line), a.s), (str(b.line), b.s)]))
                if key in seen:
                    continue
                if a.x0 < b.x1 and b.x0 < a.x1:
                    seen.add(key)
                    out.append(("COLLIDE", "%s/%s" % (a.line, b.line),
                                "%.0fpx overlap on y=%.0f: %r vs %r"
                                % (min(a.x1, b.x1) - max(a.x0, b.x0),
                                   a.y, a.s, b.s)))
                    continue
                # Not overlapping is not the same as reading as two things.
                gap = max(a.x0, b.x0) - min(a.x1, b.x1)
                if 0 <= gap < MIN_GAP:
                    seen.add(key)
                    out.append(("SEPARATE", "%s/%s" % (a.line, b.line),
                                "only %.0fpx between two runs on y=%.0f, so "
                                "they read as one: %r | %r"
                                % (gap, a.y, a.s, b.s)))

    for i, r in enumerate(sheet.rects):
        for s in sheet.rects[i + 1:]:
            if r is sheet.frame or s is sheet.frame:
                continue
            ox = min(r.x1, s.x1) - max(r.x0, s.x0)
            oy = min(r.y1, s.y1) - max(r.y0, s.y0)
            if ox > 1 and oy > 1:
                nested = ((r.x0 >= s.x0 - 1 and r.x1 <= s.x1 + 1
                           and r.y0 >= s.y0 - 1 and r.y1 <= s.y1 + 1)
                          or (s.x0 >= r.x0 - 1 and s.x1 <= r.x1 + 1
                              and s.y0 >= r.y0 - 1 and s.y1 <= r.y1 + 1))
                if not nested:
                    out.append(("BOXOVER", "%s/%s" % (r.line, s.line),
                                "boxes overlap %.0fx%.0fpx: %r %r"
                                % (ox, oy, r, s)))
    return out


def _cluster(values, tol=ALIGN_TOL):
    out = []
    for v in sorted(values):
        for c in out:
            if abs(v - c[0]) <= tol:
                c[1].append(v)
                c[0] = sum(c[1]) / len(c[1])
                break
        else:
            out.append([v, [v]])
    out.sort(key=lambda c: -len(c[1]))
    return [(c[0], c[1]) for c in out]


def consistency_findings(sheet):
    """One spacing vocabulary, one set of columns, no holes."""
    out = []

    for p in sheet.panels:
        starts = [t for t in sheet.texts_in(p) if t.anchor == "start"]
        if len(starts) < 4:
            continue
        major = [c for c in _cluster([t.anchor_x for t in starts])
                 if len(c[1]) >= 3]
        for t in starts:
            for centre, members in major:
                if abs(t.anchor_x - centre) <= ALIGN_TOL:
                    break
                if abs(t.anchor_x - centre) <= ALIGN_WINDOW:
                    out.append(("ALIGN", t.line,
                                "x=%.0f is %.0fpx off the x=%.0f column used "
                                "by %d other lines here: %r"
                                % (t.anchor_x, t.anchor_x - centre, centre,
                                   len(members), t.s)))
                    break

    # Near-miss only. Measuring every gap against a declared scale also
    # flagged box-to-box and heading gaps, because the sheet uses more
    # vertical rhythms than a list has.
    deltas = []
    for p in sheet.panels:
        cols = defaultdict(list)
        for t in sheet.texts_in(p):
            if t.anchor == "start":
                cols[round(t.anchor_x)].append(t)
        for group in cols.values():
            group.sort(key=lambda t: t.y)
            for a, b in zip(group, group[1:]):
                d = round(b.y - a.y, 1)
                if 0 < d < 46:
                    deltas.append((d, b))
    counts = Counter(d for d, _ in deltas)
    intended = {d for d, n in counts.items() if n >= 6}
    for d, t in deltas:
        if d in intended:
            continue
        near = [i for i in intended if abs(d - i) <= LEAD_WINDOW]
        if near:
            i = min(near, key=lambda v: abs(d - v))
            out.append(("RHYTHM", t.line,
                        "leading %.0fpx before %r; the sheet uses %.0fpx here "
                        "(%d times) — %.0fpx drift"
                        % (d, t.s[:34], i, counts[i], d - i)))

    # One list's section breaks are one gesture, so one value. Scoped to
    # real lists so box grids and panel headings stay out.
    for p in sheet.panels:
        cols = defaultdict(list)
        for t in sheet.texts_in(p):
            if t.anchor == "start":
                cols[round(t.anchor_x)].append(t)
        for group in cols.values():
            if len(group) < 5:
                continue
            group.sort(key=lambda t: t.y)
            breaks = [(round(b.y - a.y, 1), b)
                      for a, b in zip(group, group[1:])
                      if SECTION_MIN <= b.y - a.y <= SECTION_MAX]
            if len(breaks) < 2:
                continue
            base = Counter(g for g, _ in breaks).most_common(1)[0][0]
            for g, t in breaks:
                if abs(g - base) > 1.0:
                    out.append((
                        "RHYTHM", t.line,
                        "the section break above %r is %.0fpx; the other "
                        "breaks in this list are %.0fpx"
                        % (t.s[:30], g, base)))

    pads = []
    for p in sheet.panels:
        inner = [t for t in sheet.texts_in(p) if t.anchor == "start"]
        if inner:
            pads.append((round(min(t.anchor_x for t in inner) - p.x0, 1), p))
    if pads:
        base = Counter(v for v, _ in pads).most_common(1)[0][0]
        for v, p in pads:
            if abs(v - base) > 1.0:
                out.append(("PAD", p.line,
                            "panel left padding %.0fpx; most panels use %.0fpx"
                            % (v, base)))

    for axis, key, label in (("h", lambda r: round(r.y0 / 6), "horizontal"),
                             ("v", lambda r: round(r.x0 / 6), "vertical")):
        groups = defaultdict(list)
        for p in sheet.panels:
            groups[key(p)].append(p)
        gaps = []
        for _, grp in sorted(groups.items()):
            grp.sort(key=lambda r: r.x0 if axis == "h" else r.y0)
            for a, b in zip(grp, grp[1:]):
                gaps.append((round((b.x0 - a.x1) if axis == "h"
                                   else (b.y0 - a.y1), 1), a, b))
        if gaps:
            base = Counter(g for g, _, _ in gaps).most_common(1)[0][0]
            for g, a, b in gaps:
                if abs(g - base) > 1.0:
                    out.append(("GAP", "%s/%s" % (a.line, b.line),
                                "%s gap between panels is %.0fpx; the sheet "
                                "uses %.0fpx" % (label, g, base)))

    insets = []
    for p in sheet.panels:
        for b in sheet.subboxes(p):
            inner = [t for t in sheet.texts_in(b) if t.anchor == "start"]
            if inner:
                insets.append(
                    (round(min(t.anchor_x for t in inner) - b.x0, 1), b))
    if insets:
        base = Counter(v for v, _ in insets).most_common(1)[0][0]
        for v, b in insets:
            if abs(v - base) > 1.0:
                out.append(("BOXPAD", b.line,
                            "text inset %.0fpx from its box; most boxes use "
                            "%.0fpx" % (v, base)))

    # Unless a box is stacked under one: that is a column, not ragged.
    for p in sheet.panels:
        subs = sheet.subboxes(p)
        rows = defaultdict(list)
        for b in subs:
            rows[round(b.y0 / 1.5)].append(b)
        for _, row in sorted(rows.items()):
            if len(row) < 2:
                continue
            floor = max(b.y1 for b in row)
            for b in row:
                short = floor - b.y1
                if short <= 0:
                    continue
                stacked = any(o is not b and o.y0 >= b.y1 - 1
                              and o.x0 < b.x1 - 1 and o.x1 > b.x0 + 1
                              for o in subs)
                if short > 6 and not stacked:
                    out.append(("BOXFIT", b.line,
                                "box ends %.0fpx above its row-mates (y=%.0f "
                                "vs %.0f) with nothing stacked under it — "
                                "ragged bottom" % (short, b.y1, floor)))
                elif short <= 6:
                    out.append(("BOXFIT", b.line,
                                "box bottom y=%.0f is %.1fpx off its row-mates "
                                "at y=%.0f — drift, not intent"
                                % (b.y1, short, floor)))

    # Local correctness is not composition: a hole reads as broken.
    for p in sheet.panels:
        rows = [False] * int(p.y1 - p.y0 + 2)

        def mark(y0, y1):
            a = max(0, int(y0 - p.y0))
            b = min(len(rows) - 1, int(y1 - p.y0))
            for i in range(a, b + 1):
                rows[i] = True

        for t in sheet.texts_in(p):
            mark(t.y - t.size * 0.8, t.y + t.size * 0.3)
        for b in sheet.subboxes(p):
            mark(b.y0, b.y1)

        if p.x1 - p.x0 >= 400:
            bands, start = [], None
            for i, filled in enumerate(rows):
                if filled and start is None:
                    start = i
                elif not filled and start is not None:
                    bands.append((start, i))
                    start = None
            if start is not None:
                bands.append((start, len(rows)))
            for b0, b1 in bands:
                if b1 - b0 < 40:
                    continue
                y0, y1 = p.y0 + b0, p.y0 + b1
                items = [t for t in sheet.texts_in(p) if y0 <= t.y <= y1]
                items += [r for r in sheet.subboxes(p)
                          if r.y1 > y0 and r.y0 < y1]
                if not items:
                    continue
                used = (max(i.x1 for i in items) - p.x0) / (p.x1 - p.x0)
                if used < FILL_MIN:
                    out.append(("VOID", p.line,
                                "the block at y=%.0f..%.0f fills only %d%% of "
                                "the panel width — the right side is empty"
                                % (y0, y1, round(used * 100))))

        run = 0
        for i, filled in enumerate(rows):
            if not filled:
                run += 1
                continue
            if run >= VOID_MIN:
                top = p.y0 + i - run
                out.append(("VOID", p.line,
                            "%dpx of empty panel between y=%.0f and y=%.0f — "
                            "a hole in the middle of the panel"
                            % (run, top, top + run)))
            run = 0
        if run >= VOID_MIN:
            out.append(("VOID", p.line,
                        "%dpx of empty panel below the last item — the panel "
                        "ends in dead space" % run))
    return out


SEVERITY = {
    "OVERFLOW": 0, "COLLIDE": 1, "SEPARATE": 2, "BOXOVER": 3,
    "ALIGN": 4, "RHYTHM": 5, "VOID": 6, "BOXFIT": 7,
    "PAD": 8, "GAP": 9, "BOXPAD": 10, "INKOVER": 11, "TIGHT": 12,
}

# TIGHT is a warning: it fits, but only just.
HARD = set(SEVERITY) - {"TIGHT"}


def sort_findings(findings):
    return sorted(findings, key=lambda f: (SEVERITY.get(f[0], 99), str(f[1])))
