"""TrueType advance widths, read straight from the font file.
No fontTools here, so head/hhea/hmtx/cmap are parsed by hand.
"""
import struct


class Font:
    def __init__(self, path):
        with open(path, "rb") as fh:
            self.data = fh.read()
        self.tables = {}
        _, num_tables = struct.unpack(">IH", self.data[:6])
        off = 12
        for _ in range(num_tables):
            tag, _cs, toff, tlen = struct.unpack(">4sIII", self.data[off:off + 16])
            self.tables[tag.decode("latin-1")] = (toff, tlen)
            off += 16

        head, _ = self.tables["head"]
        self.units_per_em = struct.unpack(">H", self.data[head + 18:head + 20])[0]

        hhea, _ = self.tables["hhea"]
        num_h = struct.unpack(">H", self.data[hhea + 34:hhea + 36])[0]

        hmtx, _ = self.tables["hmtx"]
        self.advances = []
        for i in range(num_h):
            adv = struct.unpack(">H", self.data[hmtx + i * 4:hmtx + i * 4 + 2])[0]
            self.advances.append(adv)

        self.cmap = self._read_cmap()

    def _read_cmap(self):
        base, _ = self.tables["cmap"]
        n = struct.unpack(">H", self.data[base + 2:base + 4])[0]
        best = None
        for i in range(n):
            pid, eid, off = struct.unpack(
                ">HHI", self.data[base + 4 + i * 8:base + 4 + i * 8 + 8])
            if (pid, eid) in ((3, 10), (3, 1), (0, 3), (0, 4), (0, 6)):
                fmt = struct.unpack(">H", self.data[base + off:base + off + 2])[0]
                if fmt in (4, 12):
                    best = (fmt, base + off)
                    if fmt == 12:
                        break
        if not best:
            return {}
        fmt, off = best
        return self._cmap4(off) if fmt == 4 else self._cmap12(off)

    def _cmap4(self, off):
        seg_x2 = struct.unpack(">H", self.data[off + 6:off + 8])[0]
        seg = seg_x2 // 2
        ends = struct.unpack(">%dH" % seg, self.data[off + 14:off + 14 + seg_x2])
        sp = off + 16 + seg_x2
        starts = struct.unpack(">%dH" % seg, self.data[sp:sp + seg_x2])
        dp = sp + seg_x2
        deltas = struct.unpack(">%dh" % seg, self.data[dp:dp + seg_x2])
        rp = dp + seg_x2
        ranges = struct.unpack(">%dH" % seg, self.data[rp:rp + seg_x2])
        out = {}
        for i in range(seg):
            for c in range(starts[i], min(ends[i], 0xFFFF) + 1):
                if ranges[i] == 0:
                    g = (c + deltas[i]) & 0xFFFF
                else:
                    gi = rp + i * 2 + ranges[i] + (c - starts[i]) * 2
                    if gi + 2 > len(self.data):
                        continue
                    g = struct.unpack(">H", self.data[gi:gi + 2])[0]
                    if g:
                        g = (g + deltas[i]) & 0xFFFF
                if g:
                    out[c] = g
        return out

    def _cmap12(self, off):
        n = struct.unpack(">I", self.data[off + 12:off + 16])[0]
        out = {}
        p = off + 16
        for _ in range(n):
            s, e, g = struct.unpack(">III", self.data[p:p + 12])
            for c in range(s, min(e, s + 0x2000) + 1):
                out[c] = g + (c - s)
            p += 12
        return out

    def advance(self, ch):
        g = self.cmap.get(ord(ch))
        if g is None:
            g = self.cmap.get(ord("?"), 0)
        if g < len(self.advances):
            return self.advances[g]
        return self.advances[-1] if self.advances else 0

    def width(self, text, font_size, letter_spacing=0.0):
        """Advance width of `text` in user units at `font_size`."""
        if not text:
            return 0.0
        total = sum(self.advance(c) for c in text)
        w = total * font_size / self.units_per_em
        # SVG letter-spacing adds after every glyph including the last
        return w + letter_spacing * len(text)
